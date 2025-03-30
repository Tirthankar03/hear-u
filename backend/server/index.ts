import { Hono } from "hono";
import { cors } from "hono/cors";
import { HTTPException } from "hono/http-exception";

import { type ErrorResponse } from "@/lib/types";

import { authRouter } from "./routes/auth";
import { commentsRouter } from "./routes/comments";
import { postRouter } from "./routes/posts";
import { audioRouter } from "./routes/audio";
import { articleRouter } from "./routes/aritcles";
import { tasksRouter } from "./routes/tasks";


// import { serveStatic } from "hono/bun";

const app = new Hono();

app.use("*", cors());

const routes = app
  .basePath("/api")
  .route("/auth", authRouter)
  .route("/posts", postRouter)
  .route("/comments", commentsRouter)
  .route("/audios", audioRouter)
  .route("/articles", articleRouter)
  .route("/tasks", tasksRouter)

  
app.onError((err, c) => {
  if (err instanceof HTTPException) {
    const errResponse =
      err.res ??
      c.json<ErrorResponse>(
        {
          success: false,
          error: err.message,
          isFormError:
            err.cause && typeof err.cause === "object" && "form" in err.cause
              ? err.cause.form === true
              : false,
        },
        err.status,
      );
    return errResponse;
  }

  return c.json<ErrorResponse>(
    {
      success: false,
      error:
        process.env.NODE_ENV === "production"
          ? "Interal Server Error"
          : (err.stack ?? err.message),
    },
    500,
  );
});

export default app;
export type ApiRoutes = typeof routes;
