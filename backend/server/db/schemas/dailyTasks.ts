import { pgTable, serial, text, date, integer, boolean, index, timestamp } from "drizzle-orm/pg-core";
import { userTable } from "./auth";
import { audiosTable } from "./audio";
import { articlesTable } from "./articles";
import { sql } from "drizzle-orm";

export const dailyTasksTable = pgTable("daily_tasks", {
  id: serial("id").primaryKey(),
  userId: text("user_id").notNull().references(() => userTable.id),
  date: date("date"), // Date of the task (e.g., "2023-10-01")
  section: text("section").notNull(), // "Morning", "Day", "Evening"
  category: text("category").notNull(), // "Breath", "Articles", "Meditation", "Sleep Stories", "Sleep Sounds"
  audioId: integer("audio_id").references(() => audiosTable.id), // Nullable
  articleId: integer("article_id").references(() => articlesTable.id), // Nullable
  isCompleted: boolean("is_completed").default(false).notNull(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
}, (table) => ({
  // Ensure that exactly one of audioId or articleId is set
  contentCheck: sql`CHECK ((audio_id IS NOT NULL AND article_id IS NULL) OR (audio_id IS NULL AND article_id IS NOT NULL))`,
  // Index for faster queries by user and date
  userDateIdx: index("daily_tasks_user_date_idx").on(table.userId, table.date),
}));