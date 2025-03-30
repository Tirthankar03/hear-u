import { Hono } from "hono";
import { HTTPException } from "hono/http-exception";
import { eq, and, sql, gte } from "drizzle-orm";
import { zValidator } from "@hono/zod-validator";
import { z } from "zod";
import { dailyTasksTable } from "@/db/schemas/dailyTasks";
import { db } from "@/adapter";
import { audiosTable } from "@/db/schemas/audio";
import { articlesTable } from "@/db/schemas/articles";

const tasksRouter = new Hono();



// GET /api/tasks/daily - Fetch or generate daily tasks
tasksRouter
.get(
  "/daily/:userId",
  zValidator("param", z.object({ userId: z.string().min(1) })),
  async (c) => {
    const { userId } = c.req.valid("param");

    // Current time and 5-minute window
    const now = new Date();
    const fiveMinutesAgo = new Date(now.getTime() - 5 * 60 * 1000); // 5 minutes ago

    // Check if tasks exist within the last 5 minutes
    let tasks = await db
      .select({
        id: dailyTasksTable.id,
        section: dailyTasksTable.section,
        category: dailyTasksTable.category,
        isCompleted: dailyTasksTable.isCompleted,
        audio: audiosTable,
        article: articlesTable,
      })
      .from(dailyTasksTable)
      .leftJoin(audiosTable, eq(dailyTasksTable.audioId, audiosTable.id))
      .leftJoin(articlesTable, eq(dailyTasksTable.articleId, articlesTable.id))
      .where(
        and(
          eq(dailyTasksTable.userId, userId),
          gte(dailyTasksTable.createdAt, fiveMinutesAgo) // Tasks from last 5 minutes
        )
      );

    // If no tasks exist within the last 5 minutes, generate them
    if (tasks.length === 0) {
      const [
        breathAudio,
        article,
        meditationAudio,
        sleepStoryAudio,
        sleepSoundAudio,
      ] = await Promise.all([
        db.select().from(audiosTable).where(eq(audiosTable.category, "Breath")).orderBy(sql`RANDOM()`).limit(1),
        db.select().from(articlesTable).orderBy(sql`RANDOM()`).limit(1),
        db.select().from(audiosTable).where(eq(audiosTable.category, "Meditation")).orderBy(sql`RANDOM()`).limit(1),
        db.select().from(audiosTable).where(eq(audiosTable.category, "Sleep Stories")).orderBy(sql`RANDOM()`).limit(1),
        db.select().from(audiosTable).where(eq(audiosTable.category, "Sleep Sounds")).orderBy(sql`RANDOM()`).limit(1),
      ]);

      const newTasks = [
        { section: "Morning", category: "Breath", audioId: breathAudio[0]?.id, articleId: null },
        { section: "Morning", category: "Articles", audioId: null, articleId: article[0]?.id },
        { section: "Day", category: "Meditation", audioId: meditationAudio[0]?.id, articleId: null },
        { section: "Evening", category: "Sleep Stories", audioId: sleepStoryAudio[0]?.id, articleId: null },
        { section: "Evening", category: "Sleep Sounds", audioId: sleepSoundAudio[0]?.id, articleId: null },
      ];

      // Insert tasks in a transaction
      await db.transaction(async (tx) => {
        for (const task of newTasks) {
          await tx.insert(dailyTasksTable).values({
            userId,
            createdAt: now, // Explicitly set to current time
            section: task.section,
            category: task.category,
            audioId: task.audioId,
            articleId: task.articleId,
            isCompleted: false,
          });
        }
      });

      // Fetch the newly inserted tasks
      tasks = await db
        .select({
          id: dailyTasksTable.id,
          section: dailyTasksTable.section,
          category: dailyTasksTable.category,
          isCompleted: dailyTasksTable.isCompleted,
          audio: audiosTable,
          article: articlesTable,
        })
        .from(dailyTasksTable)
        .leftJoin(audiosTable, eq(dailyTasksTable.audioId, audiosTable.id))
        .leftJoin(articlesTable, eq(dailyTasksTable.articleId, articlesTable.id))
        .where(
          and(
            eq(dailyTasksTable.userId, userId),
            gte(dailyTasksTable.createdAt, fiveMinutesAgo)
          )
        );
    }

    // Group tasks by section
    const groupedTasks = {
      Morning: tasks.filter((t) => t.section === "Morning"),
      Day: tasks.filter((t) => t.section === "Day"),
      Evening: tasks.filter((t) => t.section === "Evening"),
    };

    return c.json({ success: true, data: groupedTasks });
  }
)
//to complete a task
.put("/:taskId/complete",
    zValidator("param", z.object({ taskId: z.string().min(1) })),
    zValidator("form", z.object({ userId: z.string().min(1) })),
    async (c) => {
//   const user = c.get("user");
  const {taskId} = c.req.valid("param");
  const { userId } = c.req.valid("form");

  const task = await db
    .select()
    .from(dailyTasksTable)
    .where(
      and(
        eq(dailyTasksTable.id, parseInt(taskId)),
        eq(dailyTasksTable.userId, userId)
      )
    ).limit(1)

  if (!task) throw new HTTPException(404, { message: "Task not found" });

  await db
    .update(dailyTasksTable)
    .set({ isCompleted: true })
    .where(eq(dailyTasksTable.id, parseInt(taskId)));

  return c.json({ success: true, message: "Task marked as completed", task });
});

export { tasksRouter };