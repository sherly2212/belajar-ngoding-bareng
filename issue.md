# Issue: Implementasi Registrasi User Baru (Update Skema & API Endpoint)

## 1. Deskripsi & Tujuan
Mengimplementasikan fitur registrasi pengguna baru (*User Registration*). Pekerjaan ini mencakup penambahan kolom `password` pada tabel `users` yang sudah ada, pembuatan lapisan layanan (*service layer*) untuk logika bisnis dan hashing password menggunakan bcrypt, serta penyediaan endpoint HTTP menggunakan framework ElysiaJS.

Dokumen ini disusun sebagai panduan langkah demi langkah (*implementation guide*) tingkat tinggi bagi junior programmer atau model AI implementor.

---

## 2. Spesifikasi Database (Tabel `users`)

Perbarui definisi skema tabel `users` di Drizzle ORM dengan spesifikasi berikut:

| Kolom | Tipe Data | Keterangan |
| :--- | :--- | :--- |
| `id` | `INTEGER` | Primary Key, Auto Increment |
| `name` | `VARCHAR(255)` | Not Null |
| `email` | `VARCHAR(255)` | Not Null, Unique |
| `password` | `VARCHAR(255)` | Not Null (Hash bcrypt) |
| `created_at` | `TIMESTAMP` | Not Null, Default `CURRENT_TIMESTAMP` |

> **Catatan Keamanan**: Kolom `password` harus selalu menyimpan string hasil hash bcrypt, bukan plain text. Di runtime Bun, gunakan API bawaan `await Bun.password.hash(password, { algorithm: "bcrypt", cost: 10 })` atau library bcrypt yang kompatibel.

---

## 3. Spesifikasi API Endpoint

### **POST /api/users**
Mendaftarkan akun user baru ke dalam sistem.

#### **Request Body (`application/json`)**:
```json
{
  "name": "Sherly",
  "email": "sherly@localhost",
  "password": "rahasia"
}
```

#### **Validasi Input**:
- `name`: String, wajib diisi (*required*).
- `email`: String format email yang valid, wajib diisi (*required*).
- `password`: String, wajib diisi (*required*).

#### **Response Body**:

- **Sukses (Status Code `200` atau `201`)**:
  ```json
  {
    "data": "OK"
  }
  ```

- **Gagal - Email Sudah Terdaftar (Status Code `400`)**:
  ```json
  {
    "error": "Email sudah terdaftar"
  }
  ```

---

## 4. Konvensi Struktur Folder & File

Pemisahan tanggung jawab (*separation of concerns*) wajib diterapkan di dalam folder `src/`:
- `routes/`: Menangani routing HTTP, validasi skema request body, dan pengiriman response HTTP.
- `services/`: Menangani logika bisnis, pengecekan duplikasi data, hashing password, dan pemanggilan query database.

### Format Penamaan File:
- File rute: `src/routes/users-route.ts`
- File layanan bisnis: `src/services/users-service.ts`

```text
src/
├── config/
├── db/
│   ├── index.ts
│   └── schema.ts           # Perbarui kolom tabel users di sini
├── routes/
│   ├── health.ts
│   ├── index.ts
│   └── users-route.ts      # [BARU] Definisi endpoint POST /api/users
├── services/
│   └── users-service.ts    # [BARU] Logika bisnis pendaftaran & hashing
└── index.ts                # Mount usersRoute ke instance Elysia utama
```

---

## 5. Tahapan Implementasi

### **Tahap 1: Pembaruan Skema Database & Migrasi**
1. Buka file `src/db/schema.ts`.
2. Tambahkan kolom `password` bertipe `varchar({ length: 255 }).notNull()`.
3. Jalankan perintah migrasi atau sinkronisasi skema ke database MySQL:
   ```bash
   bun run db:push
   # atau bun run db:generate jika menggunakan migrasi terstruktur
   ```
4. Pastikan tabel `users` di MySQL sudah memuat kolom `password`.

### **Tahap 2: Pembuatan Service Layer (`src/services/users-service.ts`)**
1. Buat file baru `src/services/users-service.ts`.
2. Definisikan interface/type input registrasi (`name`, `email`, `password`).
3. Buat fungsi registrasi (misalnya `registerUser(payload)`):
   - Query database untuk mengecek apakah `email` sudah ada di tabel `users`.
   - Jika email sudah ada, lemparkan error atau kembalikan status kegagalan bahwa `"Email sudah terdaftar"`.
   - Lakukan hashing pada password mentah menggunakan bcrypt (gunakan `await Bun.password.hash(password, { algorithm: "bcrypt" })`).
   - Simpan data user baru (`name`, `email`, `password` yang sudah di-hash) ke database menggunakan Drizzle ORM.
   - Kembalikan hasil sukses.

### **Tahap 3: Pembuatan Route Layer (`src/routes/users-route.ts`)**
1. Buat file baru `src/routes/users-route.ts`.
2. Inisialisasi route plugin Elysia baru:
   - Path dasar: `/api/users` (atau sub-route di bawah `/users` dengan prefix `/api`).
   - Method: `POST /`.
3. Tambahkan validasi body menggunakan skema Elysia (`t.Object`).
4. Panggil fungsi dari `users-service.ts` di dalam handler route:
   - Jika berhasil: kembalikan `{ "data": "OK" }` dengan status code `200` atau `201`.
   - Jika gagal karena email duplikat: set status HTTP `400` dan kembalikan `{ "error": "Email sudah terdaftar" }`.
   - Tangani error tak terduga lainnya secara aman.

### **Tahap 4: Pendaftaran Rute di Aplikasi Utama (`src/index.ts`)**
1. Buka file `src/index.ts`.
2. Import `usersRoute` dari `./routes/users-route`.
3. Daftarkan rute ke instance aplikasi Elysia menggunakan `.use(usersRoute)`.

### **Tahap 5: Pengujian & Validasi Fitur**
1. Jalankan server lokal:
   ```bash
   bun run dev
   ```
2. **Uji Kasus Sukses (Happy Path)**:
   - Kirim `POST /api/users` dengan data email baru.
   - Verifikasi response adalah `{ "data": "OK" }`.
   - Periksa database untuk memastikan password tersimpan dalam bentuk hash bcrypt (dimulai dengan `$2a$` / `$2b$`).
3. **Uji Kasus Duplikasi Email**:
   - Kirim kembali request `POST /api/users` dengan email yang sama.
   - Verifikasi response berstatus HTTP `400` dengan body `{ "error": "Email sudah terdaftar" }`.

---

## 6. Kriteria Keberhasilan (Acceptance Criteria)
- [ ] Kolom `password` bertipe varchar(255) berhasil ditambahkan pada tabel `users`.
- [ ] File `src/services/users-service.ts` dan `src/routes/users-route.ts` dibuat sesuai konvensi penamaan.
- [ ] Endpoint `POST /api/users` menerima request body `name`, `email`, dan `password`.
- [ ] Password tersimpan di MySQL dalam bentuk hash bcrypt yang aman.
- [ ] Registrasi berhasil mengembalikan respons `{ "data": "OK" }`.
- [ ] Pendaftaran dengan email yang telah terdaftar mengembalikan status 400 dan respons `{ "error": "Email sudah terdaftar" }`.
- [ ] Server dapat berjalan normal tanpa error kompilasi TypeScript.
