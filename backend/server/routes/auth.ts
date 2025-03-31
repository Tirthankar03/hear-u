import { Hono } from "hono";
import { HTTPException } from "hono/http-exception";
import { eq } from "drizzle-orm";

import { db } from "@/adapter";
// import type { Context } from "@/context";
import { userTable } from "@/db/schemas/auth";
// import { lucia } from "@/lucia";
// import { loggedIn } from "@/middleware/loggedIn";
import { zValidator } from "@hono/zod-validator";
import { generateId } from "lucia";
import postgres from "postgres";
import { z } from "zod";

import {
  loginSchema,
  // type SuccessResponse
} from "@/lib/types";
import { GoogleGenerativeAI } from "@google/generative-ai";


export const userUpdateSchema = z.object({
  username: z.string().min(3).optional(),
  randname: z.string().optional(),
  password: z.string().min(3).max(255).optional(),
  email: z.string().email().optional(),
  description: z.string().optional(),
  tags: z
  .string()
  .optional()
  .transform((val) => (val ? JSON.parse(val) : undefined)) // Parse stringified array
  .pipe(z.array(z.string()).optional()), // Validate as array of strings
});

const genAI = new GoogleGenerativeAI(process.env["GEMINI_API_KEY"]!);
const embedModel = genAI.getGenerativeModel({ model: "embedding-001" });
const summaryModel = genAI.getGenerativeModel({
  model: "gemini-1.5-flash", // For summarization
  systemInstruction: `
    You are a summarization tool designed to extract key information from user descriptions to connect users with similar emotional struggles and life experiences. Given a description, provide a concise summary that focuses on:
    1. The primary emotions expressed by the user, such as sadness, anxiety, loneliness, anger, or hopelessness, with an emphasis on their intensity or context.
    2. Specific experiences or situations described by the user that highlight their struggles, such as loss (e.g., bereavement, job loss), relationship challenges (e.g., breakups, conflicts), health issues, or other personal hardships.
  `,
});



export const authRouter = new Hono()
  //signup
  .post("/signup", zValidator("form", loginSchema), async (c) => {
    const { username, password, email } = c.req.valid("form");

    console.log("username>>>>", username);
    console.log("password>>>>", password);

    const passwordHash = await Bun.password.hash(password);
    const userId = generateId(15);
    const randname = generateId(6);

    try {
      const user = await db
        .insert(userTable)
        .values({
          id: userId,
          username,
          randname,
          email,
          password_hash: passwordHash,
        })
        .returning();

      // const session = await lucia.createSession(userId, { username });
      // const sessionCookie = lucia.createSessionCookie(session.id).serialize();

      // c.header("Set-Cookie", sessionCookie, { append: true });

      return c.json(
        {
          success: true,
          message: "User created",
          data: { user }, // Return userId for client use
        },
        201,
      );
    } catch (error) {
      if (error instanceof postgres.PostgresError && error.code === "23505") {
        throw new HTTPException(409, {
          message: "Username already used",
          cause: { form: true },
        });
      }
      throw new HTTPException(500, { message: "Failed to create user" });
    }
  })
  //login
  .post("/login", zValidator("form", loginSchema), async (c) => {
    const { username, password } = c.req.valid("form");
    console.log(username, password);
    console.log("username>>>>", username);
    console.log("password>>>>", password);

    const [existingUser] = await db
      .select()
      .from(userTable)
      .where(eq(userTable.username, username))
      .limit(1);

    if (!existingUser) {
      throw new HTTPException(401, {
        message: "Incorrect username",
        cause: { form: true },
      });
    }

    const validPassword = await Bun.password.verify(
      password,
      existingUser.password_hash,
    );
    if (!validPassword) {
      throw new HTTPException(401, {
        message: "Incorrect password",
        cause: { form: true },
      });
    }

    // const session = await lucia.createSession(existingUser.id, { username });
    // const sessionCookie = lucia.createSessionCookie(session.id).serialize();

    // c.header("Set-Cookie", sessionCookie, { append: true });

    return c.json(
      {
        success: true,
        message: "Logged in",
        data: { user: existingUser }, // Return userId for client use
      },
      200,
    );
  })
  //no logout route as meaningless
  // .get("/logout", async (c) => {
  //   const session = c.get("session");
  //   if (!session) {
  //     return c.redirect("/");
  //   }

  //   await lucia.invalidateSession(session.id);
  //   c.header("Set-Cookie", lucia.createBlankSessionCookie().serialize());
  //   return c.redirect("/");
  // })
  //get user by id
  .get(
    "/:id",
    zValidator("param", z.object({ id: z.coerce.string() })),
    async (c) => {
      const { id } = c.req.valid("param");

      const [existingUser] = await db
        .select()
        .from(userTable)
        .where(eq(userTable.id, id))
        .limit(1);

      if (!existingUser) {
        throw new HTTPException(401, {
          message: "user doesn't exist",
          cause: { form: true },
        });
      }

      // const user = c.get("user")!;
      return c.json({
        success: true,
        message: "User fetched",
        data: { user: existingUser },
      });
    },
  )
  // Add this to your existing authRouter chain
  .put(
    "/:id",
    zValidator("param", z.object({ id: z.coerce.string() })),
    zValidator("form", userUpdateSchema.partial()),
    async (c) => {
      const { id } = c.req.valid("param");
      const data = c.req.valid("form");
  
      // Check if user exists
      const [existingUser] = await db
        .select()
        .from(userTable)
        .where(eq(userTable.id, id))
        .limit(1);
  
      if (!existingUser) {
        throw new HTTPException(404, {
          message: "User not found",
          cause: { form: true },
        });
      }
  
      // Prepare update data
      const updateData: Partial<typeof userTable.$inferInsert> = {};
  
      if (data.username) updateData.username = data.username;
      if (data.randname) updateData.randname = data.randname;
      if (data.password) updateData.password_hash = await Bun.password.hash(data.password);
      if (data.email) updateData.email = data.email;
      if (data.description) updateData.description = data.description; // Store original description
      if (data.tags) updateData.tags = data.tags;
  
      // Generate summary and embedding if description or tags are updated
      if (data.description || data.tags) {
        let summary = "";
        if (data.description) {
          const summaryResult = await summaryModel.generateContent(
            `Summarize this description: ${data.description}`
          );
          console.log("summaryResult>>>>", summaryResult);
  
          if (!summaryResult.response.candidates) {
            return c.json(
              { success: false, error: "Unable to summarize. Please try again later" },
              400
            );
          }
  
          const descriptionSummary = summaryResult.response.candidates[0].content.parts[0].text;
          if (!descriptionSummary) {
            return c.json(
              { success: false, error: "Unable to summarize. Please try again later" },
              400
            );
          }
  
          summary = descriptionSummary.replace("\n", "").trim();
          updateData.ai_description = summary; // Store the AI-generated summary
          console.log("summary>>>>", summary);
        } else if (existingUser.ai_description) {
          summary = existingUser.ai_description; // Fallback to existing ai_description if no new description
        } else if (existingUser.description) {
          summary = existingUser.description; // Fallback to existing description as last resort
        }
  
        // Combine summary with tags for embedding
        const profileText = `${summary} ${(data.tags || existingUser.tags || []).join(" ")}`.trim();
        if (profileText) {
          const embedResponse = await embedModel.embedContent(profileText);
          updateData.embedding = embedResponse.embedding.values;
        }
      }
  
      // If no data to update, return early
      if (Object.keys(updateData).length === 0) {
        throw new HTTPException(400, {
          message: "No update data provided",
          cause: { form: true },
        });
      }
  
      try {
        const [updatedUser] = await db
          .update(userTable)
          .set(updateData)
          .where(eq(userTable.id, id))
          .returning();
  
        return c.json(
          {
            success: true,
            message: "User updated successfully",
            data: { user: updatedUser },
          },
          200
        );
      } catch (error) {
        if (error instanceof postgres.PostgresError && error.code === "23505") {
          throw new HTTPException(409, {
            message: "Username already taken",
            cause: { form: true },
          });
        }
        throw new HTTPException(500, {
          message: "Failed to update user",
        });
      }
    }
  );