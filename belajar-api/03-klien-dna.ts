// belajar-api/03-klien-dna.ts
// Klien yang mengambil SEMUA halaman dari DNA mock (pakai last_page)

const BASE_URL = process.env.DNA_BASE_URL;
const TOKEN = process.env.DNA_TOKEN;

if (!BASE_URL || !TOKEN) {
    console.error("DNA_BASE_URL atau DNA_TOKEN belum diisi di .env");
    process.exit(1);
}

type Kegiatan = Record<string, any>;

type Halaman = {
    page: number;
    length: number;
    total: number;
    last_page: number;
    data: Kegiatan[];
};

// Ambil satu halaman
async function ambilHalaman(page: number): Promise<Halaman> {
    const params = new URLSearchParams({
        length: "5",
        page: String(page),
    });

    const res = await fetch(`${BASE_URL}/metadata/mskeg/search?${params}`, {
        headers: { Authorization: `Bearer ${TOKEN}` },
    });

    if (!res.ok) {
        throw new Error(`Gagal ambil halaman ${page}: HTTP ${res.status}`);
    }

    return (await res.json()) as Halaman;
}

// Ambil semua halaman sampai last_page
async function ambilSemua(): Promise<Kegiatan[]> {
    const semua: Kegiatan[] = [];

    // Halaman 1 dulu, untuk tahu last_page
    const pertama = await ambilHalaman(1);
    semua.push(...pertama.data);
    console.log(`Halaman 1/${pertama.last_page} -> ${pertama.data.length} data`);

    for (let page = 2; page <= pertama.last_page; page++) {
        const hasil = await ambilHalaman(page);
        semua.push(...hasil.data);
        console.log(`Halaman ${page}/${pertama.last_page} -> ${hasil.data.length} data`);
    }

    return semua;
}

const data = await ambilSemua();
console.log(`\nSelesai! Total data terkumpul: ${data.length}`);
console.log("Contoh data pertama:", data[0]);