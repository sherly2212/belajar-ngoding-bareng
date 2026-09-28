import { Elysia } from "elysia";

export const apiRoutes = new Elysia().get("/", () => {
  return {
    name: "belajar-ngoding-bareng",
    version: "1.0.0",
    description: "Backend API with Bun, ElysiaJS, Drizzle ORM & MySQL",
    status: "running",
  };
});
