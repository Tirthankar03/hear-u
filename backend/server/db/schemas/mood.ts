import { pgEnum, pgTable, text, timestamp } from "drizzle-orm/pg-core";
import { sql } from "drizzle-orm";
import { userTable } from "./auth";

// Define the mood enum
export const moodEnum = pgEnum("mood", [
  "very bad",
  "bad",
  "neutral",
  "good",
  "very good",
]);

// Define the mood assessments table
export const moodAssessmentsTable = pgTable("mood_assessments", {
  id: text("id").primaryKey().default(sql`gen_random_uuid()`),
  userId: text("user_id")
    .notNull()
    .references(() => userTable.id),
  mood: moodEnum("mood").notNull(),
  assessedAt: timestamp("assessed_at").notNull().defaultNow(),
});