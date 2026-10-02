import { Elysia } from "elysia";
import { cors } from "@elysiajs/cors";
import { swagger } from "@elysiajs/swagger";
import { config } from "./config";
import { apiRoutes } from "./routes";
import { healthRoutes } from "./routes/health";
import { usersRoute } from "./routes/users-route";
import { rekapRoute } from "./routes/rekap-route"; // <- BARU

const app = new Elysia()
  .use(cors())
  .use(swagger())
  .use(apiRoutes)
  .use(healthRoutes)
  .use(usersRoute)
  .use(rekapRoute) // <- BARU
  .listen(config.port);

console.log(
  `🚀 Server is running at http://${app.server?.hostname}:${app.server?.port}`
);

console.log(
  `📚 Swagger docs available at http://${app.server?.hostname}:${app.server?.port}/swagger`
);

export default app;