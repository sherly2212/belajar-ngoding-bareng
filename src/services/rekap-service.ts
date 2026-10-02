import { and, count, eq } from "drizzle-orm";
import { db } from "../db"; // <- BARU: lihat catatan di bawah
import { kegiatan, satker } from "../db/schema";

export type RekapFilter = {
    year?: number;
    satkerKode?: string;
    status?: string;
};

export type RekapSatker = {
    kode: string;
    nama: string;
    total: number;
    perStatus: Record<string, number>;
};

/**
 * Hitung jumlah kegiatan per satker, dirinci per status.
 * LEFT JOIN dari tabel satker, jadi satker tanpa kegiatan
 * tetap muncul dengan total 0.
 */
export async function getRekap(filter: RekapFilter = {}) {
    // Filter kegiatan ditaruh di ON (bukan WHERE) supaya
    // satker yang tidak cocok filter tetap muncul dengan angka 0.
    const rows = await db
        .select({
            kode: satker.kode,
            nama: satker.nama,
            status: kegiatan.status,
            jumlah: count(kegiatan.id),
        })
        .from(satker)
        .leftJoin(
            kegiatan,
            and(
                eq(kegiatan.satkerKode, satker.kode),
                filter.year ? eq(kegiatan.year, filter.year) : undefined,
                filter.status ? eq(kegiatan.status, filter.status) : undefined
            )
        )
        .where(filter.satkerKode ? eq(satker.kode, filter.satkerKode) : undefined)
        .groupBy(satker.kode, satker.nama, kegiatan.status)
        .orderBy(satker.kode);

    // Ubah "satu baris per satker+status" jadi "satu objek per satker"
    const peta = new Map<string, RekapSatker>();
    for (const r of rows) {
        let item = peta.get(r.kode);
        if (!item) {
            item = { kode: r.kode, nama: r.nama, total: 0, perStatus: {} };
            peta.set(r.kode, item);
        }
        if (r.status && r.jumlah > 0) {
            item.perStatus[r.status] = r.jumlah;
            item.total += r.jumlah;
        }
    }

    const data = [...peta.values()];
    const total = data.reduce((jumlah, s) => jumlah + s.total, 0);
    return { total, data };
}