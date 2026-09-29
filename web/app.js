const API = "http://localhost:3000/api/users";
const $ = (id) => document.getElementById(id);

function pesan(teks, ok = false) {
    $("pesan").textContent = teks;
    $("pesan").className = ok ? "pesan ok" : "pesan";
}

// Fungsi bantu: kirim request ke API, otomatis bawa token kalau ada
async function api(path, options = {}) {
    const token = localStorage.getItem("token");
    const res = await fetch(API + path, {
        ...options,
        headers: {
            "Content-Type": "application/json",
            ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
    });
    const body = await res.json().catch(() => ({}));
    if (!res.ok || body.error) {
        throw new Error(body.error || "Input tidak valid atau terjadi kesalahan");
    }
    return body;
}

// Ganti tampilan: form login/daftar atau profil
async function tampilkan() {
    const token = localStorage.getItem("token");
    $("auth").hidden = !!token;
    $("profil").hidden = !token;
    if (!token) return;
    try {
        const { data } = await api("/current");
        $("profil-nama").textContent = data.name;
        $("profil-email").textContent = data.email;
    } catch {
        localStorage.removeItem("token"); // token tidak valid lagi
        tampilkan();
    }
}

$("ke-daftar").onclick = (e) => {
    e.preventDefault();
    $("form-login").hidden = true;
    $("form-daftar").hidden = false;
    pesan("");
};
$("ke-login").onclick = (e) => {
    e.preventDefault();
    $("form-daftar").hidden = true;
    $("form-login").hidden = false;
    pesan("");
};

$("form-daftar").onsubmit = async (e) => {
    e.preventDefault();
    try {
        await api("", {
            method: "POST",
            body: JSON.stringify({
                name: $("daftar-nama").value,
                email: $("daftar-email").value,
                password: $("daftar-password").value,
            }),
        });
        e.target.reset();
        $("ke-login").click();
        pesan("Daftar berhasil, silakan login", true);
    } catch (err) {
        pesan(err.message);
    }
};

$("form-login").onsubmit = async (e) => {
    e.preventDefault();
    try {
        const { data } = await api("/login", {
            method: "POST",
            body: JSON.stringify({
                email: $("login-email").value,
                password: $("login-password").value,
            }),
        });
        localStorage.setItem("token", data);
        e.target.reset();
        pesan("");
        tampilkan();
    } catch (err) {
        pesan(err.message);
    }
};

$("btn-logout").onclick = async () => {
    try {
        await api("/logout", { method: "DELETE" });
    } catch { }
    localStorage.removeItem("token");
    pesan("Kamu sudah logout", true);
    tampilkan();
};

tampilkan();