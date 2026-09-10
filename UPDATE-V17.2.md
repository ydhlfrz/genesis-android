# Genesis V17.2 — Collection cleanup and inline decisions

Patch ini dipasang di atas V17.1 yang sudah bekerja. Source patch, bukan APK.

## Pemasangan
1. Ekstrak ZIP dan upload isinya ke root repository yang sama. Timpa file bernama sama, termasuk .github/workflows/android.yml.
2. Tunggu database-tests dan build pada commit terbaru berhasil.
3. Backup database, kemudian jalankan hanya backend/supabase-v17_2-cleanup.sql di Supabase SQL Editor. V17 dan V17.1 harus sudah terpasang. Jangan menjalankan tests di produksi.
4. Pasang APK terbaru dari workflow.

## Hapus massal
Buka Collection > Clean up unnamed characters. Daftar mencakup karakter aktif tanpa custom name dan bukan favorite. Seluruh kandidat sudah tercentang; hapus centang pada karakter yang ingin dipertahankan. Tekan Review deletion, periksa jumlah, lalu konfirmasi Discard.

Server melindungi karakter favorit dan bernama, termasuk bila statusnya berubah sejak daftar dibuka. Jika satu kandidat tidak lagi memenuhi syarat, seluruh operasi dibatalkan; refresh lalu periksa daftar lagi. Hanya ID yang dikonfirmasi diproses, tidak termasuk summon baru yang muncul kemudian. Maksimum satu batch 1000 karakter; 466 karakter dapat ditangani sekaligus bila memenuhi syarat. Rarity tinggi tetap termasuk bila tanpa nama dan bukan favorite, jadi periksa daftar sebelum konfirmasi.

Ini mengeluarkan karakter dari Collection secara permanen dalam aplikasi, menggunakan penanda archived/discarded. History, Codex, dan catatan transaksi tetap disimpan. Tidak ada refund dan tidak mengubah pity. Migrasi SQL sendiri tidak menghapus karakter mana pun.

## Keep / Discard langsung di hasil
Tombol berada di bawah masing-masing kartu pada layar hasil 1x maupun 10x. Buka/reveal kartu terlebih dahulu, lalu pilih Keep atau Discard. Keep menyimpan tanpa pindah layar; status berubah menjadi Kept. Discard meminta konfirmasi lalu menampilkan Discarded. Penamaan tetap di detail Collection. Karakter yang belum diputuskan tetap Pending jika layar ditutup.

Jika jaringan gagal, ulangi pilihan yang sama. Server menerima retry tanpa menggandakan tindakan. Halaman Review pending tetap tersedia untuk melanjutkan keputusan setelah membuka aplikasi kembali.

## Validasi
Parsing sintaks sembilan file Java dan struktur workflow berhasil lokal. Android compile/lint, PostgreSQL runtime, dan tampilan pada perangkat belum dijalankan lokal. Workflow menambahkan pengujian perlindungan favorite/nama, pembatalan batch, retry, akses antar-akun, serta saldo tetap. Kedua job harus berhasil sebelum migrasi produksi.
