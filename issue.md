# Bug Fix: Validasi Panjang Karakter pada Endpoint Registrasi

## Tahapan Perbaikan

### Tahap 1: Pembaruan Skema Validasi di Elysia
Tambahkan batasan panjang pada skema registrasi (POST /api/users) agar sesuai kapasitas database. Gunakan properti maxLength dan minLength.

body: t.Object({
  name: t.String({ minLength: 3, maxLength: 255 }),
  email: t.String({ format: "email", maxLength: 255 }),
  password: t.String({ minLength: 6, maxLength: 255 }),
}),

### Tahap 2: Mencegah Kebocoran Error SQL
Di blok catch route registrasi, ubah agar pesan error mentah dari database tidak ikut dikembalikan ke client. Hanya error yang sengaja dilempar sendiri (punya .status) yang boleh tampil pesannya.
