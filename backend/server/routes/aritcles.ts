// routers/articles.ts
import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import { z } from "zod";
import { eq } from "drizzle-orm";
import { deleteFromCloudinary, uploadImageToCloudinary } from "@/lib/cloudinary";
import { db } from "@/adapter";
import { articlesTable } from "@/db/schemas/articles";

export const articleRouter = new Hono()
    .post(
    "/try",
    async (c) => {
        try {
         const body = await c.req.parseBody()

         console.log("body>>>>", body['file'])


        const formData = await c.req.formData();
        const file = formData.get("file") as unknown as File;

        console.log("file>>>>", file)
        console.log("file>>>>", file)

        return c.json({ success: true, data: body });
        } catch (error) {
          return c.json({ success: false, error: error instanceof Error ? error.message : "Unknown error" }, 500);
        }
      }
)
  // Create
  .post(
    "/",
    zValidator(
      "form",
      z.object({
        title: z.string().min(1),
        content: z.string().min(1),
      })
    ),
    async (c) => {
      try {
        const formData = await c.req.formData();
        const file = formData.get("file") as unknown as File;

        const { title, content } = c.req.valid("form");

        if (!file) {
          return c.json({ success: false, error: "Image is required" }, 400);
        }

        const buffer = Buffer.from(await file.arrayBuffer());
        const cloudinaryResponse: any = await uploadImageToCloudinary(buffer, file.name);
        
        const article = await db.insert(articlesTable).values({
          title,
          imageUrl: cloudinaryResponse.secure_url,
          content,
        }).returning();

        return c.json({ success: true, data: article[0] });
      } catch (error) {
        console.log("error>>>>", error)
        return c.json({ success: false, error: error instanceof Error ? error.message : "Unknown error" }, 500);
      }
    }
  )
  // Read all
  .get("/", async (c) => {
    try {
      const articles = await db.select().from(articlesTable);
      return c.json({ success: true, data: articles });
    } catch (error) {
      return c.json({ success: false, error: "Failed to fetch articles" }, 500);
    }
  })
  // Read one
  .get("/:id", async (c) => {
    try {
      const id = parseInt(c.req.param("id"));
      const article = await db.select().from(articlesTable).where(eq(articlesTable.id, id));
      if (!article.length) return c.json({ success: false, error: "Article not found" }, 404);
      return c.json({ success: true, data: article[0] });
    } catch (error) {
      return c.json({ success: false, error: "Failed to fetch article" }, 500);
    }
  })
  // Update
  .put(
    "/:id",
    zValidator(
      "form",
      z.object({
        title: z.string().min(1).optional(),
        content: z.string().min(1).optional(),
      })
    ),
    async (c) => {
      try {
        const id = parseInt(c.req.param("id"));
        const formData = await c.req.formData();
        const file = formData.get("file") as unknown as File;
        const values = c.req.valid("form");

        const existingArticle = await db.select().from(articlesTable).where(eq(articlesTable.id, id));
        if (!existingArticle.length) return c.json({ success: false, error: "Article not found" }, 404);

        let imageUrl = existingArticle[0].imageUrl;
        if (file) {
          await deleteFromCloudinary(imageUrl);
          const buffer = Buffer.from(await file.arrayBuffer());
          const cloudinaryResponse: any = await uploadImageToCloudinary(buffer, file.name);
          imageUrl = cloudinaryResponse.secure_url;
        }

        const updatedArticle = await db.update(articlesTable)
          .set({ ...values, imageUrl })
          .where(eq(articlesTable.id, id))
          .returning();

        return c.json({ success: true, data: updatedArticle[0] });
      } catch (error) {
        return c.json({ success: false, error: "Failed to update article" }, 500);
      }
    }
  )
  // Delete
  .delete("/:id", async (c) => {
    try {
      const id = parseInt(c.req.param("id"));
      const article = await db.select().from(articlesTable).where(eq(articlesTable.id, id));
      if (!article.length) return c.json({ success: false, error: "Article not found" }, 404);

      await deleteFromCloudinary(article[0].imageUrl);
      await db.delete(articlesTable).where(eq(articlesTable.id, id));

      return c.json({ success: true });
    } catch (error) {
      return c.json({ success: false, error: "Failed to delete article" }, 500);
    }
  });