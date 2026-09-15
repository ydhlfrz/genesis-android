# Rancangan distribusi aset Genesis

Status: rancangan untuk tahap selanjutnya, bukan downloader aktif. Semua aset versi ini masih dibundel di APK.

## Pembagian konten
- Core di APK: logo, loading, navigasi, badge, unknown dan placeholder. Selalu bisa membuka UI tanpa mengunduh paket tambahan; akun/gameplay tetap online.
- Character packs: dipisah berdasarkan keluarga rig/body yang kompatibel. Body dan animasi bersama tidak diduplikasi untuk setiap rarity. Pakai dependency pack untuk shared armor/weapon.
- Adventure packs: per chapter, berisi arena, musuh, boss dan audio yang diperlukan.
- Voice: opsional per bahasa. Musik dibagi berdasarkan area.
- Master: file produksi terpisah dari repository runtime dan paket distribusi.

## Manifest dan kompatibilitas
Setiap paket memiliki pack_id stabil, version immutable, min_app_version, dependencies, download_bytes, unpacked_bytes, HTTPS URL dari domain yang diizinkan, sha256 arsip dan daftar path/file/digest. Manifest rilis ditandatangani; app memverifikasi dengan public key tertanam. Hash saja melindungi integritas, bukan identitas penerbit. Tidak ada kode executable/script remote di paket.
Aplikasi hanya memilih paket kompatibel. Account state, character seed dan balance tidak berada dalam manifest aset.

## Alur instalasi paket
Not installed → meminta unduhan dengan ukuran terlihat → downloading ke berkas sementara → verifikasi hash → ekstraksi ke direktori staging → verifikasi file → pergantian pointer versi aktif secara atomik.
Periksa ruang kosong mencakup versi lama, arsip dan hasil ekstraksi. Tolak path traversal, symlink, ukuran ekstraksi berlebihan, jumlah file berlebihan dan checksum berbeda. Jangan hapus versi aktif sebelum pengganti lolos.
Unduhan berlanjut hanya bila server mendukung Range dan identitas konten/ETag cocok; jika tidak mulai ulang berkas sementara. Pembatalan dan kegagalan mempertahankan versi aktif. Setelah proses mati, baca state unduhan tersimpan dan verifikasi ulang.

## UI unduhan
Tampilkan jumlah byte/progres nyata, pilihan Wi-Fi saja, Pause/Resume/Cancel dan Retry. Jangan tampilkan persentase palsu. Pemain dapat mengelola paket opsional; dependency yang sedang digunakan tidak boleh dihapus. Placeholder lokal digunakan sampai paket siap; masuk level hanya setelah aset wajib lengkap.

## Distribusi dan operasi
Untuk APK langsung: object storage dan CDN melalui HTTPS; biaya dihitung dari ukuran paket x jumlah unduhan, update dan retry. Penyedia belum dipilih dan belum ada biaya/layanan yang diaktifkan.
Jika memakai Google Play: evaluasi Play Asset Delivery pada tahap penerbitan, berdasarkan distribusi dan ketentuan yang berlaku saat itu.
Rilis aset memakai versi immutable, rollout terbatas, cache headers yang sesuai dan kemampuan kembali ke versi kompatibel. Perubahan aset biasa tidak boleh mengubah ekonomi server.

## Gate sebelum aktivasi
Uji jaringan putus di setiap tahap, storage penuh, checksum salah, arsip berbahaya, pembatalan, proses mati, update saat paket lama aktif, dependensi hilang, font besar dan aksesibilitas UI progres. Buat satu paket uji kecil terlebih dahulu sebelum produksi seluruh race.
