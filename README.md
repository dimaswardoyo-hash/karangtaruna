# 🌐 Karang Taruna Klaten - Sistem Informasi Pemuda dan Organisasi

Selamat datang di repositori website [**Karang Taruna Kabupaten Klaten**]!

Website ini dirancang sebagai **pusat informasi, manajemen kegiatan, dan pemberdayaan pemuda** dalam satu sistem digital terpadu.  
💡 Dibangun dengan semangat _"Berkarya, Bersatu, dan Berdaya!"_

---

## 🔍 Fitur Utama

### 👥 Akses Guest
- 🔸 **Home Page** – Informasi dan update terbaru
- 🔸 **Category & Content Page** – Artikel, berita, dan kegiatan
- 🔸 **Struktur Karang Taruna** – Informasi kepengurusan
- 🔸 **Tentang Kami** – Profil singkat organisasi
- 🔸 **Login Page** – Akses masuk untuk anggota dan admin

---

### 🙋 Akses Anggota
- 🧑 **Dashboard Anggota**
- 📝 **Profil** – Lihat & edit identitas diri
- 📅 **Agenda**
  - Presensi kegiatan (terbuka/tutup otomatis)
  - Rapat & Notulen
  - Daftar kegiatan detail
- 🧾 **Perlengkapan**
  - Pinjam barang (form & ACC admin)
  - Lihat status & detail barang
- 👥 **Struktur Organisasi** – Informasi kepengurusan lengkap
- 💰 **Keuangan**
  - Laporan kas masuk, pengeluaran, dana lain

---

### 🛠️ Akses Admin
- 📊 **Dashboard Admin**
- 🔐 **Manajemen Profil & User**
  - Tambah/edit identitas
  - Tambah/edit/hapus user
- 📅 **Agenda & Kegiatan**
  - Tambah, edit, hapus agenda
  - Kontrol presensi (manual & otomatis)
  - Input Notulen
- 🧾 **Perlengkapan**
  - Tambah, edit, hapus barang
  - Verifikasi peminjaman
- 🧱 **Struktur Organisasi**
  - Kelola dan ubah kepengurusan
- 💸 **Keuangan**
  - Tambah kas, dana lain, dan pengeluaran
  - Lihat hutang anggota
- 🧑‍🤝‍🧑 **Kelola Anggota**
  - CRUD pengguna dan data lengkapnya
- 📰 **Konten Website**
  - Tambah/edit kategori, konten, dan banner
- 📢 **Broadcast WhatsApp**
  - Kirim pengumuman via WA ke anggota
- 📩 **Undangan**
  - Buat undangan digital
  - Print & Unduh PDF

---

## 🧠 Arsitektur Sistem
Website ini dibangun dengan pendekatan **role-based access** (Guest, Anggota, Admin) untuk memastikan hak akses dan keamanan data pengguna tetap terjaga.

---

## 💻 Teknologi yang Digunakan
- PHP Laravel Framework
- Blade Templating
- MySQL Database
- AOS Animation + Bootstrap UI
- Print-friendly PDF Output
- WhatsApp API (Broadcast)

---

## 🚀 Jalankan Secara Lokal
```bash
git clone https://github.com/username/karangtaruna-klaten.git
cd karangtaruna-klaten
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve
