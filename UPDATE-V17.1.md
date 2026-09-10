# Genesis V17.1 — Keep / Discard

Patch untuk V17 yang sudah berhasil memakai Wallet Hotfix. Ini source patch, bukan APK.

## Pasang

1. Ekstrak Genesis-V17.1-Keep-Discard-Patch.zip. Upload isinya ke root repository yang sekarang digunakan dan timpa file bernama sama. Sertakan .github/workflows/android.yml. Jangan hapus repository dan jangan mengganti variable Supabase.
2. Tunggu database-tests dan build pada commit terbaru berhasil. Workflow menguji migrasi dua kali dan alur pemilihan pada database sementara, bukan database Supabase produksi.
3. Siapkan APK baru dari workflow. Setelah backup database, jalankan hanya backend/supabase-v17_1-selection.sql di Supabase SQL Editor. V17 beserta hotfix harus sudah terpasang. Jangan menjalankan file tests di database produksi.
4. Pasang APK V17.1. Setelah migrasi, hasil baru berada di Pending; gunakan aplikasi baru untuk menentukan pilihannya. Aplikasi lama tidak mempunyai kontrol review.

## Perilaku

- Setelah animasi selesai, tekan Continue. Halaman Keep or discard sudah tersedia di belakang animasi.
- Keep memasukkan karakter ke Collection; Open character membuka detail untuk memberi nama, favorite, progression, dan artwork.
- Discard meminta konfirmasi dan mengeluarkan karakter dari permainan. Tidak ada tombol pemulihan.
- Hasil 10x dipilih per karakter, sehingga tidak perlu menyimpan seluruh hasil. Tidak ada penghapusan massal otomatis.
- Hasil yang belum diputuskan disimpan di server sebagai Pending, terpisah dari Collection. Buka Review pending characters dari Home atau Collection setelah aplikasi dibuka lagi.
- Pending tidak dapat dilatih, diberi nama, atau di-upgrade sebelum dipilih Keep.
- Riwayat summon, penemuan Codex, dan catatan transaksi tetap disimpan. Discard memakai penghapusan logis (record server ditandai discarded/archived), bukan menghapus seluruh rekam database.
- Biaya, pity, serta progres summon tidak dibatalkan ketika Discard. Achievement koleksi mengikuti karakter aktif; penemuan historis tetap ada.
- Karakter yang sudah ada sebelum migrasi tidak berubah. Untuk merapikan koleksi lama, gunakan Archive character pada detail karakter; patch ini tidak menyediakan bulk cleanup.

## Validasi dan batasan

Lokal: parsing sintaks sembilan file Java, struktur workflow, 100 fixture Legacy, dan 500 hasil engine baru berhasil. Engine karakter tidak diubah.
GitHub: pengujian SQL mencakup pending 10x, Keep/Discard, retry, larangan membalik keputusan, penamaan dan latihan setelah Keep, larangan latihan sebelum Keep, saldo/pity tetap, dan akses antar-akun. Migrasi dijalankan dua kali untuk memeriksa rerun.
Belum dijalankan di lingkungan lokal: Android compile/lint, PostgreSQL runtime, tampilan perangkat, atau transaksi paralel. Kedua job workflow harus berhasil sebelum SQL produksi diterapkan.
