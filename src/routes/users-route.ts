import { Elysia, t } from "elysia";
import {
  changePassword,
  deleteAccount,
  forgotPassword,
  getCurrentUser,
  loginUser,
  logoutUser,
  registerUser,
  resetPassword,
  updateProfile,
} from "../services/users-service";

// Aturan password dipakai bersama: daftar, reset, dan ganti password
const passwordSchema = t.String({
  minLength: 8,
  maxLength: 72,
  pattern: "^(?=.*[A-Za-z])(?=.*\\d).+$",
  error: "Password 8-72 karakter dan harus mengandung huruf dan angka",
});

// Mengambil token dari header Authorization, atau melempar 401
function getToken(headers: Record<string, string | undefined>) {
  const authorization = headers["authorization"];
  if (!authorization || !authorization.startsWith("Bearer ")) {
    const error = new Error("Unauthorized");
    (error as any).status = 401;
    throw error;
  }
  return authorization.slice(7);
}

export const usersRoute = new Elysia({ prefix: "/api/users" })
  .post(
    "/",
    async ({ body, set }) => {
      try {
        const result = await registerUser(body);
        return result;
      } catch (error: any) {
        set.status = error.status || 500;
        return { error: error.status ? error.message : "Internal server error" };
      }
    },
    {
      body: t.Object({
        name: t.String({ minLength: 3, maxLength: 255 }),
        email: t.String({ format: "email", maxLength: 255 }),
        password: passwordSchema,
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
        email: t.String({ minLength: 1, maxLength: 255 }),
        password: t.String({ minLength: 1, maxLength: 255 }),
      }),
    }
  )
  .post(
    "/forgot-password",
    async ({ body, set }) => {
      try {
        const result = await forgotPassword(body.email);
        return result;
      } catch (error: any) {
        set.status = error.status || 500;
        return { error: error.status ? error.message : "Internal server error" };
      }
    },
    {
      body: t.Object({
        email: t.String({ format: "email", maxLength: 255 }),
      }),
    }
  )
  .post(
    "/reset-password",
    async ({ body, set }) => {
      try {
        const result = await resetPassword(
          body.email,
          body.code,
          body.newPassword
        );
        return result;
      } catch (error: any) {
        set.status = error.status || 500;
        return { error: error.status ? error.message : "Internal server error" };
      }
    },
    {
      body: t.Object({
        email: t.String({ format: "email", maxLength: 255 }),
        code: t.String({ pattern: "^\\d{6}$", error: "Kode harus 6 angka" }),
        newPassword: passwordSchema,
      }),
    }
  )
  .get("/current", async ({ headers, set }) => {
    try {
      const token = getToken(headers);
      const result = await getCurrentUser(token);
      return result;
    } catch (error: any) {
      set.status = error.status || 500;
      return { error: error.status ? error.message : "Internal server error" };
    }
  })
  .patch(
    "/current",
    async ({ headers, body, set }) => {
      try {
        const token = getToken(headers);
        const result = await updateProfile(token, body.name);
        return result;
      } catch (error: any) {
        set.status = error.status || 500;
        return { error: error.status ? error.message : "Internal server error" };
      }
    },
    {
      body: t.Object({
        name: t.String({ minLength: 3, maxLength: 255 }),
      }),
    }
  )
  .post(
    "/change-password",
    async ({ headers, body, set }) => {
      try {
        const token = getToken(headers);
        const result = await changePassword(
          token,
          body.oldPassword,
          body.newPassword
        );
        return result;
      } catch (error: any) {
        set.status = error.status || 500;
        return { error: error.status ? error.message : "Internal server error" };
      }
    },
    {
      body: t.Object({
        oldPassword: t.String({ minLength: 1, maxLength: 255 }),
        newPassword: passwordSchema,
      }),
    }
  )
  .post(
    "/delete-account",
    async ({ headers, body, set }) => {
      try {
        const token = getToken(headers);
        const result = await deleteAccount(token, body.password);
        return result;
      } catch (error: any) {
        set.status = error.status || 500;
        return { error: error.status ? error.message : "Internal server error" };
      }
    },
    {
      body: t.Object({
        password: t.String({ minLength: 1, maxLength: 255 }),
      }),
    }
  )
  .delete("/logout", async ({ headers, set }) => {
    try {
      const token = getToken(headers);
      const result = await logoutUser(token);
      return result;
    } catch (error: any) {
      set.status = error.status || 500;
      return { error: error.status ? error.message : "Internal server error" };
    }
  });