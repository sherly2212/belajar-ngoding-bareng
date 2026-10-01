// belajar-api/02-dna-mock.ts
// DNA MOCK: server tiruan untuk latihan memanggil API.
// Alamat dan parameternya meniru DNA asli, tapi DATANYA KARANGAN.

import { Elysia } from "elysia";

const PORT = 4000;
const TOKEN_MOCK = "token-latihan"; // token PALSU. Token asli nanti TIDAK boleh ditulis di kode!

// 19 kab/kota di Sumatera Barat (kode 4 digit)
const kotaSumbar = [
    { code: "1301", name: "Kab. Kepulauan Mentawai" },
    { code: "1302", name: "Kab. Pesisir Selatan" },
    { code: "1303", name: "Kab. Solok" },
    { code: "1304", name: "Kab. Sijunjung" },
    { code: "1305", name: "Kab. Tanah Datar" },
    { code: "1306", name: "Kab. Padang Pariaman" },
    { code: "1307", name: "Kab. Agam" },
    { code: "1308", name: "Kab. Lima Puluh Kota" },
    { code: "1309", name: "Kab. Pasaman" },
    { code: "1310", name: "Kab. Solok Selatan" },
    { code: "1311", name: "Kab. Dharmasraya" },
    { code: "1312", name: "Kab. Pasaman Barat" },
    { code: "1371", name: "Kota Padang" },
    { code: "1372", name: "Kota Solok" },
    { code: "1373", name: "Kota Sawahlunto" },
    { code: "1374", name: "Kota Padang Panjang" },
    { code: "1375", name: "Kota Bukittinggi" },
    { code: "1376", name: "Kota Payakumbuh" },
    { code: "1377", name: "Kota Pariaman" },
];

const jenisStatistik = ["STATISTIK_DASAR", "STATISTIK_SEKTORAL", "STATISTIK_KHUSUS"];
const jenisPengumpulan = [
    "SURVEI",
    "PENCACAHAN_LENGKAP",
    "KOMPILASI_PRODUK_ADMINISTRASI",
    "CARA_LAIN_SESUAI_DENGAN_PERKEMBANGAN_TI",
];
// PERHATIAN: field "status" ini BELUM TENTU ADA di DNA asli. Hanya untuk latihan.
const statusContoh = [
    "Draft", "Submit", "Diperiksa", "Sudah Diperbaiki",
    "Perlu Perbaikan", "Ditolak", "Disetujui",
];

// 57 kegiatan karangan (tiap kab/kota kebagian 3)
const semuaKegiatan = Array.from({ length: 57 }, (_, i) => {
    const n = i + 1;
    const kota = kotaSumbar[i % kotaSumbar.length];
    return {
        id: 1000 + n,
        id_indah: 83000 + n,
        title: `Kegiatan Contoh ${n}`,
        year: n % 2 === 0 ? 2026 : 2025,
        province: "13",
        city: kota.code,
        city_name: kota.name,
        statistics_type: jenisStatistik[i % jenisStatistik.length],
        collection_type: jenisPengumpulan[i % jenisPengumpulan.length],
        status: statusContoh[i % statusContoh.length],
    };
});

// Cek token: terima "Bearer token-latihan" maupun "token-latihan"
function tokenValid(authorization?: string) {
    if (!authorization) return false;
    const token = authorization.replace(/^Bearer\s+/i, "").trim();
    return token === TOKEN_MOCK;
}

// Potong data menjadi halaman-halaman (pagination)
function bagiHalaman<T>(data: T[], pageStr?: string, lengthStr?: string) {
    const length = Math.min(100, Math.max(1, Number(lengthStr) || 10));
    const page = Math.max(1, Number(pageStr) || 1);
    const mulai = (page - 1) * length;
    return {
        page,
        length,
        total: data.length,
        last_page: Math.max(1, Math.ceil(data.length / length)),
        data: data.slice(mulai, mulai + length),
    };
}

new Elysia({ prefix: "/api" })
    // "Satpam": dijalankan sebelum setiap endpoint di bawahnya
    .onBeforeHandle(({ headers, set }) => {
        if (!tokenValid(headers.authorization)) {
            set.status = 401;
            return { message: "Unauthenticated." };
        }
    })

    // Daftar kab/kota
    .get("/master/city", () => ({ data: kotaSumbar }))

    // Cari kegiatan, dengan filter + pagination
    .get("/metadata/mskeg/search", ({ query }) => {
        let hasil = semuaKegiatan;

        if (query.province) hasil = hasil.filter((k) => k.province === query.province);
        if (query.city) hasil = hasil.filter((k) => k.city === query.city);
        if (query.year) hasil = hasil.filter((k) => String(k.year) === query.year);
        if (query.title) {
            const cari = query.title.toLowerCase();
            hasil = hasil.filter((k) => k.title.toLowerCase().includes(cari));
        }
        if (query.staticticsType) {
            // (sengaja ditulis "staticticsType" seperti di dokumentasi DNA asli)
            hasil = hasil.filter((k) => k.statistics_type === query.staticticsType);
        }

        return bagiHalaman(hasil, query.page, query.length);
    })

    // Detail satu kegiatan
    .get("/metadata/mskeg/detail/:id", ({ params, set }) => {
        const ditemukan = semuaKegiatan.find((k) => String(k.id) === params.id);
        if (!ditemukan) {
            set.status = 404;
            return { message: "Data tidak ditemukan." };
        }
        return { data: ditemukan };
    })

    .listen(PORT);

console.log(`DNA mock jalan di http://localhost:${PORT}/api`);
console.log(`Token latihan: ${TOKEN_MOCK}`);