import nodemailer from "nodemailer";
import dns from "node:dns/promises";

export async function sendResetCode(email: string, code: string) {
    const host = process.env.SMTP_HOST as string;
    const port = Number(process.env.SMTP_PORT);

    // Cari alamat IPv4 Gmail, karena IPv6 di jaringan ini gagal
    const { address } = await dns.lookup(host, { family: 4 });

    const transporter = nodemailer.createTransport({
        host: address, // sambung langsung ke IPv4
        port,
        secure: port === 465,
        tls: { servername: host }, // supaya sertifikat tetap dicek untuk smtp.gmail.com
        auth: {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASS,
        },
    });

    await transporter.sendMail({
        from: `"Belajar Ngoding" <${process.env.SMTP_USER}>`,
        to: email,
        subject: "Kode reset password",
        text: `Kode reset password kamu: ${code}. Berlaku 15 menit.`,
    });
}