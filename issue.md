# Issue: Implementasi Fitur Login User & Tabel Sessions

## 1. Deskripsi & Tujuan
Mengimplementasikan sistem autentikasi login pengguna dan pencatatan sesi login (*session management*). Fitur ini mencakup pembuatan tabel `sessions` baru di database MySQL untuk menyimpan token UUID pengguna yang berhasil login, penambahan logika verifikasi kredensial di service layer, serta penyediaan endpoint login pada rute yang sudah ada.

Dokumen ini disusun sebagai panduan langkah demi langkah (*step-by-step implementation guide*) tingkat tinggi bagi junior programmer atau AI implementor.

---

## 2. Spesifikasi Database (Tabel `sessions`)

Buat definisi skema tabel `sessions` baru di dalam `src/db/schema.ts` dengan spesifikasi sebagai berikut:

| Kolom | Tipe Data | Keterangan |
| :--- | :--- | :--- |
| `id` | `INTEGER` | Primary Key, Auto Increment |
| `token` | `VARCHAR(255)` | Not Null (Berisi UUID sebagai token sesi login) |
| `user_id` | `INTEGER` | Not Null, Foreign Key mengarah ke `users.id` |
| `created_at` | `TIMESTAMP` | Not Null, Default `CURRENT_TIMESTAMP` |

> **Catatan Teknis**: 
> - Di Drizzle ORM, foreign key dapat didefinisikan menggunakan `.references(() => users.id)`.
> - Untuk token UUID, gunakan fungsi standar bawaan runtime: `crypto.randomUUID()`.

---

## 3. Spesifikasi API Endpoint

### **POST /api/users/login**
Memverifikasi identitas pengguna berdasarkan email & password, lalu menerbitkan session token jika kredensial valid.

#### **Request Body (`application/json`)**:
```json
{
  "email": "sherly.tes@example.com",
  "password": "rahasia123"
}
```

#### **Validasi Input**:
- `email`: String, wajib diisi (*required*).
- `password`: String, wajib diisi (*required*).

#### **Response Body**:

- **Sukses (Status Code `200`)**:
  ```json
  {
    "data": "550e8400-e29b-41d4-a716-446655440000"
  }
  ```
  *(Nilai `data` adalah string token UUID yang baru dibuat dan disimpan di tabel `sessions`)*

- **Gagal - Kredensial Salah (Status Code `400` atau `401`)**:
  ```json
  {
    "error": "Email atau password salah"
  }
  ```

> **Catatan Keamanan**: Pesan error untuk email yang tidak ditemukan maupun password yang tidak cocok harus **sama persis**: `"Email atau password salah"` guna mencegah teknik *user enumeration*.

---

## 4. Konvensi Struktur Folder & File

Pekerjaan ini **TIDAK MEMBUAT FILE BARU** untuk layer service dan route. Gunakan dan modifikasi file yang sudah ada:

- **Database Schema**: `src/db/schema.ts` (tambahkan tabel `sessions` di file ini).
- **Service Layer**: `src/services/users-service.ts` (tambahkan fungsi `loginUser` di file ini).
- **Route Layer**: `src/routes/users-route.ts` (tambahkan sub-endpoint `POST /login` di file ini).

```text
src/
├── db/
│   ├── index.ts
│   └── schema.ts           # [MODIFIKASI] Tambahkan tabel sessions
├── routes/
│   └── users-route.ts      # [MODIFIKASI] Tambahkan handler POST /login
├── services/
│   └── users-service.ts    # [MODIFIKASI] Tambahkan fungsi bisnis loginUser
└── index.ts                # (Sudah me-mount users-route, tidak perlu diubah)
```

---

## 5. Tahapan Implementasi

### **Tahap 1: Definisi Tabel `sessions` & Sinkronisasi Database**
1. Buka file `src/db/schema.ts`.
2. Ekspor definisi tabel baru `sessions` dengan kolom:
   - `id`: integer auto increment primary key.
   - `token`: varchar 255 not null.
   - `userId`: `int("user_id").notNull().references(() => users.id)`.
   - `createdAt`: `timestamp("created_at").defaultNow().notNull()`.
3. Jalankan sinkronisasi database:
   ```bash
   bun run db:push
   # dan/atau bun run db:generate untuk mencatat file migrasi
   ```
4. Pastikan tabel `sessions` berhasil terbuat di MySQL dengan relasi foreign key ke tabel `users`.

### **Tahap 2: Menambahkan Logika Login di `src/services/users-service.ts`**
1. Buka file `src/services/users-service.ts`.
2. Import tabel `sessions` dari `../db/schema`.
3. Buat interface/type input:
   ```ts
   export interface LoginUserInput {
     email: string;
     password: string;
   }
   ```
4. Buat fungsi baru, misalnya `export async function loginUser(input: LoginUserInput)`:
   - Query user dari tabel `users` berdasarkan `email`.
   - Jika data user tidak ditemukan: lempar error `"Email atau password salah"`.
   - Verifikasi password input terhadap hash password di database menggunakan native Bun API:
     ```ts
     const isMatch = await Bun.password.verify(input.password, user.password);
     ```
   - Jika `isMatch` bernilai `false`: lempar error `"Email atau password salah"`.
   - Jika cocok:
     - Generate token UUID unik menggunakan `crypto.randomUUID()`.
     - Simpan record session baru ke tabel `sessions` (`token`, `userId: user.id`).
     - Kembalikan token ke pemanggil: `{ data: token }`.

### **Tahap 3: Menambahkan Route Login di `src/routes/users-route.ts`**
1. Buka file `src/routes/users-route.ts`.
2. Import fungsi `loginUser` dari `../services/users-service`.
3. Pada instance `usersRoute` (yang sudah memiliki prefix `/api/users`), tambahkan endpoint baru `.post("/login", ...)`:
   - Definisikan validasi body menggunakan skema Elysia:
     ```ts
     body: t.Object({
       email: t.String({ minLength: 1 }),
       password: t.String({ minLength: 1 }),
     })
     ```
   - Di dalam handler:
     - Panggil `await loginUser(body)`.
     - Kembalikan hasil sukses `{ data: token }` (HTTP 200).
     - Tangkap error: jika error adalah `"Email atau password salah"`, set status HTTP `400` (atau `401`) dan kembalikan `{ error: "Email atau password salah" }`.

### **Tahap 4: Pengujian & Validasi Fitur**
1. Jalankan server:
   ```bash
   bun run dev
   ```
2. **Skenario 1 - Login Sukses (Kredensial Valid)**:
   - Kirim `POST /api/users/login` dengan email dan password user yang sudah terdaftar.
   - Verifikasi respons berstatus HTTP 200 dan format `{ "data": "<token_uuid>" }`.
   - Periksa tabel `sessions` di MySQL, pastikan baris sesi baru tersimpan dengan `user_id` yang sesuai dan `token` yang cocok.
3. **Skenario 2 - Login Gagal (Email Tidak Terdaftar)**:
   - Kirim `POST /api/users/login` dengan email yang belum pernah terdaftar.
   - Verifikasi respons berstatus HTTP 400/401 dengan body `{ "error": "Email atau password salah" }`.
4. **Skenario 3 - Login Gagal (Password Salah)**:
   - Kirim `POST /api/users/login` dengan email valid tetapi password salah.
   - Verifikasi respons berstatus HTTP 400/401 dengan body `{ "error": "Email atau password salah" }`.

---

## 6. Kriteria Keberhasilan (Acceptance Criteria)
- [ ] Tabel `sessions` berhasil didefinisikan di `src/db/schema.ts` dan tersinkronisasi ke MySQL lengkap dengan relasi FK ke `users.id`.
- [ ] Fungsi `loginUser` ditambahkan ke `src/services/users-service.ts` tanpa membuat file baru.
- [ ] Endpoint `POST /api/users/login` ditambahkan ke `src/routes/users-route.ts` tanpa membuat file baru.
- [ ] Verifikasi password dilakukan menggunakan `Bun.password.verify`.
- [ ] Token sesi dibuat dengan `crypto.randomUUID()` dan tersimpan di database.
- [ ] Login sukses mengembalikan `{ "data": "<token>" }` dengan status HTTP 200.
- [ ] Login gagal (baik email tidak ditemukan maupun password salah) mengembalikan `{ "error": "Email atau password salah" }`.
- [ ] Kode bebas dari error tipe TypeScript.
