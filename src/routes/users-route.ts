import { Elysia, t } from "elysia";
import { getCurrentUser, loginUser, logoutUser, registerUser } from "../services/users-service";

export const usersRoute = new Elysia({ prefix: "/api/users" })
  .post(
    "/",
    async ({ body, set }) => {
      try {
        const result = await registerUser(body);
        return result;
      } catch (error: any) {
        if (error.message === "Email sudah terdaftar") {
          set.status = 400;
          return { error: "Email sudah terdaftar" };
        }
        set.status = error.status || 500;
        return { error: error.status ? error.message : "Internal server error" };
      }
    },
    {
      body: t.Object({
        name: t.String({ minLength: 3, maxLength: 255 }),
        email: t.String({ format: "email", maxLength: 255 }),
        password: t.String({ minLength: 6, maxLength: 255 }),
      }),
    }
  )
  .post(
    "/login",
    async ({ body, set }) => {
      try {
        const result = await loginUser(body);
        return result;
      } catch (error: any) {
        set.status = error.status || 500;
        return { error: error.status ? error.message : "Internal server error" };
      }
    },
    {
      body: t.Object({
        email: t.String({ minLength: 1 }),
        password: t.String({ minLength: 1 }),
      }),
    }
  )
  .get("/current", async ({ headers, set }) => {
    try {
      const authorization = headers["authorization"];

      if (!authorization || !authorization.startsWith("Bearer ")) {
        set.status = 401;
        return { error: "Unauthorized" };
      }

      const token = authorization.slice(7);

      const result = await getCurrentUser(token);
      return result;
    } catch (error: any) {
      set.status = error.status || 500;
      return { error: error.status ? error.message : "Internal server error" };
    }
  })
  .delete("/logout", async ({ headers, set }) => {
    try {
      const authorization = headers["authorization"];

      if (!authorization || !authorization.startsWith("Bearer ")) {
        set.status = 401;
        return { error: "Unauthorized" };
      }

      const token = authorization.slice(7);

      const result = await logoutUser(token);
      return result;
    } catch (error: any) {
      set.status = error.status || 500;
      return { error: error.status ? error.message : "Internal server error" };
    }
  });