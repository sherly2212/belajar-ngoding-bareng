import { randomInt } from "node:crypto";
import { eq } from "drizzle-orm";
import { db } from "../db";
import { passwordResets, sessions, users } from "../db/schema";
import { sendResetCode } from "./email-service";

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

/**
 * Meminta kode reset password.
 *
 * Jika email terdaftar, dibuat kode 6 angka yang disimpan dalam
 * bentuk hash dengan masa berlaku 15 menit. Respons selalu sama
 * untuk email terdaftar maupun tidak, agar tidak membocorkan
 * email mana yang punya akun.
 *
 * @param email - Email akun yang lupa password
 * @returns Objek `{ data: pesan }`
 */
export async function forgotPassword(email: string) {
  const foundUsers = await db
    .select({ id: users.id })
    .from(users)
    .where(eq(users.email, email))
    .limit(1);

  const user = foundUsers[0];

  if (user) {
    const code = String(randomInt(100000, 1000000));
    const codeHash = await Bun.password.hash(code, {
      algorithm: "bcrypt",
      cost: 10,
    });
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

    // hanya satu kode aktif per user
    await db.delete(passwordResets).where(eq(passwordResets.userId, user.id));

    await db.insert(passwordResets).values({
      userId: user.id,
      codeHash,
      expiresAt,
    });
    try {
      await sendResetCode(email, code);
    } catch (err) {
      console.error("Gagal kirim email:", err);
    }
  }

  return {
    data: "Jika email terdaftar, kode reset sudah dikirim",
  };
}


/**
 * Mengganti password memakai kode reset.
 *
 * Kode harus cocok, belum kedaluwarsa, dan belum terlalu sering
 * salah dimasukkan (maksimal 5 kali). Setelah berhasil, kode
 * dihapus dan semua session user dihapus agar perangkat lain
 * harus login ulang. Semua kegagalan memakai pesan yang sama.
 *
 * @param email - Email akun
 * @param code - Kode 6 angka dari email
 * @param newPassword - Password baru
 * @returns Objek `{ data: "OK" }` jika berhasil
 * @throws Error dengan status 400 jika kode tidak valid atau kedaluwarsa
 */
export async function resetPassword(
  email: string,
  code: string,
  newPassword: string
) {
  const invalidError = new Error("Kode tidak valid atau sudah kedaluwarsa");
  (invalidError as any).status = 400;

  const foundUsers = await db
    .select({ id: users.id })
    .from(users)
    .where(eq(users.email, email))
    .limit(1);

  const user = foundUsers[0];
  if (!user) {
    throw invalidError;
  }

  const foundResets = await db
    .select()
    .from(passwordResets)
    .where(eq(passwordResets.userId, user.id))
    .limit(1);

  const reset = foundResets[0];
  if (!reset) {
    throw invalidError;
  }

  // kedaluwarsa atau sudah terlalu sering salah: hapus kodenya
  if (reset.expiresAt.getTime() < Date.now() || reset.attempts >= 5) {
    await db.delete(passwordResets).where(eq(passwordResets.id, reset.id));
    throw invalidError;
  }

  const isMatch = await Bun.password.verify(code, reset.codeHash);
  if (!isMatch) {
    await db
      .update(passwordResets)
      .set({ attempts: reset.attempts + 1 })
      .where(eq(passwordResets.id, reset.id));
    throw invalidError;
  }

  const hashedPassword = await Bun.password.hash(newPassword, {
    algorithm: "bcrypt",
    cost: 10,
  });

  await db
    .update(users)
    .set({ password: hashedPassword })
    .where(eq(users.id, user.id));

  // kode hanya bisa dipakai sekali
  await db.delete(passwordResets).where(eq(passwordResets.userId, user.id));

  // paksa semua perangkat login ulang
  await db.delete(sessions).where(eq(sessions.userId, user.id));

  return {
    data: "OK",
  };
}