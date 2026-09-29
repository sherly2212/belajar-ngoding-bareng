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

/**
 * Mendaftarkan user baru ke dalam sistem.
 *
 * Mengecek apakah email sudah terdaftar, meng-hash password
 * menggunakan bcrypt, lalu menyimpan user baru ke database.
 *
 * @param input - Data registrasi: name, email, password
 * @returns Objek `{ data: "OK" }` jika berhasil
 * @throws Error dengan status 400 jika email sudah terdaftar
 */
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

/**
 * Melakukan login user dan membuat session baru.
 *
 * Mencocokkan email dan password (dengan bcrypt verify), lalu
 * membuat token UUID baru yang disimpan di tabel sessions.
 * Pesan error dibuat sama untuk email tidak ada maupun password
 * salah, agar tidak membocorkan email mana yang terdaftar.
 *
 * @param input - Data login: email, password
 * @returns Objek `{ data: token }` berisi token session
 * @throws Error dengan status 400 jika email/password salah
 */
export async function loginUser(input: LoginUserInput) {
  const foundUsers = await db
    .select()
    .from(users)
    .where(eq(users.email, input.email))
    .limit(1);

  const user = foundUsers[0];

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

/**
 * Mengambil data user yang sedang login berdasarkan token session.
 *
 * Password tidak disertakan dalam hasil, hanya id, name, email,
 * dan created_at.
 *
 * @param token - Token UUID dari tabel sessions
 * @returns Objek `{ data: user }` berisi data user (tanpa password)
 * @throws Error dengan status 401 jika token tidak valid
 */
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

/**
 * Melakukan logout user dengan menghapus session/token dari database.
 *
 * Setelah dipanggil, token yang sama tidak bisa dipakai lagi
 * untuk mengakses endpoint yang memerlukan autentikasi.
 *
 * @param token - Token UUID dari tabel sessions yang akan dihapus
 * @returns Objek `{ data: "OK" }` jika berhasil
 * @throws Error dengan status 401 jika token tidak valid
 */
export async function logoutUser(token: string) {
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

  await db.delete(sessions).where(eq(sessions.token, token));

  return {
    data: "OK",
  };
}