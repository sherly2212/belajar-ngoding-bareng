// src/db/seed-satker.ts
// Mengisi tabel satker (aman dijalankan berulang kali)

import { db, poolConnection } from "./index";
import { satker } from "./schema";

const daftar = [
    { kode: "1301", nama: "Kab. Kepulauan Mentawai" },
    { kode: "1302", nama: "Kab. Pesisir Selatan" },
    { kode: "1303", nama: "Kab. Solok" },
    { kode: "1304", nama: "Kab. Sijunjung" },
    { kode: "1305", nama: "Kab. Tanah Datar" },
    { kode: "1306", nama: "Kab. Padang Pariaman" },
    { kode: "1307", nama: "Kab. Agam" },
    { kode: "1308", nama: "Kab. Lima Puluh Kota" },
    { kode: "1309", nama: "Kab. Pasaman" },
    { kode: "1310", nama: "Kab. Solok Selatan" },
    { kode: "1311", nama: "Kab. Dharmasraya" },
    { kode: "1312", nama: "Kab. Pasaman Barat" },
    { kode: "1371", nama: "Kota Padang" },
    { kode: "1372", nama: "Kota Solok" },
    { kode: "1373", nama: "Kota Sawahlunto" },
    { kode: "1374", nama: "Kota Padang Panjang" },
    { kode: "1375", nama: "Kota Bukittinggi" },
    { kode: "1376", nama: "Kota Payakumbuh" },
    { kode: "1377", nama: "Kota Pariaman" },
];

for (const s of daftar) {
    await db
        .insert(satker)
        .values(s)
        .onDuplicateKeyUpdate({ set: { nama: s.nama } });
}

console.log(`Selesai: ${daftar.length} satker tersimpan.`);
await poolConnection.end();