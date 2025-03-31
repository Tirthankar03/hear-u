import { pgTable, text, timestamp } from "drizzle-orm/pg-core";
import { userTable } from "./auth";
import { relations } from "drizzle-orm";




export const chatTable = pgTable("chat", {
    id: text("id").primaryKey(), // UUID for chat instance
    user1Id: text("user1_id").notNull().references(() => userTable.id),
    user2Id: text("user2_id").notNull().references(() => userTable.id),
    startedAt: timestamp("started_at").notNull().defaultNow(),
  });

export const chatRelations = relations(chatTable, ({ one }) => ({
    user1: one(userTable, {
      fields: [chatTable.user1Id],
      references: [userTable.id],
      relationName: "user1_chats",
    }),
    user2: one(userTable, {
      fields: [chatTable.user2Id],
      references: [userTable.id],
      relationName: "user2_chats",
    }),
  }));