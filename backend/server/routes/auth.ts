import { Hono } from "hono";
import { HTTPException } from "hono/http-exception";
import { eq } from "drizzle-orm";

import { db } from "@/adapter";
import { userTable } from "@/db/schemas/auth";
import { generateId } from "lucia";

import { zValidator } from "@hono/zod-validator";
import postgres from "postgres";
import { z } from "zod";
import { loginSchema } from "@/lib/types";



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
