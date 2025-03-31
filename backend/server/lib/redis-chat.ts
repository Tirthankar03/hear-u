// lib/redis-chat.ts
import { Redis } from "@upstash/redis";

export const redisChat = new Redis({
  url: process.env["UPSTASH_REDIS_CHAT_URL"],
  token: process.env["UPSTASH_REDIS_CHAT_TOKEN"]
});