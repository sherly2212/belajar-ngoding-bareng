import { afterAll, beforeEach, describe, expect, test } from "bun:test";
import { eq } from "drizzle-orm";
import { db } from "../src/db";
import { sessions, users } from "../src/db/schema";
import {
    getCurrentUser,
    loginUser,
    logoutUser,
    registerUser,
} from "../src/services/users-service";

const TEST_EMAIL = "test-uji@example.com";
const TEST_PASSWORD = "rahasia123";

// Fungsi ini membersihkan data tes sebelum setiap skenario,
// supaya tidak bentrok "email sudah terdaftar" tiap kali test diulang
async function hapusDataTes() {
    const existingUsers = await db
        .select({ id: users.id })
        .from(users)
        .where(eq(users.email, TEST_EMAIL));

    for (const user of existingUsers) {
        await db.delete(sessions).where(eq(sessions.userId, user.id));
    }

    await db.delete(users).where(eq(users.email, TEST_EMAIL));
}

describe("registerUser", () => {
    beforeEach(async () => {
        await hapusDataTes();
    });

    test("registrasi berhasil dengan data valid", async () => {
        const result = await registerUser({
            name: "User Tes",
            email: TEST_EMAIL,
            password: TEST_PASSWORD,
        });

        expect(result).toEqual({ data: "OK" });
    });

    test("registrasi gagal jika email sudah terdaftar", async () => {
        await registerUser({
            name: "User Tes",
            email: TEST_EMAIL,
            password: TEST_PASSWORD,
        });

        try {
            await registerUser({
                name: "User Tes Lain",
                email: TEST_EMAIL,
                password: TEST_PASSWORD,
            });
            expect(true).toBe(false); // seharusnya tidak sampai sini
        } catch (error: any) {
            expect(error.message).toBe("Email sudah terdaftar");
            expect(error.status).toBe(400);
        }
    });
});

describe("loginUser", () => {
    beforeEach(async () => {
        await hapusDataTes();
        await registerUser({
            name: "User Tes",
            email: TEST_EMAIL,
            password: TEST_PASSWORD,
        });
    });

    test("login berhasil dengan email dan password benar", async () => {
        const result = await loginUser({
            email: TEST_EMAIL,
            password: TEST_PASSWORD,
        });

        expect(typeof result.data).toBe("string");
    });

    test("login gagal jika password salah", async () => {
        try {
            await loginUser({
                email: TEST_EMAIL,
                password: "passwordsalah",
            });
            expect(true).toBe(false);
        } catch (error: any) {
            expect(error.message).toBe("Email atau password salah");
            expect(error.status).toBe(400);
        }
    });

    test("login gagal jika email tidak terdaftar", async () => {
        try {
            await loginUser({
                email: "tidakada@example.com",
                password: TEST_PASSWORD,
            });
            expect(true).toBe(false);
        } catch (error: any) {
            expect(error.message).toBe("Email atau password salah");
        }
    });
});

describe("getCurrentUser", () => {
    beforeEach(async () => {
        await hapusDataTes();
        await registerUser({
            name: "User Tes",
            email: TEST_EMAIL,
            password: TEST_PASSWORD,
        });
    });

    test("berhasil mendapatkan data user dengan token valid", async () => {
        const loginResult = await loginUser({
            email: TEST_EMAIL,
            password: TEST_PASSWORD,
        });

        const result = await getCurrentUser(loginResult.data);

        expect(result.data.name).toBe("User Tes");
        expect(result.data.email).toBe(TEST_EMAIL);
        expect((result.data as any).password).toBeUndefined();
    });

    test("gagal jika token tidak valid", async () => {
        try {
            await getCurrentUser("token-ngasal-tidak-ada");
            expect(true).toBe(false);
        } catch (error: any) {
            expect(error.message).toBe("Unauthorized");
            expect(error.status).toBe(401);
        }
    });
});

describe("logoutUser", () => {
    beforeEach(async () => {
        await hapusDataTes();
        await registerUser({
            name: "User Tes",
            email: TEST_EMAIL,
            password: TEST_PASSWORD,
        });
    });

    test("berhasil logout dengan token valid", async () => {
        const loginResult = await loginUser({
            email: TEST_EMAIL,
            password: TEST_PASSWORD,
        });

        const result = await logoutUser(loginResult.data);

        expect(result).toEqual({ data: "OK" });
    });

    test("token tidak bisa dipakai lagi setelah logout", async () => {
        const loginResult = await loginUser({
            email: TEST_EMAIL,
            password: TEST_PASSWORD,
        });

        await logoutUser(loginResult.data);

        try {
            await getCurrentUser(loginResult.data);
            expect(true).toBe(false);
        } catch (error: any) {
            expect(error.message).toBe("Unauthorized");
            expect(error.status).toBe(401);
        }
    });

    test("gagal jika token tidak valid", async () => {
        try {
            await logoutUser("token-ngasal-tidak-ada");
            expect(true).toBe(false);
        } catch (error: any) {
            expect(error.message).toBe("Unauthorized");
            expect(error.status).toBe(401);
        }
    });
});

afterAll(async () => {
    await hapusDataTes();
});