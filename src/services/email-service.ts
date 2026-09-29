import nodemailer from "nodemailer";

const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT),
    auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
    },
});

export async function sendResetCode(email: string, code: string) {
    await transporter.sendMail({
        from: process.env.MAIL_FROM,
        to: email,
        subject: "Kode reset password",
        text: `Kode reset password kamu: ${code}. Berlaku 15 menit. Jangan bagikan kode ini ke siapa pun.`,
    });
}