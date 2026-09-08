# Genesis 16.5.1 — Sanctum Ritual

Patch kumulatif untuk Genesis native V16.4.5 atau V16.5 yang sudah berjalan.
versionCode 4 / versionName 16.5.1-native.1.

## Pasang ke repository yang sama

1. Ekstrak Genesis-Android-V16.5.1-Sanctum-Ritual-Patch.zip.
2. Pada root repository (tempat folder app/backend/tests), pilih Add file → Upload files.
3. Tarik folder app, tools, tests dan SANCTUM-RITUAL-UPDATE.md dari hasil ekstraksi ke area upload. Pertahankan seluruh struktur folder. Jangan upload ZIP saja atau folder pembungkus tambahan.
4. Commit ke main. Tunggu workflow terbaru: build dan database-tests harus hijau.
5. Unduh artifact Genesis-Android-APK terbaru, ekstrak, lalu instal APK.

Tidak perlu menghapus repository. Paket ini bukan source project lengkap. Supabase Variables dan database tidak perlu diubah.

## Perubahan

- Idle Sanctum mengganti gambar mark statis dengan pentagram lima titik dalam lingkaran berlapis, simbol fantasi abstrak, halo ungu-emas, partikel naik, dan putaran berlawanan yang pelan.
- Pentagram digambar sebagai bintang yang saling bersilangan, bukan pentagon.
- Native Canvas dengan ukuran yang mengikuti layar. Redraw idle dibatasi kira-kira 30 kali per detik; tidak menggunakan bitmap blur baru setiap frame.
- Berhenti menggambar ulang saat view dilepas, Activity kehilangan fokus/masuk background, Reduce motion aktif, atau animasi sistem dinonaktifkan. Dalam mode minim gerak, ritual tetap terlihat sebagai gambar statis.
- Summon dan progression memakai presentasi fullscreen dengan tombol Skip dan Continue tetap di bagian bawah.
- Pembuka ritual 1.6 detik mengumpulkan energi, disertai suara rise baru, kemudian beralih ke kartu hasil.
- Kartu muncul bertahap, memiliki bayangan, terangkat saat flip, dan mendapat border sesuai rarity setelah reveal. Informasi karakter masuk bertahap setelah flip.
- 10x: tap kartu manual, Play reveal sequence, Reveal all; tombol Skip juga bisa dipakai selama pembuka ritual.
- Musik mengecil selama layar hasil aktif dan kembali ke volume pilihan saat layar ditutup.
- Background dekoratif ritual untuk progression; pola efek train/upgrade/evolution V16.5 dipertahankan.
- Semua audio dan perbaikan test dari patch sebelumnya ikut disertakan.

Race emblem, rarity badge, dan hasil server tetap digunakan. Tidak ada perubahan biaya, odds, RPC, atau kepemilikan. Menutup/skip animasi tidak menjalankan ulang summon. Preview rarity effects tidak mengubah akun.

## Validasi

Dilakukan lokal: pemeriksaan sintaks empat file Java; validasi 16 WAV (PCM mono 22050 Hz, unik, tidak kosong, tidak clipping); batas decoded SoundPool di bawah 1 MB per efek; pengecekan integritas ZIP dan referensi aset.
Belum dilakukan: build Android, lint, pengukuran frame rate di HP, dan pengujian visual di emulator/perangkat. Lingkungan pembuat patch tidak memiliki Android SDK. Ini adalah kandidat update untuk diuji melalui workflow dan HP, bukan klaim kualitas visual yang sudah diverifikasi di perangkat.

## Uji di HP

1. Home: pastikan pentagram terlihat dan berputar pelan. Ganti halaman dan kembali.
2. Aktifkan Reduce motion; ritual harus statis. Nonaktifkan untuk mengembalikan gerakan.
3. Settings → Preview rarity effects: lihat transisi pembuka, flip, dan border.
4. Coba 10x dan Skip saat pembuka, saat kartu masuk, serta di tengah flip. Semua kartu harus tetap terbaca dan hasil tersedia di Collection.
5. Coba menutup dengan Continue/Back sebelum selesai; pastikan tidak ada audio yang tersangkut.
6. Home/lock screen selama animasi: audio berhenti dan hasil tetap tersimpan; kembali ke aplikasi.
7. Pastikan kontrol bawah dapat disentuh pada HP yang dipakai dan kartu tetap terbaca.

Dialog animasi tidak dipulihkan jika Android membuat ulang Activity; hasil dibaca kembali dari server.

## Berkas

MainActivity.java, GenesisAudio.java, GenesisPresentation.java, SanctumRitualView.java,
app/build.gradle, 16 WAV di app/src/main/assets/audio, tools/generate-audio.py,
CharacterEngineTest.java dan tests/native-backend.sql (perbaikan sebelumnya).
Script audio disertakan untuk reproduksi, tidak perlu dijalankan untuk build APK.
