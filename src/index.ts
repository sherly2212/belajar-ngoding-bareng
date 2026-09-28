import { Elysia } from "elysia";
import { config } from "./config";
import { apiRoutes } from "./routes";
import { healthRoutes } from "./routes/health";
import { usersRoute } from "./routes/users-route";

const app = new Elysia()
  .use(apiRoutes)
  .use(healthRoutes)
  .use(usersRoute)
  .listen(config.port);

console.log(
  `🚀 Server is running at http://${app.server?.hostname}:${app.server?.port}`
);

export default app;
