import { Elysia, t } from "elysia";
import { getRekap } from "../services/rekap-service";

/**
 * GET /api/rekap
 * Filter opsional lewat query: ?year=2026&satker=1371&status=Draft
 */
export const rekapRoute = new Elysia({ prefix: "/api/rekap" }).get(
    "/",
    async ({ query }) => {
        const hasil = await getRekap({
            year: query.year,
            satkerKode: query.satker,
            status: query.status,
        });
        return hasil;
    },
    {
        query: t.Object({
            year: t.Optional(t.Numeric()),
            satker: t.Optional(t.String({ maxLength: 4 })),
            status: t.Optional(t.String({ maxLength: 50 })),
        }),
        detail: {
            summary: "Rekap jumlah kegiatan per satker per status",
            tags: ["Rekap"],
        },
    }
);