import { pgTable, serial, text } from "drizzle-orm/pg-core";


export const articlesTable = pgTable("articles", {
    id: serial("id").primaryKey(),
    title: text("title").notNull(),
    imageUrl: text("image_url").notNull(), // URL to the article image
    content: text("content").notNull(), // Article text
  });