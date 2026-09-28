# API Logout User

## Deskripsi

Buatkan API untuk logout user yang sedang login. Saat logout berhasil, data session dengan token tersebut harus **dihapus dari tabel `sessions`** di database.

## Endpoint

```
DELETE /api/users/logout
```

### Headers

| Header          | Contoh Nilai     | Keterangan                                                                                    |
| --------------- | ---------------- | --------------------------------------------------------------------------------------------- |
| `Authorization` | `Bearer <token>` | Token yang didapat dari API login (`POST /api/users/login`) dan tersimpan di tabel `sessions` |

### Response Body (Success)

```json
{
  "data": "OK"
}
```

HTTP Status: `200`

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

| Folder         | File              | Keterangan                       |
| -------------- | ----------------- | -------------------------------- |
| `src/routes`   | `users-route.ts`  | Tambahkan endpoint DELETE baru   |
| `src/services` | `users-service.ts`| Tambahkan fungsi service baru    |

---

## Konteks Kode yang Sudah Ada

Sebelum mulai, pahami struktur file yang sudah ada:

### `src/db/schema.ts`

Berisi definisi tabel database. Tabel yang relevan untuk fitur ini:

```ts
export const sessions = mysqlTable("sessions", {
  id: int().primaryKey().autoincrement(),
  token: varchar({ length: 255 }).notNull(),
  userId: int("user_id").notNull().references(() => users.id),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});
```

### `src/services/users-service.ts`

File ini sudah memiliki 3 fungsi:
- `registerUser(input)` — registrasi user baru
- `loginUser(input)` — login dan buat session
- `getCurrentUser(token)` — ambil data user dari token

Semua fungsi sudah menggunakan `db`, `eq` dari drizzle-orm, dan import `sessions` & `users` dari schema — **tidak perlu import tambahan**.

### `src/routes/users-route.ts`

File ini sudah memiliki 3 endpoint yang di-chain dalam satu `usersRoute`:
- `POST /` — registrasi
- `POST /login` — login
- `GET /current` — get current user

---

## Tahapan Implementasi

### Tahap 1 — Tambahkan fungsi `logoutUser` di `src/services/users-service.ts`

Tambahkan fungsi baru **di bawah** fungsi `getCurrentUser` yang sudah ada (di bagian paling bawah file).

**Yang harus dilakukan:**

1. Buat fungsi `export async function logoutUser(token: string)`.

2. Di dalam fungsi, pertama cek apakah token ada di tabel `sessions`:
   ```ts
   const foundSessions = await db
     .select()
     .from(sessions)
     .where(eq(sessions.token, token))
     .limit(1);
   ```

3. Jika session tidak ditemukan, throw error `"Unauthorized"` dengan status `401`:
   ```ts
   if (!foundSessions[0]) {
     const error = new Error("Unauthorized");
     (error as any).status = 401;
     throw error;
   }
   ```

4. Jika session ditemukan, **hapus** session tersebut dari tabel `sessions`:
   ```ts
   await db.delete(sessions).where(eq(sessions.token, token));
   ```

5. Return response sukses:
   ```ts
   return {
     data: "OK",
   };
   ```

**Import yang sudah ada dan bisa dipakai:** `eq` dari `drizzle-orm`, `db` dari `../db`, `sessions` dari `../db/schema` — semua sudah di-import, tidak perlu menambahkan import baru.

---

### Tahap 2 — Tambahkan endpoint `DELETE /api/users/logout` di `src/routes/users-route.ts`

Tambahkan endpoint baru **setelah** `.get("/current", ...)` dengan cara method chaining (sambung di akhir chain yang sudah ada).

**Yang harus dilakukan:**

1. Tambahkan `logoutUser` ke import dari `../services/users-service`:
   ```ts
   import { getCurrentUser, loginUser, logoutUser, registerUser } from "../services/users-service";
   ```

2. Tambahkan endpoint DELETE baru di akhir chain `usersRoute`:
   ```ts
   .delete("/logout", async ({ headers, set }) => {
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

       const result = await logoutUser(token);
       return result;
     } catch (error: any) {
       set.status = error.status || 500;
       return { error: error?.message || "Internal server error" };
     }
   });
   ```

   > **Catatan:** Pastikan endpoint ini menggantikan titik koma (`;`) di akhir `.get("/current", ...)`. Method chaining harus menyambung tanpa titik koma di tengah-tengah, dan titik koma hanya ada di endpoint paling akhir.

**Catatan:** Endpoint ini tidak memerlukan `body` validator karena method DELETE dan hanya membaca dari header.

---

### Tahap 3 — Testing Manual

Setelah implementasi selesai, lakukan testing manual dengan langkah berikut:

1. **Jalankan server:**
   ```bash
   bun run dev
   ```

2. **Login untuk mendapatkan token** (gunakan user yang sudah ada, atau registrasi dulu jika belum ada):
   ```bash
   curl -X POST http://localhost:3000/api/users/login \
     -H "Content-Type: application/json" \
     -d '{"email": "eko@localhost", "password": "rahasia123"}'
   ```
   Catat token yang dikembalikan di field `data`.

3. **Verifikasi token ada di database** (opsional, cek via MySQL client):
   ```sql
   SELECT * FROM sessions WHERE token = '<token>';
   ```

4. **Test DELETE logout (success):**
   ```bash
   curl -X DELETE http://localhost:3000/api/users/logout \
     -H "Authorization: Bearer <token-dari-langkah-2>"
   ```
   **Expected:** Status `200`, body `{"data": "OK"}`.

5. **Verifikasi token sudah terhapus dari database:**
   ```sql
   SELECT * FROM sessions WHERE token = '<token>';
   ```
   **Expected:** Tidak ada hasil (0 rows).

6. **Test menggunakan token yang sudah di-logout (token tidak valid lagi):**
   ```bash
   curl -X DELETE http://localhost:3000/api/users/logout \
     -H "Authorization: Bearer <token-yang-sama>"
   ```
   **Expected:** Status `401`, body `{"error": "Unauthorized"}`.

7. **Test tanpa header Authorization:**
   ```bash
   curl -X DELETE http://localhost:3000/api/users/logout
   ```
   **Expected:** Status `401`, body `{"error": "Unauthorized"}`.

8. **Test dengan token asal-asalan:**
   ```bash
   curl -X DELETE http://localhost:3000/api/users/logout \
     -H "Authorization: Bearer token-tidak-valid"
   ```
   **Expected:** Status `401`, body `{"error": "Unauthorized"}`.

---

## Checklist

- [ ] Fungsi `logoutUser(token)` ditambahkan di `src/services/users-service.ts`
- [ ] Session dengan token tersebut dihapus dari tabel `sessions` saat logout berhasil
- [ ] Token tidak valid → throw error `"Unauthorized"` dengan status `401`
- [ ] Endpoint `DELETE /api/users/logout` ditambahkan di `src/routes/users-route.ts`
- [ ] Import `logoutUser` ditambahkan di `users-route.ts`
- [ ] Header `Authorization` diparsing dengan format `Bearer <token>`
- [ ] Tanpa header / format salah → langsung return `401`
- [ ] Testing: success case mengembalikan `{"data": "OK"}` dan session terhapus dari DB
- [ ] Testing: token yang sudah di-logout tidak bisa dipakai lagi (return `401`)
- [ ] Testing: tanpa header → return `401`
