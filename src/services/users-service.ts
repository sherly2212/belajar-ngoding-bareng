import { randomInt } from "node:crypto";
import { and, eq, ne } from "drizzle-orm";
import { db } from "../db";
import { passwordResets, sessions, users } from "../db/schema";
import { sendResetCode } from "./email-service";

const PASSWORD_UMUM = [
  "12345678",
  "123456789",
  "password",
  "password1",
  "qwerty123",
  "abc12345",
  "admin123",
];

// Membuat error dengan status HTTP supaya route bisa membalas dengan benar
function httpError(message: string, status: number) {
  const error = new Error(message);
  (error as any).status = status;
  return error;
}

function cekPasswordUmum(password: string) {
  if (PASSWORD_UMUM.includes(password.toLowerCase())) {
    throw httpError("Password terlalu mudah ditebak", 400);
  }
}

function normalizeEmail(email: string) {
  return email.trim().toLowerCase();
}

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
 * Membersihkan nama dan email, menolak password yang terlalu umum,
 * mengecek apakah email sudah terdaftar, meng-hash password
 * menggunakan bcrypt, lalu menyimpan user baru ke database.
 *
 * @param input - Data registrasi: name, email, password
 * @returns Objek `{ data: "OK" }` jika berhasil
 * @throws Error dengan status 400 jika data tidak valid atau email sudah terdaftar
 */
export async function registerUser(input: RegisterUserInput) {
  const name = input.name.trim();
  const email = normalizeEmail(input.email);

  if (name.length < 3) {
    throw httpError("Nama minimal 3 karakter", 400);
  }
  cekPasswordUmum(input.password);

  const existingUser = await db
    .select({ id: users.id })
    .from(users)
    .where(eq(users.email, email))
    .limit(1);

  if (existingUser.length > 0) {
    throw httpError("Email sudah terdaftar", 400);
  }

  const hashedPassword = await Bun.password.hash(input.password, {
    algorithm: "bcrypt",
    cost: 10,
  });

  await db.insert(users).values({
    name,
    email,
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
  const email = normalizeEmail(input.email);

  const foundUsers = await db
    .select()
    .from(users)
    .where(eq(users.email, email))
    .limit(1);

  const user = foundUsers[0];

  const loginError = httpError("Email atau password salah", 400);

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
    throw httpError("Unauthorized", 401);
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
    throw httpError("Unauthorized", 401);
  }

  return {
    data: foundUsers[0],
  };
}

/**
 * Mengubah nama user yang sedang login.
 *
 * @param token - Token session user
 * @param newName - Nama baru (minimal 3 karakter setelah dirapikan)
 * @returns Objek `{ data: "OK" }` jika berhasil
 * @throws Error dengan status 400 jika nama tidak valid, 401 jika token tidak valid
 */
export async function updateProfile(token: string, newName: string) {
  const { data: current } = await getCurrentUser(token);

  const name = newName.trim();
  if (name.length < 3) {
    throw httpError("Nama minimal 3 karakter", 400);
  }

  await db.update(users).set({ name }).where(eq(users.id, current.id));

  return {
    data: "OK",
  };
}

/**
 * Mengganti password user yang sedang login.
 *
 * Password lama harus benar. Setelah berhasil, semua session lain
 * dihapus (perangkat lain harus login ulang), sedangkan session
 * yang sedang dipakai tetap hidup.
 *
 * @param token - Token session user
 * @param oldPassword - Password lama
 * @param newPassword - Password baru
 * @returns Objek `{ data: "OK" }` jika berhasil
 * @throws Error dengan status 400 jika password lama salah atau password baru tidak valid
 */
export async function changePassword(
  token: string,
  oldPassword: string,
  newPassword: string
) {
  const { data: current } = await getCurrentUser(token);

  const foundUsers = await db
    .select()
    .from(users)
    .where(eq(users.id, current.id))
    .limit(1);

  const user = foundUsers[0];
  if (!user) {
    throw httpError("Unauthorized", 401);
  }

  const isMatch = await Bun.password.verify(oldPassword, user.password);
  if (!isMatch) {
    throw httpError("Password lama salah", 400);
  }

  if (oldPassword === newPassword) {
    throw httpError("Password baru harus berbeda dari password lama", 400);
  }
  cekPasswordUmum(newPassword);

  const hashedPassword = await Bun.password.hash(newPassword, {
    algorithm: "bcrypt",
    cost: 10,
  });

  await db
    .update(users)
    .set({ password: hashedPassword })
    .where(eq(users.id, user.id));

  // keluarkan perangkat lain, session yang sedang dipakai tetap hidup
  await db
    .delete(sessions)
    .where(and(eq(sessions.userId, user.id), ne(sessions.token, token)));

  return {
    data: "OK",
  };
}

/**
 * Menghapus akun user yang sedang login beserta data terkaitnya.
 *
 * Meminta password sebagai konfirmasi. Kode reset dan semua session
 * dihapus lebih dulu, baru user-nya.
 *
 * @param token - Token session user
 * @param password - Password saat ini (konfirmasi)
 * @returns Objek `{ data: "OK" }` jika berhasil
 * @throws Error dengan status 400 jika password salah
 */
export async function deleteAccount(token: string, password: string) {
  const { data: current } = await getCurrentUser(token);

  const foundUsers = await db
    .select()
    .from(users)
    .where(eq(users.id, current.id))
    .limit(1);

  const user = foundUsers[0];
  if (!user) {
    throw httpError("Unauthorized", 401);
  }

  const isMatch = await Bun.password.verify(password, user.password);
  if (!isMatch) {
    throw httpError("Password salah", 400);
  }

  await db.delete(passwordResets).where(eq(passwordResets.userId, user.id));
  await db.delete(sessions).where(eq(sessions.userId, user.id));
  await db.delete(users).where(eq(users.id, user.id));

  return {
    data: "OK",
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
    throw httpError("Unauthorized", 401);
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
 * @param rawEmail - Email akun yang lupa password
 * @returns Objek `{ data: pesan }`
 */
export async function forgotPassword(rawEmail: string) {
  const email = normalizeEmail(rawEmail);

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
      // Di production, sebaiknya log error tapi jangan sampai user tahu ada error.
      // Di tahap belajar, boleh saja console.error.
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
 * harus login ulang. Semua kegagalan kode memakai pesan yang sama.
 *
 * @param rawEmail - Email akun
 * @param code - Kode 6 angka dari email
 * @param newPassword - Password baru
 * @returns Objek `{ data: "OK" }` jika berhasil
 * @throws Error dengan status 400 jika kode tidak valid atau kedaluwarsa
 */
export async function resetPassword(
  rawEmail: string,
  code: string,
  newPassword: string
) {
  const email = normalizeEmail(rawEmail);

  // dicek paling awal supaya kode tidak terbuang gara-gara password lemah
  cekPasswordUmum(newPassword);

  const invalidError = httpError("Kode tidak valid atau sudah kedaluwarsa", 400);

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