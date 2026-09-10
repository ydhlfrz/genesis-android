# Genesis V18.1 — Lobby and embedded Sanctum

Source Android lengkap, berdasarkan V18. Memuat perbaikan gambar sebelumnya. Tidak ada migrasi SQL baru dan tidak mengubah engine, koleksi, atau ekonomi.

## Pemasangan
1. Ekstrak ZIP. Upload isi folder genesis-android-main ke root repository yang sama; timpa file bernama sama dan sertakan .github/workflows/android.yml, app/src, serta tools.
2. Pertahankan variable Supabase yang sudah bekerja.
3. Tunggu database-tests dan build pada commit terbaru berhasil. Pasang APK terbaru dari artifact workflow sebagai pembaruan aplikasi yang sama.
4. Database V17.2 yang sudah berjalan tetap digunakan. Tidak perlu menjalankan SQL untuk pembaruan ini.

## Startup dan lobby
- Saat inisialisasi, aplikasi menampilkan loading screen dengan spinner dan latar aula kastel. Tidak ada waktu tunggu buatan; durasinya mengikuti pekerjaan yang dilakukan.
- Jika belum memiliki sesi login, loading dilanjutkan ke Login. Setelah login berhasil, masuk Lobby. Sesi valid tetap dapat melanjutkan tanpa mengetik password lagi.
- Permintaan jaringan menampilkan overlay Genesis connecting dengan spinner dan memblokir ketukan ganda. Error menutup overlay dan memberikan pesan untuk retry.
- Lobby mengikuti susunan sketsa: Profile/Settings di kiri atas, logo di tengah atas, saldo GP/Essence/Tickets/Tokens di kanan atas, menu harian di kiri, karakter di tengah, Collection/Progression di bawah, Enter Sanctum di kanan bawah.
- Choose lobby character mengambil karakter dari Collection. Pilihan tampilan disimpan per akun di perangkat sebagai preferensi UI. Jika pilihan hilang dari Collection, aplikasi memakai favorit/karakter lain yang tersedia; jika koleksi kosong, memakai logo.
- Karakter memakai artwork yang sudah tersedia atau emblem. Aset karakter modular baru belum ditambahkan.
- Background adalah ilustrasi aula kastel native dengan pilar, panji, cahaya obor, menara dan bulan. Tidak memerlukan unduhan atau gambar buatan AI.

## Sanctum
- Animasi hasil berlangsung langsung di panel kiri, bukan layar/dialog reveal terpisah.
- Keep dan Discard berada pada bar tetap di bawah panel. Discard tetap meminta konfirmasi.
- Hasil 10x ditinjau per karakter dengan panah kiri/kanan dan nomor hasil. Keduanya berada di panel yang sama.
- Keputusan yang berhasil ditampilkan sebagai Kept atau Discarded; tidak mengalihkan halaman. Untuk menamai karakter yang disimpan, buka detail Collection.
- Hasil yang belum diputuskan disimpan di server. Pending pada Lobby/Sanctum dapat membukanya lagi setelah aplikasi ditutup.
- Reduce motion menampilkan hasil tanpa ritual reveal. Animasi dihentikan ketika panel ditinggalkan atau aplikasi masuk latar belakang.

## Ukuran UI
Header, sidebar, teks dan jarak antarkontrol lebih rapat. Tombol keputusan tetap sekitar 44dp. Pada layar pendek/font besar, konten panjang tetap dapat digulir agar tidak kehilangan kontrol.

## Validasi
Lulus lokal: parsing sintaks 12 file Java, pemeriksaan 45 gambar, XML/workflow, 100 fixture Legacy dan 500 hasil V2. SQL dan engine sama dengan versi sebelumnya.
Belum dijalankan lokal: kompilasi Android/lint, emulator, runtime SQL, tampilan perangkat dan perilaku animasi saat lifecycle nyata. Workflow harus berhasil sebelum APK digunakan untuk penilaian UI.

Setelah pemasangan, periksa startup tanpa login, login ke lobby, memilih karakter lobby, Settings > Preview rarity effects, penempatan kontrol Sanctum, Keep/Discard, serta membuka kembali Pending setelah aplikasi ditutup. Kirim screenshot jika layout tidak pas di ukuran layar perangkatmu.
