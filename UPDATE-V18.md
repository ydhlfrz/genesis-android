# Genesis V18 — Landscape RPG UI

Paket source Android lengkap, dibangun dari V17.2 beserta perbaikan gambar V17.2.1. Ini belum berupa APK yang sudah diuji pada perangkat.

## Pemasangan untuk akun/repository V17.2 yang sudah berjalan

1. Ekstrak ZIP. Upload isi folder genesis-android-main ke root repository yang sama dan timpa file bernama sama. Sertakan .github/workflows/android.yml, seluruh app/src, dan tools.
2. Variable Supabase tetap menggunakan nilai sebelumnya.
3. Tunggu database-tests dan build pada commit terbaru berhasil, lalu unduh artifact Genesis-Android-APK.
4. Pasang APK sebagai pembaruan aplikasi yang sama. Tidak ada SQL/migrasi baru untuk V18; jangan mengulang migrasi produksi untuk pembaruan UI ini. Database V17.2 yang sudah berhasil tetap digunakan.

## Tampilan dan navigasi

- sensorLandscape: layar horizontal pada kedua arah landscape. Beberapa mode multiwindow/perangkat besar bisa mengatur orientasi sendiri; tata letak mengandalkan ukuran ruang tersedia.
- Sidebar kiri dapat digulir, header akun di atas. Navigasi Home, Collection, Progression, Prompt, Daily, Shop, Codex, Achievements, Profile, History, Settings.
- Panel charcoal/green gelap, bingkai emas bertingkat bergaya pixel, tombol dengan state tekan/fokus/nonaktif, tipografi monospace. Bingkai dirender native, tidak mengambil gambar atau font dari internet.
- Login dua panel; Home memisahkan ritual dan kontrol. Panel dapat digulir secara mandiri pada layar pendek.
- Collection dan Codex memakai grid 2–4 kolom sesuai ukuran layar; Daily dan Achievements mengikuti sistem grid.
- Character Detail, Progression, Prompt, dan Profile memakai pembagian panel sesuai fungsi. Identitas/equipment tampil bersama emblem atau artwork yang tersedia.
- Hasil karakter memakai strip kartu horizontal. Geser kiri/kanan untuk melihat kartu berikutnya. Keep/Discard tetap berada pada setiap kartu, dengan status keputusan dan konfirmasi Discard. Reveal all, Play sequence, Continue tersedia di bagian bawah.
- Halaman panjang dan kartu pada layar pendek/font besar tetap bisa digulir untuk menjangkau semua kontrol.
- Seluruh teks UI tetap English. Dialog konfirmasi menggunakan tema gelap dan monospace; bukan ilustrasi dialog bitmap yang meniru referensi secara persis.

## Yang tetap tersedia

Keep/Discard, Pending, penghapusan massal dengan perlindungan nama/favorite, progression, artwork, account, shop, daily, history, codex, achievements, serta pengaturan musik/efek. SQL dan engine karakter identik dengan versi sebelumnya.

Perbaikan gambar digabungkan: antrean gambar lokal terpisah, semua 45 PNG emblem/branding disertakan, pemeriksaan source dan APK pada workflow, Settings > Check bundled images.

Aset karakter modular, ilustrasi slot equipment baru, dan font bitmap khusus belum dibuat. Referensi digunakan untuk arah panel/warna/tata letak, bukan menjanjikan karakter sprite yang belum tersedia. Emblem dan artwork tetap visual karakter.

## Pemeriksaan

Lokal lulus: parsing sintaks 10 file Java; XML manifest/theme; struktur workflow; 45 gambar source; 100 fixture Legacy beserta prompt; 500 hasil V2. Backend SQL dan engine telah dibandingkan dengan versi sebelumnya dan tidak berubah.

Belum terverifikasi lokal: kompilasi Android lengkap/lint, emulator, tata letak pada perangkat, keyboard landscape, font besar, dan runtime SQL. Workflow tetap menjadi gate build. Setelah memasang, periksa layar Home, Collection, detail/progression, input login/rename, preview efek, dan kartu hasil. Jika ada panel terpotong, kirim screenshot beserta model HP/ukuran font agar dapat diperbaiki berdasarkan tampilan nyata.
