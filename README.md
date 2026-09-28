# Belajar Ngoding Bareng - Backend API

Boilerplate backend API modular dan scalable menggunakan **Bun**, framework **ElysiaJS**, ORM **Drizzle**, dan database **MySQL**.

---

## 🛠️ Tech Stack

- **Runtime & Package Manager**: [Bun](https://bun.sh/)
- **Language**: TypeScript
- **Web Framework**: [ElysiaJS](https://elysiajs.com/)
- **ORM & Migrations**: [Drizzle ORM](https://orm.drizzle.team/) + `drizzle-kit`
- **Database Driver**: `mysql2`
- **Database**: MySQL

---

## 📁 Struktur Direktori

```text
├── drizzle/              # File migrasi SQL hasil generate Drizzle
├── src/
│   ├── config/           # Konfigurasi aplikasi & environment variables
│   │   └── index.ts
│   ├── db/               # Koneksi database MySQL & skema Drizzle
│   │   ├── index.ts
│   │   └── schema.ts
│   ├── routes/           # Endpoint & routing ElysiaJS
│   │   ├── health.ts     # Health-check route
│   │   └── index.ts      # Root API route
│   └── index.ts          # Entry point aplikasi server
├── .env.example          # Template environment variable
├── drizzle.config.ts     # Konfigurasi Drizzle Kit
├── package.json
└── tsconfig.json
```

---

## 🚀 Memulai (Getting Started)

### 1. Prasyarat
- Pastikan [Bun](https://bun.sh/) telah terpasang (`bun --version`).
- Database MySQL sudah berjalan secara lokal atau remote.

### 2. Instalasi Dependency
```bash
bun install
```

### 3. Konfigurasi Lingkungan (.env)
Salin template `.env.example` menjadi `.env`:
```bash
cp .env.example .env
```
Sesuaikan konfigurasi database dan port:
```env
PORT=3000
DATABASE_URL=mysql://root:password@localhost:3306/belajar_db
```

### 4. Database Migrations / Schema Sync
Sinkronisasikan skema tabel ke database MySQL:
```bash
# Push skema langsung ke database (pengembangan cepat)
bun run db:push

# Atau generate file migrasi SQL
bun run db:generate
```

### 5. Menjalankan Server
```bash
# Mode development (dengan live-reload)
bun run dev

# Mode production
bun run start
```
Server akan aktif di `http://localhost:3000`.

---

## 📡 Daftar Endpoint Dasar

| Method | Endpoint  | Deskripsi |
| :--- | :--- | :--- |
| `GET` | `/` | Informasi status API |
| `GET` | `/health` | Pemeriksaan kesehatan server dan koneksi MySQL |

Contoh respons `/health`:
```json
{
  "status": "ok",
  "timestamp": "2026-09-28T01:47:49.173Z",
  "database": "connected"
}
```