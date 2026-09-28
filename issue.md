# Issue: Inisialisasi Proyek Backend dengan Bun, ElysiaJS, Drizzle ORM & MySQL

## 1. Deskripsi & Tujuan
Membuat fondasi (*boilerplate*) proyek backend API baru menggunakan runtime **Bun**, framework **ElysiaJS**, dan ORM **Drizzle** yang terhubung ke database **MySQL**. 

Dokumen ini berfungsi sebagai panduan implementasi tingkat tinggi (*high-level roadmap*) bagi programmer atau AI implementor untuk menyusun arsitektur dan konfigurasi dasar proyek secara terstruktur.

---

## 2. Tech Stack
- **Runtime & Package Manager**: [Bun](https://bun.sh/)
- **Language**: TypeScript
- **Web Framework**: [ElysiaJS](https://elysiajs.com/)
- **ORM & Migrations**: [Drizzle ORM](https://orm.drizzle.team/) + `drizzle-kit`
- **Database Driver**: MySQL (misalnya `mysql2` driver)
- **Database**: MySQL

---

## 3. High-Level Implementation Steps

### Tahap 1: Inisialisasi Proyek & Lingkungan
- Inisialisasi proyek TypeScript berbasis Bun di direktori proyek.
- Konfigurasi `package.json` untuk metadata proyek dan script runner (`dev`, `build`, `start`).
- Setup file konfigurasi dasar:
  - `tsconfig.json` (pastikan mendukung modul Bun/TypeScript terkini).
  - `.gitignore` (abaikan `node_modules`, `.env`, build artifact, log).
  - `.env.example` (template variabel lingkungan untuk port server dan kredensial database).

### Tahap 2: Manajemen Dependency
- Pasang dependency utama:
  - Framework: `elysia`
  - ORM: `drizzle-orm`
  - MySQL client: driver MySQL yang kompatibel dengan Bun & Drizzle (contoh: `mysql2`)
- Pasang dev dependencies:
  - Tooling migrasi: `drizzle-kit`
  - Type definitions yang diperlukan (jika belum tercakup).

### Tahap 3: Perancangan Struktur Direktori
Rancang struktur folder modular dan scalable di dalam `src/`, contohnya:
```text
├── src/
│   ├── config/       # Pengaturan env & aplikasi
│   ├── db/           # Koneksi database, schema Drizzle, & migrasi
│   ├── routes/       # Endpoint / controller ElysiaJS
│   └── index.ts      # Entry point aplikasi server
├── drizzle.config.ts # Konfigurasi Drizzle Kit
├── .env.example
├── package.json
└── tsconfig.json
```

### Tahap 4: Konfigurasi Database & Drizzle
- Konfigurasi koneksi MySQL pool menggunakan variabel lingkungan.
- Inisialisasi instance Drizzle ORM dengan koneksi database tersebut.
- Buat file `drizzle.config.ts` untuk mengatur schema folder, output migrasi, dan dialek MySQL.
- Sediakan minimal 1 skema tabel percontohan (misalnya tabel `users` atau health-check log) untuk memvalidasi integrasi Drizzle.

### Tahap 5: Konfigurasi Server ElysiaJS
- Buat entry point server pada `src/index.ts`.
- Tambahkan middleware dasar (error handling, logging/CORS jika relevan).
- Sediakan endpoint dasar:
  - `GET /`: Sambutan / info API.
  - `GET /health`: Health-check status server dan status koneksi database.
- Pastikan server dapat berjalan di port yang ditentukan via environment variable.

### Tahap 6: Scripting & Database Tooling
- Tambahkan script Drizzle pada `package.json`, minimal mencakup:
  - Generate migrasi (`drizzle-kit generate`)
  - Eksekusi migrasi (`drizzle-kit migrate` atau `push`)
  - Drizzle Studio viewer (opsional, `drizzle-kit studio`)

### Tahap 7: Dokumentasi & Verifikasi Akhir
- Tuliskan panduan singkat di `README.md` mengenai:
  - Cara instalasi dependency (`bun install`).
  - Cara setup file `.env`.
  - Cara menjalankan migrasi database.
  - Cara menjalankan server dalam mode development (`bun run dev`).

---

## 4. Kriteria Keberhasilan (Acceptance Criteria)
- [ ] Proyek dapat diinstal tanpa konflik dependency menggunakan `bun install`.
- [ ] Server dapat dijalankan secara lancar dengan perintah `bun run dev`.
- [ ] Endpoint `GET /` dan `GET /health` merespons dengan format JSON yang valid dan status code `200`.
- [ ] Konfigurasi Drizzle dapat mengenali schema dan berhasil terhubung ke MySQL.
- [ ] Skrip migrasi Drizzle dapat dijalankan tanpa error konfigurasi.
- [ ] Struktur kode bersih, terpisah antara layer rute/controller dan database layer.

---

## 5. Catatan untuk Implementor
- Hindari hardcoding kredensial database di kode sumber; selalu gunakan environment variable.
- Implementasi difokuskan pada fondasi/boilerplate arsitektur yang solid, belum memerlukan implementasi bisnis logic yang kompleks.
