import { index, pgTable, text, vector } from "drizzle-orm/pg-core";
import { userTable } from "./auth";
import { relations } from "drizzle-orm";

export const sessionTable = pgTable("session", {
  id: text("id").primaryKey(), // Use the sessionId from uuidv4
  userId: text("user_id").notNull().references(() => userTable.id),
  title: text("title"), // Optional: A title for the session
  summary: text("summary"), // Chat summary generated by the LLM
  embedding: vector("embedding", { dimensions: 768 }), // Chat summary embedding
},
(table) =>  [
      index("session_embedding_idx").using(
        "hnsw",
        table.embedding.op("vector_cosine_ops")
      ),
    ]
);

export const sessionRelations = relations(sessionTable, ({ one }) => ({
  user: one(userTable, {
    fields: [sessionTable.userId],
    references: [userTable.id],
  }),
}));