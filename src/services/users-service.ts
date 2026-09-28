import { eq } from "drizzle-orm";
import { db } from "../db";
import { sessions, users } from "../db/schema";

export interface RegisterUserInput {
  name: string;
  email: string;
  password: string;
}

export interface LoginUserInput {
  email: string;
  password: string;
}

export async function registerUser(input: RegisterUserInput) {
  const existingUser = await db
    .select({ id: users.id })
    .from(users)
    .where(eq(users.email, input.email))
    .limit(1);

  if (existingUser.length > 0) {
    const error = new Error("Email sudah terdaftar");
    (error as any).status = 400;
    throw error;
  }

  const hashedPassword = await Bun.password.hash(input.password, {
    algorithm: "bcrypt",
    cost: 10,
  });

  await db.insert(users).values({
    name: input.name,
    email: input.email,
    password: hashedPassword,
  });

  return {
    data: "OK",
  };
}

export async function loginUser(input: LoginUserInput) {
  const foundUsers = await db
    .select()
    .from(users)
    .where(eq(users.email, input.email))
    .limit(1);

  const user = foundUsers[0];

  // Pesan error dibuat sama untuk email tidak ada dan password salah
  const loginError = new Error("Email atau password salah");
  (loginError as any).status = 400;

  if (!user) {
    throw loginError;
  }

  const isMatch = await Bun.password.verify(input.password, user.password);

  if (!isMatch) {
    throw loginError;
  }

  const token = crypto.randomUUID();

  await db.insert(sessions).values({
    token,
    userId: user.id,
  });

  return {
    data: token,
  };
}

export async function getCurrentUser(token: string) {
  const foundSessions = await db
    .select()
    .from(sessions)
    .where(eq(sessions.token, token))
    .limit(1);

  if (!foundSessions[0]) {
    const error = new Error("Unauthorized");
    (error as any).status = 401;
    throw error;
  }

  const foundUsers = await db
    .select({
      id: users.id,
      name: users.name,
      email: users.email,
      created_at: users.createdAt,
    })
    .from(users)
    .where(eq(users.id, foundSessions[0].userId))
    .limit(1);

  if (!foundUsers[0]) {
    const error = new Error("Unauthorized");
    (error as any).status = 401;
    throw error;
  }

  return {
    data: foundUsers[0],
  };
}