// routers/audios.ts
import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import { z } from "zod";

import { eq } from "drizzle-orm";
import { db } from "@/adapter";
import { audiosTable } from "@/db/schemas/audio";
import { deleteFromCloudinary, uploadAudioToCloudinary } from "@/lib/cloudinary";
import { formatDuration } from "@/lib/utils";

export const audioRouter = new Hono()
  // Create
  .post(
    "/",
    zValidator(
      "form",
      z.object({
        category: z.enum(["Breath", "Meditation", "Sleep Stories", "Sleep Sounds"]),
        title: z.string().min(1)
      })
    ),
    async (c) => {
      try {
        const formData = await c.req.formData();
        const file = formData.get("file") as unknown as File;
        const { category, title } = c.req.valid("form");

        if (!file) {
          return c.json({ success: false, error: "Audio file is required" }, 400);
        }

        const buffer = Buffer.from(await file.arrayBuffer());
        const cloudinaryResponse: any = await uploadAudioToCloudinary(buffer, file.name);

        const duration = Math.round(cloudinaryResponse.duration);
        console.log("duration>>>", duration)
        const formattedDuration = formatDuration(duration);

        console.log("formattedDuration>>>", formattedDuration)

        
        const audio = await db.insert(audiosTable).values({
          category,
          title,
          url: cloudinaryResponse.secure_url,
          duration: formattedDuration,
        }).returning();

        console.log("audio>>>", audio)


        return c.json({ success: true, data: audio[0] });
      } catch (error) {
        return c.json({ success: false, error: error instanceof Error ? error.message : "Unknown error" }, 500);
      }
    }
  )
  // Read all
  .get("/", async (c) => {
    try {
      const audios = await db.select().from(audiosTable);
      return c.json({ success: true, data: audios });
    } catch (error) {
      return c.json({ success: false, error: "Failed to fetch audios" }, 500);
    }
  })
  // Read one
  .get("/:id", async (c) => {
    try {
      const id = parseInt(c.req.param("id"));
      const audio = await db.select().from(audiosTable).where(eq(audiosTable.id, id));
      if (!audio.length) return c.json({ success: false, error: "Audio not found" }, 404);
      return c.json({ success: true, data: audio[0] });
    } catch (error) {
      return c.json({ success: false, error: "Failed to fetch audio" }, 500);
    }
  })
  // Update
  .put(
    "/:id",
    zValidator(
      "form",
      z.object({
        category: z.enum(["Breath", "Meditation", "Sleep Stories", "Sleep Sounds"]).optional(),
        title: z.string().min(1).optional()
      })
    ),
    async (c) => {
      try {
        const id = parseInt(c.req.param("id"));
        const formData = await c.req.formData();
        const file = formData.get("file") as unknown as File;
        const values = c.req.valid("form");

        const existingAudio = await db.select().from(audiosTable).where(eq(audiosTable.id, id));
        if (!existingAudio.length) return c.json({ success: false, error: "Audio not found" }, 404);

        let url = existingAudio[0].url;
        let duration = existingAudio[0].duration;
        if (file) {
          await deleteFromCloudinary(url, "video");
          const buffer = Buffer.from(await file.arrayBuffer());
          const cloudinaryResponse: any = await uploadAudioToCloudinary(buffer, file.name);
          url = cloudinaryResponse.secure_url;

          const newDuration = Math.round(cloudinaryResponse.duration);
          const formattedDuration = formatDuration(newDuration);

          duration = formattedDuration
          
        }

        const updatedAudio = await db.update(audiosTable)
          .set({ ...values, url, duration })
          .where(eq(audiosTable.id, id))
          .returning();

        return c.json({ success: true, data: updatedAudio[0] });
      } catch (error) {
        return c.json({ success: false, error: "Failed to update audio" }, 500);
      }
    }
  )
  // Delete
  .delete("/:id", async (c) => {
    try {
      const id = parseInt(c.req.param("id"));
      const audio = await db.select().from(audiosTable).where(eq(audiosTable.id, id));
      if (!audio.length) return c.json({ success: false, error: "Audio not found" }, 404);

      await deleteFromCloudinary(audio[0].url, "video");
      await db.delete(audiosTable).where(eq(audiosTable.id, id));

      return c.json({ success: true });
    } catch (error) {
      return c.json({ success: false, error: "Failed to delete audio" }, 500);
    }
  });