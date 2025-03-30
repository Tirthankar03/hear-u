import { sql, type SQL } from "drizzle-orm";
import type { PgColumn } from "drizzle-orm/pg-core";

export function getISOFormatDateQuery(dateTimeColumn: PgColumn): SQL<string> {
  return sql<string>`to_char(${dateTimeColumn}, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')`;
}


export function formatDuration(seconds: number): string {
  // Handle negative durations by returning "00:00"
  if (seconds < 0) {
    return "00:00";
  }

  // Calculate hours, minutes, and remaining seconds
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secondsRemainder = Math.round(seconds % 60);

  // Convert to two-digit strings
  const minutesStr = minutes.toString().padStart(2, "0");
  const secondsStr = secondsRemainder.toString().padStart(2, "0");

  // If there are hours, include them in the format "HH:MM:SS"
  if (hours > 0) {
    const hoursStr = hours.toString().padStart(2, "0");
    return `${hoursStr}:${minutesStr}:${secondsStr}`;
  } else {
    // Otherwise, use "MM:SS" format
    return `${minutesStr}:${secondsStr}`;
  }
}