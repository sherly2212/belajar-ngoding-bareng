// belajar-api/01-fetch-dasar.ts
// Latihan: memanggil API (GET), membaca JSON, dan mengambil data per halaman (pagination)

const BASE_URL = "https://jsonplaceholder.typicode.com";

type Post = { id: number; userId: number; title: string; body: string };

// Ambil SATU halaman data
async function ambilHalaman(page: number, length: number): Promise<Post[]> {
    const url = `${BASE_URL}/posts?_page=${page}&_limit=${length}`;

    const res = await fetch(url, {
        headers: { Accept: "application/json" },
        // nanti untuk DNA: Authorization: process.env.DNA_TOKEN
    });

    if (!res.ok) {
        throw new Error(`Gagal memanggil API: ${res.status} ${res.statusText}`);
    }

    return (await res.json()) as Post[];
}

// Ambil SEMUA data dengan mengulang halaman sampai habis
async function ambilSemua(): Promise<Post[]> {
    const hasil: Post[] = [];
    let page = 1;

    while (page <= 50) {
        const data = await ambilHalaman(page, 20);
        if (data.length === 0) break; // halaman kosong = data sudah habis
        hasil.push(...data);
        console.log(`Halaman ${page}: dapat ${data.length} data`);
        page++;
    }

    return hasil;
}

const semua = await ambilSemua();
console.log(`Total: ${semua.length} data`);
console.log("Judul pertama:", semua[0]?.title);