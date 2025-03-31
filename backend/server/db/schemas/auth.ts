import { relations, sql } from "drizzle-orm";
import { index, pgTable, text, vector } from "drizzle-orm/pg-core";

import { commentsTable } from "./comments";


import { postsTable } from "./posts";
import { commentUpvotesTable, postUpvotesTable } from "./upvotes";
import { sessionTable } from "./sessions";
import { chatTable } from "./chats";

export const userTable = pgTable("user", {
  id: text("id").primaryKey(),
  username: text("username").notNull().unique(),
  password_hash: text("password_hash").notNull(),
  randname: text("randname")
    .notNull()
    .default(sql`md5(random()::text)`), // Generates a random hash-like name
    email: text("email"), // Optional: Add if you want to store emails
    description: text("description"), // User's self-description
    tags: text("tags").array(), // e.g., ["anxiety", "stress"]
    embedding: vector("embedding", { dimensions: 768 }), // For profile embedding
    ai_description: text("ai_description"), // AI's description
},
(table) => [
    index("user_embedding_idx").using(
      "hnsw",
      table.embedding.op("vector_cosine_ops")
    ),
  ],
);



export const userRelations = relations(userTable, ({ many }) => ({
  posts: many(postsTable, { relationName: "author" }),
  comments: many(commentsTable, { relationName: "author" }),
  postUpvotes: many(postUpvotesTable, {
    relationName: "postUpvotes",
  }),
  commentUpvotes: many(commentUpvotesTable, {
    relationName: "commentUpvotes",
  }),
  sessions: many(sessionTable),
  chatsAsUser1: many(chatTable, { relationName: "user1_chats" }),
  chatsAsUser2: many(chatTable, { relationName: "user2_chats" }),
}));

