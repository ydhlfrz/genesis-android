# Genesis — Adventure Practice prototype 0.1

Source patch untuk V18.9 dengan progression dan transaction patch sebelumnya. Bukan APK; nomor versi tetap. Visual menggunakan bentuk sederhana yang digambar langsung, bukan sprite final atau asset tambahan.

## Upload lewat HP: empat file aplikasi

Upload tiga file ini bersama ke `app/src/main/java/com/genesis/gacha/`:

- MainActivity.java (ganti; termasuk perbaikan progression/transaksi sebelumnya)
- PracticeActivity.java (baru)
- PracticeCombat.java (baru)

Lalu ganti `app/src/main/AndroidManifest.xml` dengan file yang disertakan. Nama harus persis tanpa `(1)` atau `(2)`. Jangan menghapus repository. Jangan upload ZIP saja ke repo: workflow membutuhkan file yang telah diekstrak. Bila commit Java memicu workflow sebelum manifest diupload, gunakan hasil workflow dari commit terakhir yang sudah memuat keempat file.

`tests/PracticeCombatTest.java` adalah test standalone opsional untuk developer; tidak diperlukan agar aplikasi berjalan. `INSTALL-PRACTICE.md` tidak perlu diupload untuk build. Tidak ada SQL, gambar atau image-manifest baru. Api.java dari patch transaksi terakhir tetap digunakan.

## Cara memainkan

Setelah workflow berhasil, install APK sebagai update dan login. Di Lobby tekan **Adventure · Practice** di area tombol Sanctum, kemudian **Play**.

- Drag joystick kiri bawah untuk bergerak. Arah gerak terakhir menentukan arah tebasan.
- Tahan Attack untuk mengulang basic slash. Lepas untuk berhenti.
- Tap Slash untuk skill, cooldown sekitar 5.8 detik.
- Tap Dodge untuk dash ke arah gerak/hadap, cooldown 2 detik. Kebal singkat di bagian tengah dash.
- Hindari lingkaran Ground Slam dan jalur Rune Charge sebelum tanda berubah menjadi serangan.
- Pause atau tombol Back membuka menu. Lobby keluar dari arena. Victory/Defeat menyediakan Retry.

Latihan memakai Human Warrior tetap dan Stone Warden. Tidak memilih atau mengubah karakter Collection. Tidak membagikan reward, tidak memotong saldo, dan tidak menyimpan hasil pertarungan. Setelah masuk arena, simulasi tidak membutuhkan request jaringan. Masuk aplikasi/Lobby masih mengikuti login online yang ada.

## Yang diterapkan

Simulasi 60 tick/detik terpisah dari render; gerak diagonal dinormalisasi; batas arena; basic/skill dengan fase windup, active dan recovery; hit satu kali per serangan; critical ber-seed tetap; dodge; dua pola boss dengan telegraph; HP; cooldown; simultaneous defeat rule; pause saat background; reset input saat pause dan Retry; insets layar Android.

Perbedaan dari desain lengkap: belum ada attack buffer 100ms, floating damage numbers, animasi sprite, musik khusus arena, dukungan karakter Collection, progression Adventure atau reward. Power/HP hero menggunakan nilai acuan tetap dari rancangan, belum adapter semua karakter. Tidak ada collider obstacle interior; arena terbuka dengan batas luar. Karakter dapat saling overlap. Sesi dapat diulang setelah Activity/process dibuat ulang; belum ada save/resume run.

## Validasi

- 22 pemeriksaan JVM lulus: rumus damage, diagonal, arena/dash bounds, pause timer dan input, satu hit per swing/slam, arah tebasan, cooldown, dodge immunity, telegraph, Victory/Defeat/Retry, simultaneous hit, swept collision dan pengelompokan tick.
- PracticeActivity dan PracticeCombat berhasil dikompilasi dengan javac API menggunakan library Android 15 dari Robolectric (bukan build APK Gradle). Ada catatan penggunaan API deprecated; tidak ada error kompilasi kedua kelas ini.
- Parser membaca tiga file Java patch; manifest valid XML; dua kelas practice tidak memakai API akun/wallet/persistence.
- Belum ada hasil APK/lint/emulator atau pemeriksaan visual/touch di perangkat. Workflow GitHub tetap diperlukan untuk build penuh dan resource linking. Aksesibilitas arena Canvas belum setara menu native; prototype ini memerlukan kontrol visual/touch.

## Checklist di HP

1. Adventure bisa dibuka dari Lobby; teks dan tiga action button terlihat tanpa terpotong.
2. Gerak sambil menahan Attack memakai dua jari; melepas joystick tidak menghentikan Attack yang masih ditahan.
3. Dodge dan skill hanya aktif saat cooldown selesai; hit sesuai arah.
4. Tanda boss terbaca, HP turun hanya saat terkena serangan; tidak ada hit saat menu pause terbuka.
5. Tekan Home lalu buka lagi: sesi tetap paused sampai Play ditekan.
6. Retry mengembalikan HP dan cooldown; kembali Lobby tidak mengubah saldo/Collection.
7. Coba kedua arah landscape. Jika device merekreasi Activity, latihan mulai dari awal tanpa perubahan akun.
