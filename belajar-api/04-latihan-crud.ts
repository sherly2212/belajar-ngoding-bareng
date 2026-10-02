// belajar-api/04-latihan-crud.ts
// Server latihan: tambah, ubah, hapus catatan (data di memori)

import { Elysia, t } from "elysia";

const TOKEN = "token-latihan";

type Catatan = { id: number; judul: string };

let catatan: Catatan[] = [
    { id: 1, judul: "Belajar fetch" },
    { id: 2, judul: "Belajar pagination" },
];
let idBerikutnya = 3;

new Elysia({ prefix: "/api" })
    // Satpam: semua endpoint di bawah ini wajib pakai token
    .onBeforeHandle(({ request, set }) => {
        if (request.headers.get("authorization") !== `Bearer ${TOKEN}`) {
            set.status = 401;
            return { message: "Unauthenticated." };
        }
    })

    // GET: lihat semua catatan
    .get("/catatan", () => catatan)

    // POST: tambah catatan baru
    .post(
        "/catatan",
        ({ body, set }) => {
            const baru = { id: idBerikutnya++, judul: body.judul };
            catatan.push(baru);
            set.status = 201; // 201 = berhasil dibuat
            return baru;
        },
        { body: t.Object({ judul: t.String({ minLength: 1 }) }) }
    )

    // PATCH: ubah judul catatan
    .patch(
        "/catatan/:id",
        ({ params, body, set }) => {
            const item = catatan.find((c) => c.id === Number(params.id));
            if (!item) {
                set.status = 404;
                return { message: "Catatan tidak ditemukan." };
            }
            item.judul = body.judul;
            return item;
        },
        { body: t.Object({ judul: t.String({ minLength: 1 }) }) }
    )

    // DELETE: hapus catatan
    .delete("/catatan/:id", ({ params, set }) => {
        const ada = catatan.some((c) => c.id === Number(params.id));
        if (!ada) {
            set.status = 404;
            return { message: "Catatan tidak ditemukan." };
        }
        catatan = catatan.filter((c) => c.id !== Number(params.id));
        return { message: "Catatan dihapus." };
    })

    .listen(4001);

console.log("Server latihan CRUD jalan di http://localhost:4001");