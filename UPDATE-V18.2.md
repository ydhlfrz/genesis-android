# Genesis V18.2 — Living UI

Source Android lengkap untuk memperbarui V18.1 yang sudah bekerja. Pembaruan ini berfokus pada tampilan dan navigasi. Tidak ada perubahan engine, peluang, biaya, reward, atau SQL.

## Pemasangan
1. Ekstrak ZIP, lalu upload isi folder genesis-android-main ke root repository yang sama. Timpa file bernama sama; sertakan .github/workflows/android.yml, app/src dan tools.
2. Jalankan workflow pada commit terbaru. Setelah database-tests dan build berhasil, pasang APK dari artifact sebagai pembaruan aplikasi yang sama.
3. Tidak perlu menjalankan SQL baru atau mengubah variable Supabase.

## Navigasi dan ukuran
- Sidebar tidak ditampilkan pada halaman mana pun. Tombol Back di kiri atas kembali ke Lobby.
- Semua tujuan utama tersedia melalui Lobby. Pembukaan detail karakter dari Collection tetap tersedia sebagai bagian pengelolaan karakter.
- Header, teks, padding dan tombol lebih ringkas; area sentuh utama tetap sekitar 44dp.
- Collection/Codex mengikuti ruang layar penuh dengan grid adaptif hingga lima kolom.
- Gaya panel/tombol memakai bevel logam, highlight dan respons tekan, terinspirasi arah visual referensi tetapi desainnya asli.

## Gerakan ambient
- Lobby memiliki partikel cahaya yang bergerak dan cahaya landasan yang berubah lembut.
- Sanctum mempertahankan lingkaran ritual di belakang emblem dan gerakan idle ringan setelah reveal.
- Tombol memberikan respons tekan singkat.
- Reduce motion menonaktifkan gerakan tambahan. Animasi dihentikan saat aplikasi masuk latar belakang atau panel ditinggalkan. Gerakan karakter bukan animasi kerangka 3D; visual karakter tetap artwork/emblem yang tersedia.

## Badge baru
Lima desain native baru: Common 3 bintang, Rare 4, Super Rare 5, Epic 6, Mythic 7. Badge memiliki nama, bintang, warna tier, logam, ornamen dan permata. Gambar dirender sebagai vector oleh aplikasi; tidak perlu unduhan, font baru, atau PNG tambahan. Badge Legacy tetap memakai aset lamanya.

Buka Settings > Preview new rarity badges untuk memeriksa kelima desain. Badge baru juga terhubung ke tampilan karakter yang memakai badge V2 dan panel Sanctum.

## Perbaikan Prompt
Prompt tidak lagi diletakkan di panel dengan scroll bertumpuk. Seluruh konten memakai satu ScrollView utama tanpa tinggi teks tetap. Tombol Copy prompt dan Upload artwork berada di atas teks. Bagian akhir ditandai End of prompt agar bisa diperiksa pada perangkat. Pemilihan karakter, salin prompt dan upload artwork tetap tersedia.

## Validasi dan batasan
Lokal: parsing sintaks 13 file Java, XML/workflow, pemeriksaan 45 PNG, pengecekan struktur Prompt/sidebar berhasil. Engine dan semua SQL dibandingkan dengan V18.1 dan tetap identik.
Belum dijalankan lokal: kompilasi Android/lint, emulator, runtime database, scroll sentuh dan tata letak pada perangkat. Workflow dan pemeriksaan APK di HP diperlukan sebelum menyatakan tampilan sudah sesuai. Periksa Back ke Lobby, ujung Prompt, kelima badge, dan Reduce motion; kirim screenshot jika ada bagian terpotong.
