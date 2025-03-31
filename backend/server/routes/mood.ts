import { Hono } from "hono";
import { ChatGroq } from "@langchain/groq";
import { ChatPromptTemplate } from "@langchain/core/prompts";
import { BufferMemory } from "langchain/memory";
import { ConversationChain } from "langchain/chains";
import { UpstashRedisChatMessageHistory } from "@langchain/community/stores/message/upstash_redis";
import { v4 as uuidv4 } from "uuid";
import { z } from "zod";
import { zValidator } from "@hono/zod-validator";
import { Redis } from "@upstash/redis";
import { eq } from "drizzle-orm";
import { db } from "@/adapter";
import { moodAssessmentsTable } from "@/db/schemas/mood";
import { userTable } from "@/db/schemas/auth";
import { HTTPException } from "hono/http-exception";
import { sessionTable } from "@/db/schemas/sessions";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { flaggedUsersTable } from "@/db/schemas/flagged";

// Initialize the language model
const llm = new ChatGroq({
  // model: "mixtral-8x7b-32768",
  model: "deepseek-r1-distill-qwen-32b",
  
  temperature: 0,
  apiKey:  process.env["GROQ_API_KEY"],
});

// Initialize Redis client
const redis = new Redis({
  url: process.env["UPSTASH_REDIS_URL"],
  token: process.env["UPSTASH_REDIS_TOKEN"],
});

// Define the mood assessment prompt
const moodPrompt = ChatPromptTemplate.fromTemplate(`
You are an AI assistant called Hear-U, engaging in a real-time conversation with a user to determine their mood based on five multiple-choice questions. You will ask one question at a time and wait for the user's answer before proceeding to the next question. After the user has answered five questions, you will analyze their responses and provide a mood assessment. Do not include any reasoning, internal thoughts, or tags like <think> in your response.

**Instructions:**
- Review the chat history to determine how many questions have been asked and answered.
- If no questions have been asked yet (e.g., the user says "Hi" or starts the conversation), greet the user and ask the first multiple-choice question with four options.
- If the user has just answered a question, acknowledge their answer and:
  - If fewer than five questions have been answered, ask the next question with four options.
  - If five questions have been answered, analyze the responses, provide a brief explanation, and classify the mood as very bad, bad, neutral, good, or very good.
- Do not simulate the user's answers; provide only Hear-U's next response based on the current input and history.

**Example Interaction:**
User: Hi
Hear-U: Hello! I'm Hearu, here to help you understand your mood. First question: How do you feel right now? a) Energetic b) Tired c) Neutral d) Stressed

User: a) Energetic
Hear-U: Nice to hear that! Question 2: How was your day so far? a) Great b) Okay c) Challenging d) Terrible

[After four questions]
User: [Answer to question 4]
Hear-U: Thanks for sharing! Question 5: How do you feel about the rest of your day? a) Optimistic b) Neutral c) Worried d) Overwhelmed

[After five questions]
User: [Answer to question 5]
Hear-U: Thank you for answering all five questions. Based on your responses, your mood is good. You seem to be feeling energetic and positive overall.

**Chat History:** {history}
**User Input:** {input}

Provide only the next response from Hear-U.
`);

// Define the therapist prompt
const therapistPrompt = ChatPromptTemplate.fromTemplate(`
You are an AI assistant called Hear-U, a compassionate and supportive virtual therapist.  

Your goal is to help users talk about their feelings, offer comfort, and provide guidance to help them feel better.  
If the user is experiencing a severe emotional crisis, gently encourage them to seek support from a professional therapist or a trusted person. Do not include any reasoning, internal thoughts, or tags like <think> in your response.  

**Chat History:** {history}  
**User Input:** {input}  
`);


const genAI = new GoogleGenerativeAI(process.env["GEMINI_API_KEY"]!);
export const geminiModel = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });


const criticalityPrompt = `
You are an AI safety assistant tasked with analyzing a user's message in a mental health chat context. Your goal is to determine if the message indicates potential drastic steps (e.g., self-harm, suicide), harmful behavior, or critical emotional distress. Follow these steps:

1. **Analyze the Message**: Examine the user's input for explicit or implicit signs of danger, such as mentions of self-harm, hopelessness, or intent to act destructively.
2. **Assign a Criticality Percentage**: Based on the severity and likelihood of drastic action or critical behavior, assign a percentage (0-100%):
   - 0-20%: No significant concern (e.g., casual conversation).
   - 21-40%: Mild concern (e.g., general sadness or frustration).
   - 41-60%: Moderate concern (e.g., hints of despair or risky thoughts).
   - 61-80%: High concern (e.g., strong emotional distress or vague threats).
   - 81-100%: Severe concern (e.g., explicit intent to harm self or others).
3. **Provide Reasoning**: Briefly explain why you assigned this percentage.

**Input**: A single user message from a chat session.
**Output**: Return a JSON object with:
- 
- "percentage": number (0-100)
- "reason": string (explanation of the assessment)

**Example Inputs and Outputs**:
- Input: "I'm just tired today."
  Output: { "percentage": 20, "reason": "Mild expression of fatigue, no immediate danger." }
- Input: "I can't go on like this anymore."
  Output: { "percentage": 60, "reason": "Moderate concern due to hopelessness, requires context." }
- Input: "I'm going to end it all tonight."
  Output: { "percentage": 90, "reason": "Severe concern due to explicit intent to self-harm." }

**User Message**: {message}
`;


// Helper function to initialize conversation chain
const initializeChain = async (
  sessionId: string,
  prompt: ChatPromptTemplate,
) => {

  const upstashMessageHistory = new UpstashRedisChatMessageHistory({
    sessionId,
    config: {
      url: process.env["UPSTASH_REDIS_URL"],
      token: process.env["UPSTASH_REDIS_TOKEN"],
    },
  });

  const memory = new BufferMemory({
    memoryKey: "history",
    chatHistory: upstashMessageHistory,
  });

  return new ConversationChain({
    prompt,
    llm,
    memory,
  });
};

// Define valid mood values as a const array for TypeScript and Zod
const moodValues = ["very bad", "bad", "neutral", "good", "very good"] as const;
type MoodValue = (typeof moodValues)[number];

// Mapping for extractMood (string to string, no TS enum needed)
const moodMap: Record<string, MoodValue | undefined> = {
  "very bad": "very bad",
  bad: "bad",
  neutral: "neutral",
  good: "good",
  "very good": "very good",
};

// Helper function to extract mood from the LLM response
const extractMood = (response: string): MoodValue | null => {
  const moodMatch = response.match(/your mood is (\w+\s*\w*)/i);
  if (moodMatch && moodMatch[1]) {
    const moodText = moodMatch[1].toLowerCase();
    return moodMap[moodText] || null;
  }
  return null;
};

// Define the mood router
export const moodRouter = new Hono()
  // quiz chat
  .post(
    "/start",
    zValidator("form", z.object({ userId: z.string().min(1) })),
    async (c) => {
      try {
        const { userId } = c.req.valid("form");
        const sessionId = uuidv4();
        await redis.set(`session:${sessionId}:userId`, userId);

        const sessionInsert = await db.insert(sessionTable).values({
          id: sessionId,
          userId,
          title: sessionId
        }).returning();

        console.log("sessionInsert>>>", sessionInsert)


        const chain = await initializeChain(sessionId, moodPrompt);
        const result = await chain.call({ input: "Hi" });


        console.log("result>>>>>>", result);

        // Post-process to remove <think> tags if they still appear
      let response = result["response"];
      response = response.replace(/<think>[\s\S]*?<\/think>/g, "").trim();


        return c.json({ success: true, message: response, sessionId });
      } catch (error) {
        console.error("Error in /start route:", error);
        return c.json(
          {
            success: false,
            error:
              process.env.NODE_ENV === "production"
                ? "Internal Server Error"
                : error instanceof Error
                ? error.message
                : "Unknown error",
          },
          500,
        );
      }
    },
  )
  //normal chat
  .post(
    "/start/chat",
    zValidator("form", z.object({ userId: z.string().min(1) })),
    async (c) => {
      try {
        const { userId } = c.req.valid("form");

        console.log("userId>>>>", userId);

        console.log("start chat");

        
        const sessionId = uuidv4();
        await redis.set(`session:${sessionId}:userId`, userId);

        const sessionInsert = await db.insert(sessionTable).values({
          id: sessionId,
          userId,
          title: sessionId
        }).returning();

        console.log("sessionInsert>>>", sessionInsert)

        const chain = await initializeChain(sessionId, therapistPrompt);
        const result = await chain.call({ input: "Hi" });
        console.log("result>>>>>>", result);


        // Post-process to remove <think> tags if they still appear
      let response = result["response"];
      response = response.replace(/<think>[\s\S]*?<\/think>/g, "").trim();

        return c.json({ success: true, response, sessionId });
      } catch (error) {
        console.error("Error in /start/chat route:", error);
        return c.json(
          {
            success: false,
            error:
              process.env.NODE_ENV === "production"
                ? "Internal Server Error"
                : error instanceof Error
                ? error.message
                : "Unknown error",
          },
          500,
        );
      }
    },
  )
  .post(
    "/answer/:sessionId",
    zValidator("param", z.object({ sessionId: z.string().min(1) })),
    zValidator(
      "query",
      z.object({ isQuiz: z.string().optional().transform((val) => val === "true")}),),
    zValidator("form", z.object({ answer: z.string().min(1) })),
    async (c) => {
      try {
        const { sessionId } = c.req.valid("param");
        const { isQuiz } = c.req.valid("query");
        console.log("isQuiz>>>", isQuiz);
        
        if (!sessionId) {
          return c.json({ success: false, error: "No sessionId found" }, 400);
        }
        
        const { answer } = c.req.valid("form");
        console.log("answer>>>", answer);
        if (!answer) {
          return c.json({ success: false, error: "No answer provided" }, 400);
        }

        //this is where we will use the LLM to check for flag
        const prompt = criticalityPrompt.replace("{message}", answer);

        const result_user = await geminiModel.generateContent(prompt);


            // const result = await model.generateContent(text);

      console.log("result_user>>>", result_user)


      if(!result_user.response.candidates){
        return c.json({ success: false, error: "Invalid response format from AI" }, 500);


      }
    
      const aiSummary = result_user.response.candidates[0].content.parts[0].text 
    
      console.log("aiSummary>>>>", aiSummary)
    
      if(!aiSummary){
        return c.json({ success: false, error: "Invalid response format from AI" }, 500);

      }
    
    
      // const summary = aiSummary.replace("\n", "")
    
      // console.log("summary>>>>", summary)

      // Clean up the response (remove markdown ```json ... ``` wrapper)
    const cleanedSummary = aiSummary
    .replace(/```json/g, "") // Remove opening ```json
    .replace(/```/g, "")     // Remove closing ```
    .replace(/\n/g, "")      // Remove newlines
    .trim();

  console.log("cleanedSummary>>>>", cleanedSummary);

  // Parse the cleaned JSON string
  let parsedResult;
  try {
    parsedResult = JSON.parse(cleanedSummary);
  } catch (parseError) {
    console.error("Failed to parse JSON:", parseError);
    return c.json({ success: false, error: "Invalid response format from AI" }, 500);

  }

  // Extract percentage and reason
  const { percentage, reason } = parsedResult;

  if (typeof percentage !== "number" || !reason) {
    return c.json({ success: false, error: "Invalid response format from AI" }, 500);

  }

  console.log("Parsed result>>>>", { percentage, reason });
    
  
        
      

   // If percentage > 50%, save to flaggedUsersTable
   const userId = await redis.get(`session:${sessionId}:userId`) as string;
   if (percentage > 50 && userId) {
     await db.insert(flaggedUsersTable).values({
       userId,
       reason,
       sessionId,
       percentage: percentage.toString(), // Convert number to string for schema
     }).onConflictDoNothing(); // Avoid duplicates
     console.log(`User ${userId} flagged with percentage ${percentage} for reason: ${reason}`);
   }

        let chain;
        if (isQuiz) {
          chain = await initializeChain(sessionId, moodPrompt);
        } else {
          chain = await initializeChain(sessionId, therapistPrompt);
        }

        const result = await chain.call({ input: answer });
        console.log("result>>>>>>", result);

                // Post-process to remove <think> tags if they still appear
      let response = result["response"];
      response = response.replace(/<think>[\s\S]*?<\/think>/g, "").trim();

      console.log("response>>>", response)


        const responseMessage = response;
        const mood = extractMood(responseMessage);

        let moodAssessment;

        if (isQuiz && mood) {
          const userId = await redis.get(`session:${sessionId}:userId`);
          if (userId) {
            moodAssessment = await db.insert(moodAssessmentsTable).values({
              userId: userId as string,
              mood,
            }).returning();
          }
        }

        if (mood) {
          return c.json({
            success: true,
            message: responseMessage,
            mood: mood,
            moodAssessment
          });
        }

        return c.json({
          success: true,
          message: responseMessage,
        });
      } catch (error) {
        console.error("Error in /answer route:", error);
        return c.json(
          {
            success: false,
            error:
              process.env.NODE_ENV === "production"
                ? "Internal Server Error"
                : error instanceof Error
                ? error.message
                : "Unknown error",
          },
          500,
        );
      }
    },
  )
  //graph details
  .get("/history/:userId",
    zValidator("param", z.object({ userId: z.string().min(1) })),
    async (c) => {
    try {
    //   const userId = c.get("userId"); // Assuming userId is set in context via authentication middleware
      const {userId} = c.req.valid("param")
    
      console.log("userId>>>", userId)
    if (!userId) {
        return c.json({ success: false, error: "User not authenticated" }, 401);
      }

      const assessments = await db
        .select()
        .from(moodAssessmentsTable)
        .where(eq(moodAssessmentsTable.userId, userId))
        .orderBy(moodAssessmentsTable.assessedAt);

      return c.json({ success: true, assessments });
    } catch (error) {
      console.error("Error in /mood/history route:", error);
      return c.json(
        {
          success: false,
          error:
            process.env.NODE_ENV === "production"
              ? "Internal Server Error"
              : error instanceof Error
              ? error.message
              : "Unknown error",
        },
        500,
      );
    }
  })
  //popup to determine mood
  .post(
    "/:userId",
    zValidator("param", z.object({ userId: z.string().min(1) })),
    zValidator("form", z.object({ 
      mood: z.enum(moodValues, { message: "Invalid mood value" }),// Use z.enum to restrict to valid values
    })),
    async (c) => {
      try {
        const { userId } = c.req.valid("param");
        const { mood } = c.req.valid("form");
  
        console.log("userId>>>", userId);
        console.log("mood>>>", mood);
  
        // Verify user exists in userTable (assuming you have this from your previous schemas)
        const [existingUser] = await db
          .select()
          .from(userTable)
          .where(eq(userTable.id, userId))
          .limit(1);
  
        if (!existingUser) {
          throw new HTTPException(404, {
            message: "User not found",
            cause: { form: true },
          });
        }
  
        // Insert the mood assessment
        const [moodAssessment] = await db
          .insert(moodAssessmentsTable)
          .values({
            userId: userId,
            mood: mood,
          })
          .returning();
  
        return c.json({
          success: true,
          message: "Mood recorded successfully",
          data: {
            moodAssessment
          }
        }, 201);
  
      } catch (error) {
        console.error("Error in /:userId mood route:", error);
        return c.json(
          {
            success: false,
            error:
              process.env.NODE_ENV === "production"
                ? "Internal Server Error"
                : error instanceof Error
                ? error.message
                : "Unknown error",
          },
          500
        );
      }
    }
  )
.get(
  "/messages/:sessionId",
  zValidator("param", z.object({ sessionId: z.string().min(1) })),
  async (c) => {
    try {
      const { sessionId } = c.req.valid("param");

      // Initialize UpstashRedisChatMessageHistory with the same config as in initializeChain
      const upstashMessageHistory = new UpstashRedisChatMessageHistory({
        sessionId,
        config: {
          url: process.env["UPSTASH_REDIS_URL"],
          token: process.env["UPSTASH_REDIS_TOKEN"],
        },
      });

      // Fetch all messages for the session
      const messages = await upstashMessageHistory.getMessages();
      console.log("messages>>>", messages);

      // Transform the messages into a simpler format
      const formattedMessages = messages.map((message) => ({
        role: message.constructor.name === "HumanMessage" ? "user" : "assistant", // Check constructor name
        content: message.content,
      }));

      return c.json({
        success: true,
        sessionId,
        messages: formattedMessages,
      });
    } catch (error) {
      console.error("Error in /messages/:sessionId route:", error);
      return c.json(
        {
          success: false,
          error:
            process.env.NODE_ENV === "production"
              ? "Internal Server Error"
              : error instanceof Error
              ? error.message
              : "Unknown error",
        },
        500,
      );
    }
  },
)