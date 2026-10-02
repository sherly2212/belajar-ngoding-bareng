import { getRekap } from "../services/rekap-service";

const hasil = await getRekap();
console.log("Total kegiatan:", hasil.total);
console.log("Jumlah satker :", hasil.data.length);
console.log(JSON.stringify(hasil.data.slice(0, 3), null, 2));

process.exit(0);