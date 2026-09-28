import { Elysia } from "elysia";
import { poolConnection } from "../db";

export const healthRoutes = new Elysia({ prefix: "/health" }).get(
  "/",
  async ({ set }) => {
    try {
      await poolConnection.query("SELECT 1");
      return {
        status: "ok",
        timestamp: new Date().toISOString(),
        database: "connected",
      };
    } catch (error: any) {
      set.status = 503;
      return {
        status: "error",
        timestamp: new Date().toISOString(),
        database: "disconnected",
        message: error?.message || "Database connection failed",
      };
    }
  }
);
