# API Get Current User

## Deskripsi

Buatkan API untuk mendapatkan data user yang sedang login berdasarkan token di header `Authorization`.

## Endpoint

```
GET /api/users/current
```

### Headers

| Header          | Contoh Nilai         | Keterangan                                      |
| --------------- | -------------------- | ----------------------------------------------- |
| `Authorization` | `Bearer <token>`     | Token yang didapat dari API login (`POST /api/users/login`) dan tersimpan di tabel `sessions` |

### Response Body (Success)

```json
{
  "data": {
    "id": 1,
    "name": "eko",
    "email": "eko@localhost",
    "created_at": "timestamp"
  }
}
```

> **PENTING:** Field `password` **tidak boleh** ikut dikembalikan di response.

### Response Body (Error — token tidak valid atau tidak ada)

```json
{
  "error": "Unauthorized"
}
```

HTTP Status: `401`

---

## Struktur Folder & File

Semua perubahan dilakukan di file yang **sudah ada**, jangan membuat file baru.

| Folder       | File                  | Keterangan                  |
| ------------ | --------------------- | --------------------------- |
| `src/routes` | `users-route.ts`      | Tambahkan endpoint GET baru |
| `src/services` | `users-service.ts`  | Tambahkan fungsi service baru |

---

## Tahapan Implementasi

### Tahap 1 — Tambahkan fungsi `getCurrentUser` di `src/services/users-service.ts`

File saat ini sudah memiliki fungsi `registerUser` dan `loginUser`. Tambahkan fungsi baru **di bawah** fungsi `loginUser`.

**Yang harus dilakukan:**

1. Buat fungsi `export async function getCurrentUser(token: string)`.
2. Di dalam fungsi:
   - Query tabel `sessions` untuk mencari session berdasarkan `token` yang diberikan.
     ```ts
     const foundSessions = await db
       .select()
       .from(sessions)
       .where(eq(sessions.token, token))
       .limit(1);
     ```
   - Jika session tidak ditemukan, throw error dengan message `"Unauthorized"` dan set `status = 401`:
     ```ts
     if (!foundSessions[0]) {
       const error = new Error("Unauthorized");
       (error as any).status = 401;
       throw error;
     }
     ```
   - Jika session ditemukan, ambil `userId` dari session, lalu query tabel `users` untuk mendapatkan data user. **Jangan select field `password`** — gunakan select spesifik:
     ```ts
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
     ```
   - Jika user tidak ditemukan (edge case), throw error yang sama (`"Unauthorized"`, status `401`).
   - Jika user ditemukan, kembalikan:
     ```ts
     return {
       data: foundUsers[0],
     };
     ```

**Import yang sudah ada dan bisa dipakai:** `eq` dari `drizzle-orm`, `db` dari `../db`, `sessions` dan `users` dari `../db/schema` — semua sudah di-import di file ini.

---

### Tahap 2 — Tambahkan endpoint `GET /api/users/current` di `src/routes/users-route.ts`

File saat ini sudah memiliki 2 endpoint: `POST /` (registrasi) dan `POST /login`. Tambahkan endpoint GET baru **setelah** `.post("/login", ...)` dengan cara method chaining.

**Yang harus dilakukan:**

1. Import `getCurrentUser` dari `../services/users-service`:
   ```ts
   import { getCurrentUser, loginUser, registerUser } from "../services/users-service";
   ```

2. Tambahkan endpoint baru di akhir chain (setelah `.post("/login", ...)`):
   ```ts
   .get(
     "/current",
     async ({ headers, set }) => {
       try {
         // Ambil header Authorization
         const authorization = headers["authorization"];

         // Validasi format "Bearer <token>"
         if (!authorization || !authorization.startsWith("Bearer ")) {
           set.status = 401;
           return { error: "Unauthorized" };
         }

         // Ekstrak token (hilangkan prefix "Bearer ")
         const token = authorization.slice(7);

         const result = await getCurrentUser(token);
         return result;
       } catch (error: any) {
         set.status = error.status || 500;
         return { error: error?.message || "Internal server error" };
       }
     }
   )
   ```

**Catatan:** Endpoint ini tidak memerlukan `body` validator karena menggunakan method GET dan hanya membaca dari header.

---

### Tahap 3 — Testing Manual

Setelah implementasi selesai, lakukan testing manual:

1. **Jalankan server:**
   ```bash
   bun run dev
   ```

2. **Registrasi user baru** (jika belum ada):
   ```bash
   curl -X POST http://localhost:3000/api/users \
     -H "Content-Type: application/json" \
     -d '{"name": "eko", "email": "eko@localhost", "password": "rahasia123"}'
   ```

3. **Login untuk mendapatkan token:**
   ```bash
   curl -X POST http://localhost:3000/api/users/login \
     -H "Content-Type: application/json" \
     -d '{"email": "eko@localhost", "password": "rahasia123"}'
   ```
   Catat token yang dikembalikan di field `data`.

4. **Test GET current user (success):**
   ```bash
   curl http://localhost:3000/api/users/current \
     -H "Authorization: Bearer <token-dari-langkah-3>"
   ```
   **Expected:** Status `200`, body berisi `data` dengan `id`, `name`, `email`, `created_at`. **Tidak ada field `password`.**

5. **Test GET current user (tanpa header Authorization):**
   ```bash
   curl http://localhost:3000/api/users/current
   ```
   **Expected:** Status `401`, body `{"error": "Unauthorized"}`.

6. **Test GET current user (token tidak valid):**
   ```bash
   curl http://localhost:3000/api/users/current \
     -H "Authorization: Bearer token-asal-asalan"
   ```
   **Expected:** Status `401`, body `{"error": "Unauthorized"}`.

---

## Checklist

- [ ] Fungsi `getCurrentUser(token)` ditambahkan di `src/services/users-service.ts`
- [ ] Password **tidak** ikut di-select dari database
- [ ] Token tidak valid → throw error `"Unauthorized"` dengan status `401`
- [ ] Endpoint `GET /api/users/current` ditambahkan di `src/routes/users-route.ts`
- [ ] Header `Authorization` diparsing dengan format `Bearer <token>`
- [ ] Tanpa header / format salah → langsung return `401`
- [ ] Testing: success case mengembalikan data user tanpa password
- [ ] Testing: error case mengembalikan `{"error": "Unauthorized"}` dengan status `401`
