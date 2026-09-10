# Genesis 17.0 — Five-tier economy update

Paket ini berisi source Android lengkap dan SQL migrasi. Belum berupa APK. Produksi aset karakter ditunda.

## Cara memasang untuk repository yang sudah berjalan

1. Ekstrak ZIP. Upload isi folder `genesis-android-main` ke root repository lama, termasuk `.github/workflows/android.yml`. Timpa file yang namanya sama. Repository dan variable Supabase tetap dipakai.
2. Jalankan **Build Genesis Android** pada commit terbaru. Tunggu **build** dan **database-tests** sama-sama berhasil. Build menghasilkan APK; workflow tidak menjalankan migrasi pada Supabase produksi.
3. Setelah kedua job berhasil, siapkan APK baru dan jadwalkan pergantian aplikasi. Buat backup database melalui fasilitas project sebelum migrasi.
4. Di Supabase SQL Editor project yang sekarang digunakan, jalankan hanya `backend/supabase-v17-migration.sql`. Semua migrasi lama harus sudah terpasang. Jangan jalankan `tests/` di Supabase produksi.
5. Pasang APK baru dan masuk dengan akun lama. Versi aplikasi lama perlu diperbarui karena endpoint summon/reward lama diblokir untuk menjaga ekonomi baru.
6. Periksa Collection Legacy, Daily check-in, tiket, summon GP, dan Shop. Migrasi tidak menghapus koleksi, saldo, artwork, atau progres.

Migrasi berada dalam transaksi; kegagalan membatalkan seluruh perubahan transaksi. Rerun tidak menggandakan tiket sambutan atau konversi pity. Setelah migrasi berhasil, jangan mengembalikan engine/database ke versi lama tanpa rencana pemulihan data, karena karakter G165 memerlukan engine baru.

## Aturan yang diterapkan

- Common 3★ 60%; Rare 4★ 30%; Super Rare 5★ 7%; Epic 6★ 2.5%; Mythic 7★ 0.5%.
- Ras dipilih merata dalam tier sesuai spreadsheet: 22/31/37/18/6 ras. Demi God menggunakan nama kanonik lama Demi-God. Human hanya Common/Rare/SR.
- Seed baru G165. Seed lama tetap memakai engine Legacy. Hidden forms baru ditunda.
- Weapon/equipment memakai lima rarity secara independen, tanpa pity tambahan. Pilihan jenis equipment tetap mengikuti pool lama; belum ada sistem pembatasan pemakaian equipment per class.
- Nilai kekuatan tier memakai band internal 1/3/5/7/9 agar tidak mencampur jumlah bintang tampilan dengan formula stat. Common baru bukan Rare lama.
- Level, evolution, upgrade, kepemilikan, favorite, nama, archive, dan artwork tetap tersedia.
- Dua pity selalu aktif: setelah 39 hasil di bawah SR, berikutnya SR+; setelah 89 hasil tanpa Mythic, berikutnya Mythic. Soft pity mulai draw70=1%, meningkat 0.5 poin persentase sampai draw89=10.5%.
- Mythic reset kedua counter. SR/Epic hanya reset SR counter. Saat SR dijamin, sisa peluang non-Mythic dibagi SR:Epic 7:2.5. Semua draw10 diproses berurutan.
- Konversi satu kali: sr=min(pity_lama,39), mythic=floor(pity_lama*89/60). Semua saldo lama dipertahankan.
- 1x 12 GP; 10x 120 GP. Tiket alternatif 1 per karakter. Reward GP dari rarity dihapus. Akun mendapat 5 tiket sambutan sekali, termasuk akun lama.
- GP/Tokens/Tickets tidak dijual, tidak kedaluwarsa, dan tidak bisa diuangkan.

## Daily pengganti

Tidak ada penalti streak. Klaim per akun, reset tanggal UTC. Reward tidak diakumulasikan otomatis untuk hari yang tidak diklaim.

| Misi | Hadiah |
|---|---|
| Check-in | 60 GP, 50 Essence, 10 Tokens, 1 Ticket |
| Summon 1 | 12 GP |
| Summon 3 | 24 GP |
| Train 1 kali | 12 GP, 15 Essence |
| Upgrade 1 kali | 12 GP, 20 Essence |

Maksimum hadiah Daily: 120 GP, 85 Essence, 10 Tokens, 1 Ticket per hari, di luar hadiah achievement. Itu pemasukan bruto sebelum biaya summon/progression, bukan jaminan net gain. Check-in memastikan akun saldo nol bisa tetap memperoleh karakter dan bahan tanpa pembelian. Nilai ini baseline uji permainan, belum divalidasi dengan telemetry pemain.

## Exchange Shop pertama

5 Tokens = 50 Essence. 12 Tokens = 150 Essence. Harga dan isi tetap; konfirmasi sebelum menukar. Tidak ada kotak acak, peningkat peluang, kosmetik palsu, atau equipment yang belum dapat dipakai. Mythic Fragments dan kosmetik belum termasuk rilis ini.

## Legacy dan achievement

Tidak ada karakter lama yang diubah menjadi tier baru. Badge Legacy dipertahankan. Badge V2 dirender native dengan label/bintang yang benar; suara/gerakan menggunakan efek lama yang dipetakan ke lima tier. Aset badge premium baru belum dibuat.

AP dan achievement yang sudah diklaim tetap ada. Target rarity/hidden/login yang pensiun diberi label Legacy dan tidak memberi unlock baru; tidak ada hadiah ganda. Achievement umum tetap berjalan. Daily-count dan perfect-daily menerima progres dari misi baru. Catatan progres historis tetap disimpan. Layar tidak lagi menjanjikan bahwa semua 940 AP lama masih dapat diperoleh. History/ledger tetap menyimpan transaksi lama; headline statistik lama tertentu masih berlandaskan data legacy.

## Validasi

Sudah dijalankan lokal: matriks 42 ras, total peluang dasar, 100 fixture Legacy dan prompt yang identik, 500 hasil V2 serta eligibility, dan parsing sintaks 9 file Java.

Belum dijalankan lokal: Gradle/Android lint, interpreter Rhino, PostgreSQL runtime, tampilan di perangkat, dan transaksi paralel langsung. Lingkungan ini tidak memiliki Android SDK, Gradle, atau PostgreSQL. Workflow berisi pengujian JVM, migrasi dua kali, parity stat engine/database, transaksi idempotent, insufficient balance, RLS antar-akun, serta batas pity. Jangan menerapkan SQL produksi sebelum kedua job berhasil.
