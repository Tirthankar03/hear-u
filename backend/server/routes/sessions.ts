import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import { z } from "zod";
import { and, eq, sql } from "drizzle-orm";
import { db } from "@/adapter";

import { UpstashRedisChatMessageHistory } from "@langchain/community/stores/message/upstash_redis";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { sessionTable } from "@/db/schemas/sessions";
import { userTable } from "@/db/schemas/auth";
import { flaggedUsersTable } from "@/db/schemas/flagged";


// Initialize Google Gemini API
const genAI = new GoogleGenerativeAI(process.env["GEMINI_API_KEY"]!);
const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash", 
  systemInstruction: `
You are a summarization tool designed to extract key information from chat conversations to connect users with similar emotional struggles and life experiences. Given a chat text, provide a concise summary that focuses on:
1. The primary emotions expressed by the user, such as sadness, anxiety, loneliness, anger, or hopelessness, with an emphasis on their intensity or context.
2. Specific experiences or situations described by the user that highlight their struggles, such as loss (e.g., bereavement, job loss), relationship challenges (e.g., breakups, conflicts), health issues, or other personal hardships.

Exclude the following:
- References to the AI's identity (e.g., "Hear-U" or "virtual therapist").
- Statements about the AI's limitations or inability to provide help.
- Actionable suggestions or advice provided in the chat.
- Redundant or procedural details about the conversation flow (e.g., greetings or question phrasing).

Focus solely on capturing the user's core emotional state and significant experiences in a vivid, empathetic way that underscores their challenges and makes their struggles relatable to others.
  `,

 });
 const modelEmbed = genAI.getGenerativeModel({ model: "embedding-001" });



 // Utility function to compute cosine similarity
function cosineSimilarity(vecA: number[], vecB: number[]): number {
  const dotProduct = vecA.reduce((sum, a, i) => sum + a * vecB[i], 0);
  const magnitudeA = Math.sqrt(vecA.reduce((sum, a) => sum + a * a, 0));
  const magnitudeB = Math.sqrt(vecB.reduce((sum, b) => sum + b * b, 0));
  if (magnitudeA === 0 || magnitudeB === 0) return 0; // Avoid division by zero
  return dotProduct / (magnitudeA * magnitudeB);
}

// Utility function to normalize a vector
function normalizeVector(vec: number[]): number[] {
  const magnitude = Math.sqrt(vec.reduce((sum, val) => sum + val * val, 0));
  if (magnitude === 0) return vec; // Return original if zero vector
  return vec.map((val) => val / magnitude);
}



export const sessionRouter = new Hono()
.post("/summarize-session/:sessionId", 
  zValidator("param", z.object({ sessionId: z.string().min(1) })),
  async (c) => {
  try {
    const { sessionId } = c.req.valid("param");

    // Retrieve chat history from Redis 
    const upstashMessageHistory = new UpstashRedisChatMessageHistory({
      sessionId,
      config: {
        url: process.env["UPSTASH_REDIS_URL"],
        token: process.env["UPSTASH_REDIS_TOKEN"],
      },
    });

    const messages = await upstashMessageHistory.getMessages();
    console.log("messages>>>", messages);


    const formattedMessages = messages.map((message) => ({
      role: message.constructor.name === "HumanMessage" ? "user" : "assistant", // Check constructor name
      content: message.content,
    }));

    console.log("formattedMessages>>", formattedMessages)

    const chatText = formattedMessages
        .map((msg) => `${msg.role}: ${msg.content}`)
        .join("\n");

        console.log("chatText>>>>", chatText)

    //Generate summary 
    const result = await model.generateContent(`Summarize this chat:\n${chatText}`);

    console.log("result>>>>", result)

    if(!result.response.candidates){
      return c.json({ success: false, error: "unable to summarize. Please try again later" }, 400);
    }

    const chatSummary = result.response.candidates[0].content.parts[0].text 

    console.log("chatSummary>>>>", chatSummary)

    if(!chatSummary){
      return c.json({ success: false, error: "unable to summarize. Please try again later" }, 400);
    }

    const summary = chatSummary.replace("\n", "")

    console.log("summary>>>>", summary)


    // Generate embedding
    const response = await modelEmbed.embedContent(summary);

    const embedding = response.embedding.values



    // 4. Store in sessionTable
    const session = await db.update(sessionTable).set({
      summary,
      embedding,
    }).where(eq(sessionTable.id, sessionId)).returning();

    return c.json({ success: true, message: "Session summarized", summary, embedding,session  });
  } catch (error) {
    console.error("Error summarizing session:", error);
    return c.json({ success: false, error: "Internal Server Error" }, 500);
  }
})
.get("/get-all-flags", async (c) => {
  try {
    // Fetch all flagged users with user details
    const flaggedUsers = await db
      .select({
        id: flaggedUsersTable.id,
        userId: flaggedUsersTable.userId,
        username: userTable.username,
        randname: userTable.randname,
        reason: flaggedUsersTable.reason,
        percentage: flaggedUsersTable.percentage,
        flaggedAt: flaggedUsersTable.flaggedAt,
        reviewed: flaggedUsersTable.reviewed,
      })
      .from(flaggedUsersTable)
      .leftJoin(userTable, eq(flaggedUsersTable.userId, userTable.id))
      .orderBy(flaggedUsersTable.flaggedAt); // Optional: order by flagged time

    // If no flagged users exist, return an empty array with a message
    if (flaggedUsers.length === 0) {
      return c.json({
        success: true,
        message: "No flagged users found",
        data: [],
      });
    }

    return c.json({
      success: true,
      message: "All flagged users fetched",
      data: flaggedUsers,
    });
  } catch (error) {
    console.error("Error fetching flagged users:", error);
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
})
// .get(
//   "/find-similar-users/:userId/:sessionId",
//   zValidator("param", z.object({ userId: z.string(), sessionId: z.string() })),
//   async (c) => {
//     const { userId, sessionId } = c.req.valid("param");

//     // 1. Get the specific session and user profile data
//     const [session] = await db
//       .select({ embedding: sessionTable.embedding })
//       .from(sessionTable)
//       .where(and(eq(sessionTable.id, sessionId), eq(sessionTable.userId, userId)))
//       .limit(1);

//       console.log("session>>>>", session)

//     const [user] = await db
//       .select({ embedding: userTable.embedding, ai_description: userTable.ai_description, tags: userTable.tags })
//       .from(userTable)
//       .where(eq(userTable.id, userId))
//       .limit(1);


//       console.log("user>>>>", user)


//     if (!session?.embedding || !user?.embedding) {
//       return c.json({ error: "Embeddings not found for session or user" }, 404);
//     }

//     // 2. Compute the requesting user's final embedding
//     const sessionEmbedding = session.embedding;
//     const profileEmbedding = user.embedding;
//     const finalEmbedding = sessionEmbedding.map((val, i) =>
//       0.7 * val + 0.3 * profileEmbedding[i] // Weighted: 70% session, 30% profile
//     );

//     console.log("sessionEmbedding>>>>", sessionEmbedding)
//     console.log("profileEmbedding>>>>", profileEmbedding)
//     console.log("finalEmbedding>>>>", finalEmbedding)


//     // 3. Compute combined embeddings for all users with sessions
//     const allUsersWithSessions = await db
//       .select({
//         userId: userTable.id,
//         username: userTable.username,
//         profileEmbedding: userTable.embedding,
//         sessionEmbedding: sessionTable.embedding,
//       })
//       .from(userTable)
//       .leftJoin(sessionTable, eq(sessionTable.userId, userTable.id))
//       .where(sql`${sessionTable.embedding} IS NOT NULL AND ${userTable.embedding} IS NOT NULL`);


//     console.log("allUsersWithSessions>>>>", allUsersWithSessions)


//     // 4. Calculate similarity for each user
//     const similarUsers = allUsersWithSessions
//       .map((otherUser) => {
//         // Compute other user's final embedding (70% session, 30% profile)
//         const otherFinalEmbedding = otherUser.sessionEmbedding
//           ? otherUser.sessionEmbedding.map((val, i) =>
//               0.7 * val + 0.3 * otherUser.profileEmbedding[i]
//             )
//           : otherUser.profileEmbedding; // Fallback to profile if no session


//           console.log("otherFinalEmbedding>>>>", otherFinalEmbedding)


//         // Compute cosine similarity
//         const distance = cosineDistance(finalEmbedding, otherFinalEmbedding);

//         console.log("distance>>>>", distance)

//         const similarity = 1 - distance;

//         return {
//           id: otherUser.userId,
//           username: otherUser.username,
//           similarity,
//         };
//       })
//       .filter((u) => u.similarity > 0.1 && u.id !== userId) // Exclude self, apply threshold
//       .sort((a, b) => b.similarity - a.similarity) // Sort by similarity descending
//       .slice(0, 10); // Limit to top 10

//     return c.json({
//       message: "Similar users found",
//       data: similarUsers,
//     });
//   }
// );
// .get(
//   "/find-similar-users/:userId/:sessionId",
//   zValidator("param", z.object({ userId: z.string(), sessionId: z.string() })),
//   async (c) => {
//     const { userId, sessionId } = c.req.valid("param");

//     // 1. Get the specific session and user profile data
//     const [session] = await db
//       .select({ embedding: sessionTable.embedding })
//       .from(sessionTable)
//       .where(and(eq(sessionTable.id, sessionId), eq(sessionTable.userId, userId)))
//       .limit(1);
//     console.log("session>>>>", session);

//     const [user] = await db
//       .select({
//         embedding: userTable.embedding,
//         ai_description: userTable.ai_description,
//         tags: userTable.tags,
//       })
//       .from(userTable)
//       .where(eq(userTable.id, userId))
//       .limit(1);
//     console.log("user>>>>", user);

//     if (!session?.embedding || !user?.embedding) {
//       return c.json({ error: "Embeddings not found for session or user" }, 404);
//     }

//     // 2. Compute the requesting user's final embedding
//     const sessionEmbedding = session.embedding;
//     const profileEmbedding = user.embedding;
//     const rawFinalEmbedding = sessionEmbedding.map((val, i) => 0.7 * val + 0.3 * profileEmbedding[i]);
//     const finalEmbedding = normalizeVector(rawFinalEmbedding); // Normalize the combined vector
//     console.log("sessionEmbedding>>>>", sessionEmbedding);
//     console.log("profileEmbedding>>>>", profileEmbedding);
//     console.log("finalEmbedding>>>>", finalEmbedding);

//     // 3. Compute combined embeddings for all users with sessions
//     const allUsersWithSessions = await db
//       .select({
//         userId: userTable.id,
//         username: userTable.username,
//         profileEmbedding: userTable.embedding,
//         sessionEmbedding: sessionTable.embedding,
//       })
//       .from(userTable)
//       .leftJoin(sessionTable, eq(sessionTable.userId, userTable.id))
//       .where(sql`${sessionTable.embedding} IS NOT NULL AND ${userTable.embedding} IS NOT NULL`);
//     console.log("allUsersWithSessions>>>>", allUsersWithSessions);

//     // 4. Calculate similarity for each user
//     const similarUsers = allUsersWithSessions
//       .map((otherUser) => {
//         const otherRawFinalEmbedding = otherUser.sessionEmbedding
//           ? otherUser.sessionEmbedding.map((val, i) => 0.7 * val + 0.3 * otherUser.profileEmbedding[i])
//           : otherUser.profileEmbedding;
//         const otherFinalEmbedding = normalizeVector(otherRawFinalEmbedding);
//         console.log("otherFinalEmbedding>>>>", otherFinalEmbedding);

//         // Use standard cosine similarity
//         const similarity = cosineSimilarity(finalEmbedding, otherFinalEmbedding);
//         console.log("similarity>>>>", similarity, "for user:", otherUser.userId);

//         return {
//           id: otherUser.userId,
//           username: otherUser.username,
//           similarity,
//         };
//       })
//       .filter((u) => u.similarity > 0.1 && u.id !== userId) // Threshold 0.1, exclude self
//       .sort((a, b) => b.similarity - a.similarity)
//       .slice(0, 10);

//     console.log("similarUsers>>>>", similarUsers);

//     return c.json({
//       message: "Similar users found",
//       data: similarUsers,
//     });
//   }
// );
.get(
  "/find-similar-users/:userId/:sessionId",
  zValidator("param", z.object({ userId: z.string(), sessionId: z.string() })),
  async (c) => {
    const { userId, sessionId } = c.req.valid("param");

    // 1. Get the specific session and user profile data
    const [session] = await db
      .select({ embedding: sessionTable.embedding })
      .from(sessionTable)
      .where(and(eq(sessionTable.id, sessionId), eq(sessionTable.userId, userId)))
      .limit(1);
    console.log("session>>>>", session);

    const [user] = await db
      .select({
        embedding: userTable.embedding,
        ai_description: userTable.ai_description,
        tags: userTable.tags,
      })
      .from(userTable)
      .where(eq(userTable.id, userId))
      .limit(1);
    console.log("user>>>>", user);

    if (!session?.embedding || !user?.embedding) {
      return c.json({ error: "Embeddings not found for session or user" }, 404);
    }

    // 2. Compute the requesting user's final embedding
    const sessionEmbedding = session.embedding;
    const profileEmbedding = user.embedding;
    const rawFinalEmbedding = sessionEmbedding.map((val, i) => 0.7 * val + 0.3 * profileEmbedding[i]);
    const finalEmbedding = normalizeVector(rawFinalEmbedding);
    console.log("sessionEmbedding>>>>", sessionEmbedding);
    console.log("profileEmbedding>>>>", profileEmbedding);
    console.log("finalEmbedding>>>>", finalEmbedding);

    // 3. Compute combined embeddings for all users with sessions
    const allUsersWithSessions = await db
      .select({
        id: userTable.id,
        username: userTable.username,
        randname: userTable.randname,
        email: userTable.email,
        description: userTable.description,
        tags: userTable.tags,
        embedding: userTable.embedding,
        ai_description: userTable.ai_description,
        sessionEmbedding: sessionTable.embedding, // Needed for similarity calculation
      })
      .from(userTable)
      .leftJoin(sessionTable, eq(sessionTable.userId, userTable.id))
      .where(sql`${sessionTable.embedding} IS NOT NULL AND ${userTable.embedding} IS NOT NULL`);
    console.log("allUsersWithSessions>>>>", allUsersWithSessions);

    // 4. Calculate similarity and include full user data
    const similarUsers = allUsersWithSessions
      .map((otherUser) => {
        const otherRawFinalEmbedding = otherUser.sessionEmbedding
          ? otherUser.sessionEmbedding.map((val, i) => 0.7 * val + 0.3 * otherUser.embedding[i])
          : otherUser.embedding;
        const otherFinalEmbedding = normalizeVector(otherRawFinalEmbedding);
        console.log("otherFinalEmbedding>>>>", otherFinalEmbedding);

        const similarity = cosineSimilarity(finalEmbedding, otherFinalEmbedding);
        console.log("similarity>>>>", similarity, "for user:", otherUser.id);

        return {
          id: otherUser.id,
          username: otherUser.username,
          randname: otherUser.randname,
          email: otherUser.email,
          description: otherUser.description,
          tags: otherUser.tags,
          ai_description: otherUser.ai_description,
          similarity,
        };
      })
      .filter((u) => u.similarity > 0.1 && u.id !== userId) // Threshold 0.1, exclude self
      .sort((a, b) => b.similarity - a.similarity)
      .slice(0, 10);

    console.log("similarUsers>>>>", similarUsers);

    return c.json({
      message: "Similar users found",
      data: similarUsers,
    });
  }
);