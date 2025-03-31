import { pgTable, text, timestamp, serial, json, boolean } from "drizzle-orm/pg-core";
import { userTable } from "@/db/schemas/auth";
import { relations } from "drizzle-orm";

export const flaggedUsersTable = pgTable("flagged_users", {
  id: serial("id").primaryKey(),
  userId: text("user_id")
    .notNull()
    .references(() => userTable.id, { onDelete: "cascade" }),
  reason: text("reason").notNull(), // e.g., "Potential self-harm indicators"
  flaggedAt: timestamp("flagged_at").defaultNow().notNull(),
  percentage: text("percentage").notNull(), 
  reviewed: boolean("reviewed").default(false).notNull(), // Admin review status
  sessionId: text("sessionId")
});

export const flaggedUsersRelations = relations(flaggedUsersTable, ({ one }) => ({
  user: one(userTable, {
    fields: [flaggedUsersTable.userId],
    references: [userTable.id],
  }),
}));