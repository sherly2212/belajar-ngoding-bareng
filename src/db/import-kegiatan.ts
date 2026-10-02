// src/db/import-kegiatan.ts
// Mengambil semua kegiatan dari DNA (sementara: mock) lalu menyimpannya ke MySQL.
// Aman dijalankan berulang: data yang sudah ada diperbarui, bukan dobel.

import { db, poolConnection } from "./index";
import { satker, kegiatan } from "./schema";

const BASE_URL = process.env.DNA_BASE_URL;
const TOKEN = process.env.DNA_TOKEN;

if (!BASE_URL || !TOKEN) {
    console.error("DNA_BASE_URL atau DNA_TOKEN belum diisi di .env");
    process.exit(1);
}

type Halaman = {
    page: number;
    length: number;
    total: number;
    last_page: number;
    data: Record<string, any>[];
};

async function ambilHalaman(page: number): Promise<Halaman> {
    const params = new URLSearchParams({ length: "20", page: String(page) });
    const res = await fetch(`${BASE_URL}/metadata/mskeg/search?${params}`, {
        headers: { Authorization: `Bearer ${TOKEN}` },
    });
    if (!res.ok) {
        throw new Error(`Gagal ambil halaman ${page}: HTTP ${res.status}`);
    }
    return (await res.json()) as Halaman;
}

// 1. Ambil semua halaman
const semua: Record<string, any>[] = [];
const pertama = await ambilHalaman(1);
semua.push(...pertama.data);
for (let page = 2; page <= pertama.last_page; page++) {
    const hasil = await ambilHalaman(page);
    semua.push(...hasil.data);
}
console.log(`Diambil dari sumber: ${semua.length} data`);

// 2. Siapkan daftar kode satker yang valid
const daftarSatker = await db.select({ kode: satker.kode }).from(satker);
const kodeValid = new Set(daftarSatker.map((s) => s.kode));

// 3. Simpan satu per satu (upsert)
let tersimpan = 0;
let dilewati = 0;

for (const d of semua) {
    if (!kodeValid.has(String(d.city))) {
        console.warn(`Dilewati (kode satker tidak dikenal): id ${d.id}, city ${d.city}`);
        dilewati++;
        continue;
    }

    const baris = {
        id: Number(d.id),
        idIndah: d.id_indah ?? null,
        title: String(d.title),
        year: Number(d.year),
        satkerKode: String(d.city),
        statisticsType: d.statistics_type ?? null,
        collectionType: d.collection_type ?? null,
        status: String(d.status),
    };

    await db
        .insert(kegiatan)
        .values(baris)
        .onDuplicateKeyUpdate({
            set: {
                idIndah: baris.idIndah,
                title: baris.title,
                year: baris.year,
                satkerKode: baris.satkerKode,
                statisticsType: baris.statisticsType,
                collectionType: baris.collectionType,
                status: baris.status,
            },
        });
    tersimpan++;
}

console.log(`Selesai: ${tersimpan} tersimpan, ${dilewati} dilewati.`);
await poolConnection.end();