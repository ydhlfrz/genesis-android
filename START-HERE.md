# Current release: V18 Landscape RPG UI

For an existing working V17.2 account, read UPDATE-V18.md first. This UI update needs no new production SQL.

# Pembaruan 17.0

Untuk paket ini, ikuti **UPDATE-V17.md** terlebih dahulu. Langkah di bawah adalah dokumentasi fondasi versi sebelumnya.

# Genesis V16.4.5 — Native Android port, first candidate

Paket ini adalah source Android yang dibuat dari ZIP web V16.4.5 Anda. Ini belum merupakan APK yang telah lulus build atau diuji di HP. Workflow GitHub akan menjalankan pengujian engine, build, lint, dan SQL sebelum dipakai untuk pengujian perangkat.

## Perubahan utama

| Bagian | Implementasi Android |
|---|---|
| Akun | Register, login, logout, refresh token, session terenkripsi dengan Android Keystore |
| Tampilan | Native Android Views, warna cokelat/emas, logo dan mark Genesis |
| Karakter | Rekonstruksi G163 dari registry server, hidden race/class, family, ability, equipment, CP, stats, lore |
| Collection | Cari nama/race/class/ID, filter rarity/favorite, detail, rename, favorite, archive |
| Progression | Train +1 / ×5, level 1–100, evolution, weapon dan empat equipment upgrades |
| Prompt Studio | Splash Art 3:4 compact V16.4.5, copy prompt, pilih gambar dari Android, upload artwork |
| Artwork | Private Storage, metadata per registry ID, signed URL, thumbnail Collection |
| Codex | 42 race entries dan daftar seluruh discovery server |
| Achievements | 47 definisi dan total 940 AP; status serta progress berasal dari server |
| Daily | Daily missions, bonus penyelesaian, login reward |
| Profile | Display name, level, lifetime XP, AP/rank, statistik |
| History | 200 summon records terakhir dan 10 ledger events terbaru |
| Settings | Sound effects, reduce motion, compact Collection, refresh account |

Semua karakter/reward berasal dari permainan gratis. Tidak ada pembelian, transfer nilai uang, atau cash-out. Tidak ada battle/campaign dari starter yang ditambahkan ke port ini karena fitur tersebut bukan bagian dari web V16.4.5.

## Tentang native Android

Seluruh layar, navigasi, akses foto, audio, session storage, dan koneksi jaringan menggunakan API Android/Java. Tidak ada WebView dan tidak ada halaman HTML yang ditampilkan.

Untuk menjaga karakter G163 konsisten, fungsi matematika/data dari source web dipakai kembali sebagai engine JavaScript murni melalui interpreter Rhino dalam aplikasi. Engine ini tidak memiliki DOM, browser, jaringan, atau hak menulis ownership. Babel menyiapkan sintaks engine saat build. Ini bukan pengubahan seluruh fungsi data ke Java; yang dipertahankan bersama adalah logika rekonstruksi deterministik.

Source engine berasal dari web V16.4.5 yang Anda kirim. Arahan bentuk tubuh pada prompt diganti menjadi proporsi alami dan pakaian fantasi praktis. Layout splash art, identitas, class, equipment, power, dan footer dipertahankan.

## 1. Pilih backend yang tepat

Ada dua keadaan berbeda:

### A. Menggunakan Supabase Genesis web V16.4.5 yang sudah aktif

Gunakan Project URL dan publishable key dari project web tersebut dalam GitHub repository Variables. Login menggunakan akun web yang sama. Aplikasi membaca tabel `genesis_` dan bucket `genesis-character-art`.

Jangan jalankan ulang semua migrasi lama pada database produksi yang sudah aktif. Paket menyertakan satu patch kecil `backend/supabase-native-bootstrap-guard.sql` untuk membatasi pembuatan wallet baru menjadi saldo nol, sesuai alur full-online. Patch tidak mengubah saldo wallet yang sudah ada. Tinjau dan uji patch di development terlebih dahulu.

### B. Menggunakan Supabase baru yang sebelumnya hanya untuk starter Android

Tabel `g_profiles`, `g_heroes`, dan `g_requests` tidak cukup untuk edisi ini. Jalankan file berikut satu per satu lewat Supabase SQL Editor **dengan urutan ini** untuk menambahkan backend Genesis lengkap:

1. `backend/supabase-schema.sql`
2. `backend/supabase-v16_1-migration.sql`
3. `backend/supabase-v16_3a-migration.sql`
4. `backend/supabase-v16_3b-migration.sql`
5. `backend/supabase-v16_3c-migration.sql`
6. `backend/supabase-v16_3c_1-hotfix.sql`
7. `backend/supabase-v16_3d-migration.sql`
8. `backend/supabase-v16_4-migration.sql`
9. `backend/supabase-native-bootstrap-guard.sql`

Migration source asli disertakan tanpa mengubah isinya. Jangan jalankan file `tests/*` di Supabase; file tersebut hanya meniru Auth/Storage untuk CI.

Data starter `g_` tidak dihapus dan tidak dikonversi otomatis. Karakter starter memakai seed/data berbeda sehingga tidak dapat dianggap sebagai karakter registry G163 yang sah. Akun Auth yang sudah ada pada project yang sama bisa tetap login; profil gameplay Genesis lengkap dibuat terpisah saat pertama masuk.

Jika memilih project Supabase berbeda, akun dari project lama tidak otomatis ikut pindah. Untuk memakai akun/karakter web lama, hubungkan ke project web aslinya.

## 2. Perbarui repository Android

Ekstrak ZIP ini. Upload isi folder `genesis-native-v1645` ke root repository Android. Ganti file yang namanya sama. Jangan upload ZIP saja dan jangan menaruh folder pembungkus di dalam repository.

File penting yang berubah meliputi:

- `app/build.gradle`
- `app/src/main/AndroidManifest.xml`
- Semua source dalam `app/src/main/java/com/genesis/gacha/`
- `app/src/main/assets/` dan `app/src/main/res/`
- `tools/`, `tests/`, dan `backend/`
- `.github/workflows/android.yml`

**Workflow lama harus diganti.** Jika `.github` tidak ikut ter-upload, buka file `.github/workflows/android.yml` di GitHub dan ganti seluruh isinya dengan file `ANDROID-WORKFLOW.yml` yang terlihat di root paket ini. File root tersebut hanya salinan praktis; GitHub menjalankan file di `.github/workflows/`.

Paket berisi 89 file. Jika upload web menolak jumlah atau ukuran batch, upload isi root dalam beberapa batch: source/configuration lebih dulu, lalu folder media per bagian. Pertahankan struktur folder. Anda juga bisa menyalin isi paket ke clone repository lokal, kemudian commit/push dengan Git.

## 3. Repository Variables

Pertahankan atau ganti nilainya sesuai pilihan backend pada langkah 1:

| Nama tepat | Nilai |
|---|---|
| `SUPABASE_URL` | Project URL dengan `https://` |
| `SUPABASE_PUBLISHABLE_KEY` | Public publishable key |

Workflow sekarang berhenti lebih awal jika variabel kosong atau URL tidak valid. Nilai variabel tidak dicetak dalam log. Jangan memakai secret/service-role key.

## 4. Build dan install

Actions → **Build Genesis Android** → Run workflow pada `main`.

Workflow akan:

1. Memeriksa konfigurasi publik.
2. Menyiapkan engine JavaScript untuk interpreter Android.
3. Membandingkan 100 fixture karakter/prompt lewat unit tests.
4. Membuild APK dan menjalankan Android lint.
5. Menerapkan migrasi dan memeriksa backend di PostgreSQL sementara pada job terpisah.

Tunggu kedua job hijau. Download artifact **Genesis-Android-APK**, ekstrak, lalu install `app-debug.apk` di HP.

Jika Android menolak update karena tanda tangan berbeda, itu dapat terjadi karena debug keystore runner berubah. Jangan menghapus aplikasi sebelum memastikan Anda mengetahui akun yang digunakan. Progress Genesis tersimpan di server; penggunaan signing key tetap diperlukan untuk distribusi update jangka panjang.

## 5. Uji perangkat

- Login dan pastikan akun/profile yang tampil benar.
- Periksa karakter web yang sudah ada, seed, nama, rarity, dan CP.
- Coba character detail, favorite, rename, search, serta filter.
- Uji train dan satu equipment upgrade; cek kembali melalui web.
- Salin prompt dan periksa footer.
- Upload PNG/JPEG/WebP maksimal 10 MB, lalu cek thumbnail Collection dan artwork dari web.
- Uji Daily/Login, achievement status, Codex, serta History.
- Tutup proses aplikasi dan buka lagi untuk memeriksa persistent session.
- Sign out dan masuk akun lain; pastikan Collection terpisah.

## Batas validasi yang sebenarnya

Di lingkungan penyusunan, source Java diperiksa sintaksnya dan engine JavaScript dijalankan di Node untuk membuat 100 fixture deterministik. Aset diperiksa, path diverifikasi, dan konfigurasi dibaca secara statis.

**Belum dijalankan di lingkungan ini:** build Android, Android lint, interpreter Rhino, PostgreSQL integration suite, live Supabase, dan emulator/perangkat. Dependensi Android/Rhino belum tersedia dan pengunduhan jaringan tidak tersedia. File ini adalah kandidat implementasi; hasil CI aktual diperlukan sebelum dinyatakan lulus.

UI menggunakan native controls dengan aset asli, bukan replika piksel-per-piksel web. SFX berupa nada Android pendek dan reveal berupa fade berdasarkan rarity; efek Web Audio asli belum direplikasi persis. Codex non-race tersedia dalam daftar discovery. Password recovery/deep links dan penghapusan akun belum ditambahkan. Jangan menganggap pekerjaan visual dan perangkat selesai hanya dari hasil unit test.

## Struktur teknis

`MainActivity.java`: seluruh layar native, navigation, server RPC calls, artwork flow.

`Api.java`: HTTPS Auth/PostgREST/Storage, token refresh, error propagation.

`SessionStore.java`: AES-GCM session encryption with Android Keystore.

`CharacterEngine.java`: sandboxed Rhino interpreter for deterministic reconstruction.

`tools/engine-source.js`: pure data/math/prompt functions extracted from V16.4.5.

`tools/transpile.cjs`: prepares interpreter-compatible engine. No browser code is bundled.

`backend/`: original supplied migrations plus zero-balance bootstrap guard.

Diperlukan JDK 17, Android SDK 35, Gradle 8.11.1, Node 22. Workflow menyiapkan semuanya. Untuk build lokal: `npm install --prefix tools`, `node tools/transpile.cjs`, kemudian `gradle :app:testDebugUnitTest :app:assembleDebug :app:lintDebug`. Gradle wrapper belum dibundel.

No backend was deployed, no existing account data was altered, and no GitHub repository was edited by preparing this package.
