# Belajar Ngoding Bareng

Aplikasi backend sederhana untuk belajar membangun REST API dengan autentikasi user, dibuat sambil mengikuti tutorial "vibe coding".

## Tentang Aplikasi

Aplikasi ini menyediakan API untuk registrasi, login, melihat data user yang sedang login, dan logout. Password disimpan dalam bentuk hash (bcrypt), dan sesi login dikelola menggunakan token di tabel `sessions`.

## Technology Stack

- **Runtime**: [Bun](https://bun.sh)
- **Web Framework**: [ElysiaJS](https://elysiajs.com)
- **ORM**: [Drizzle ORM](https://orm.drizzle.team)
- **Database**: MySQL
- **Bahasa**: TypeScript
- **Testing**: `bun test` (bawaan Bun)

## Library yang Digunakan

| Library | Kegunaan |
|---|---|
| `elysia` | Framework web untuk membuat routing dan HTTP server |
| `drizzle-orm` | ORM untuk berkomunikasi dengan database MySQL |
| `mysql2` | Driver koneksi ke database MySQL |
| `drizzle-kit` | Tool untuk membuat migrasi database dari skema Drizzle |

## Struktur Folder
belajar-ngoding-bareng/
├── src/
│ ├── index.ts # Entry point, menjalankan server
│ ├── config/
│ │ └── index.ts # Konfigurasi aplikasi (baca dari .env)
│ ├── db/
│ │ ├── index.ts # Koneksi database
│ │ └── schema.ts # Skema tabel (users, sessions)
│ ├── routes/
│ │ ├── index.ts # Gabungan semua routing
│ │ ├── health.ts # Endpoint GET /health
│ │ └── users-route.ts # Endpoint terkait user (register, login, dll)
│ └── services/
│ └── users-service.ts # Logika bisnis (hashing, validasi, query DB)
├── tests/
│ └── users.test.ts # Unit test untuk semua fungsi di users-service.ts
├── drizzle/ # File migrasi database (dibuat otomatis oleh drizzle-kit)
├── drizzle.config.ts # Konfigurasi Drizzle Kit
└── .env # Variabel environment (PORT, DATABASE_URL)

**Pola penamaan file**: routing memakai akhiran `-route.ts` (contoh: `users-route.ts`), logika bisnis memakai akhiran `-service.ts` (contoh: `users-service.ts`). Ini memisahkan urusan HTTP (routing) dari logika sebenarnya (service), supaya lebih mudah dites dan dirawat.

## Schema Database

### Tabel `users`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INTEGER | Primary Key, Auto Increment |
| `name` | VARCHAR(255) | Not Null |
| `email` | VARCHAR(255) | Not Null, Unique |
| `password` | VARCHAR(255) | Not Null (hash bcrypt) |
| `created_at` | TIMESTAMP | Not Null, Default CURRENT_TIMESTAMP |

### Tabel `sessions`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INTEGER | Primary Key, Auto Increment |
| `token` | VARCHAR(255) | Not Null (UUID token login) |
| `user_id` | INTEGER | Foreign Key ke `users.id` |
| `created_at` | TIMESTAMP | Not Null, Default CURRENT_TIMESTAMP |

## API yang Tersedia

### `GET /`
Menampilkan info dasar aplikasi.

### `GET /health`
Mengecek status server dan koneksi database.

### `POST /api/users`
Registrasi user baru.

**Request Body:**
```json
{
  "name": "Sherly",
  "email": "sherly@example.com",
  "password": "rahasia123"
}
```

**Response Sukses:**
```json
{ "data": "OK" }
```

**Response Gagal (email sudah terdaftar):**
```json
{ "error": "Email sudah terdaftar" }
```

### `POST /api/users/login`
Login user.

**Request Body:**
```json
{
  "email": "sherly@example.com",
  "password": "rahasia123"
}
```

**Response Sukses:**
```json
{ "data": "<token>" }
```

**Response Gagal:**
```json
{ "error": "Email atau password salah" }
```

### `GET /api/users/current`
Mendapatkan data user yang sedang login.

**Header:**

**Response Sukses:**
```json
{
  "data": {
    "id": 1,
    "name": "Sherly",
    "email": "sherly@example.com",
    "created_at": "2026-09-28T00:00:00.000Z"
  }
}
```

### `DELETE /api/users/logout`
Logout user, menghapus session/token.

**Header:**

**Response Sukses:**
```json
{ "data": "OK" }
```

## Cara Setup Project

1. Install [Bun](https://bun.sh) (versi 1.4 ke atas).
2. Install MySQL dan buat database baru, misalnya `belajar_db`.
3. Clone repository ini, lalu install dependency:
```bash
   bun install
```
4. Copy `.env.example` menjadi `.env`, lalu sesuaikan `DATABASE_URL` dengan koneksi MySQL-mu:
5. Jalankan migrasi database:
```bash
   bun run db:push
```

## Cara Menjalankan Aplikasi

```bash
bun run dev
```

Server berjalan di `http://localhost:3000` dengan auto-reload saat ada perubahan kode.

## Cara Menjalankan Test

```bash
bun test
```

Menjalankan seluruh unit test yang ada di folder `tests/`, mencakup skenario registrasi, login, get current user, dan logout.