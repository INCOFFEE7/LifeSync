# TEMPLATE PERMINTAAN PERUBAHAN & INTEGRITAS FITUR
> Gunakan template ini untuk setiap permintaan fitur atau perbaikan agar sinkron antara User dan Programmer, menjaga integritas fitur existing, dan mencegah data hilang / regresi.

---

## 📌 BAGIAN 1: PERMINTAAN USER (Diisi oleh User)

### 1. Informasi Tiket
- **ID / Judul Tiket**: `[Contoh: FEAT-01 / Perbaikan Filter Bar & Logo Dark Mode]`
- **Tanggal Permintaan**: `YYYY-MM-DD`
- **Target Versi**: `[Contoh: v2026.11.06.01.01]`
- **Halaman / Modul Terdampak**: `[Contoh: Catatan Keuangan / Pengingat / Dashboard]`

### 2. Kondisi Saat Ini vs Perilaku yang Diharapkan
| Kondisi Saat Ini (As-Is) | Perilaku yang Diharapkan (To-Be) | Alasan / Prioritas |
| :--- | :--- | :--- |
| *Deskripsi apa yang terjadi sekarang* | *Deskripsi apa yang diinginkan* | *Low / Medium / High / Critical* |

### 3. Ruang Lingkup Spesifik yang Diminta (In-Scope)
> Tuliskan poin perubahan secara rinci. Programmer HANYA akan mengubah poin di bawah ini.
1. [ ] Perubahan 1: ...
2. [ ] Perubahan 2: ...
3. [ ] Perubahan 3: ...

### 4. Batasan Tegas (Out-of-Scope / DILARANG DIUBAH)
> Fitur, tampilan, atau alur yang TIDAK BOLEH berubah pada halaman terkait.
- [ ] Dilarang mengubah alur data / skema database existing.
- [ ] Dilarang mengubah tombol / aksi existing berikut: `...`
- [ ] Dilarang mengubah styling / warna selain yang disebutkan di In-Scope.

---

## 🛠️ BAGIAN 2: AUDIT & RENCANA PROGRAMMER (Diisi oleh Developer Sebelum Coding)

### 1. Checklist Fitur Eksisting di Halaman Tersebut (Existing Page Audit)
> Programmer WAJIB memetakan seluruh komponen halaman ini sebelum coding untuk memastikan tidak ada fitur lama yang rusak/hilang.

#### A. Frontend (UI / Komponen Tampilan)
- [ ] Header / AppBar (Logo, title, icons, action buttons)
- [ ] Filter / Baris Navigasi Tanggal (Bulan, dropdown range, icon)
- [ ] Komponen Konten Utama (Cards, list tiles, status chips, charts)
- [ ] Tombol Aksi / Floating Action Button (FAB)
- [ ] Modal / Bottom Sheet / Dialog terkait
- [ ] Mode Tampilan (Light mode & Dark mode compatibility)

#### B. Backend / Logic / State & Database
- [ ] State Management (Provider, Notifier, Controller yang dipakai)
- [ ] Query / Stream Database (Tabel Isar, entity, filter query)
- [ ] Fungsi Perhitungan / Formatting (Currency, date parser, calculator)
- [ ] Integrasi Notifikasi / Alarm / Background Service
- [ ] Integrasi Cloud Sync / Google Drive / Ekspor CSV

### 2. Rencana File yang Dimodifikasi (Impacted Files & Minimal Diff)
| Path File | Alasan Perubahan | Tingkat Risiko (Rendah/Sedang/Tinggi) |
| :--- | :--- | :--- |
| `lib/...` | *Alasan spesifik* | *Rendah* |

### 3. Pemeriksaan Keamanan Data & Versi (Safety Check)
- [ ] **Tidak ada data reset**: Tidak ada truncate/drop table database.
- [ ] **Version Code Safety**: `versionCode` lebih tinggi dari versi sebelumnya (`> previous_versionCode`) dan integer valid (< 2.147.483.647).
- [ ] **Minimal Diff**: Tidak ada refactoring kode di luar lingkup permintaan user.

---

## ✅ BAGIAN 3: VERIFIKASI & LAPORAN AKHIR (Diisi oleh Developer Setelah Coding)

### 1. Eksekusi Pengujian
- [ ] `dart format`: Terformat rapi.
- [ ] `dart analyze`: 0 errors.
- [ ] `flutter test`: Lulus 100%.
- [ ] `flutter build apk` / Device Run: Berhasil dijalankan tanpa error downgrade atau crash.

### 2. Verifikasi Preservasi Fitur Eksisting (Regression Check)
- [ ] Fitur UI lama di halaman terkait tetap tampil dan berfungsi normal.
- [ ] Fitur logic/database lama tetap menghasilkan data yang benar.
- [ ] Fitur Light Mode & Dark Mode tetap selaras.

### 3. Catatan Penyelesaian
- **Branch / Commit Hash**: `[Contoh: redesign-ui / a1b2c3d]`
- **Risiko Tersisa / Unverified**: `[Jika ada, sebutkan di sini]`
- **Fitur di luar lingkup yang sengaja tidak disentuh**: `[Sebutkan]`

---

## ✍️ TANDA TANGAN PERSETUJUAN (Sign-off)

- **User**: `[ Nama / Tanggal / Status: Approved / Revision Needed ]`
- **Developer**: `[ Nama / Tanggal / Status: Implemented & Verified ]`
