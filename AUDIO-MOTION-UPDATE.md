# Genesis Android V16.5 — Audio & Motion

Paket ini adalah PATCH untuk project native V16.4.5 yang sudah berjalan.
Versi aplikasi: 16.5-native.1 / versionCode 3. Visible UI tetap English.

## Cara memasang lewat GitHub

1. Ekstrak Genesis-Android-V16.5-Audio-Motion-Patch.zip di komputer.
2. Buka halaman Code repository genesis-android, pada root (tempat app, backend, tests, dan tools).
3. Pilih Add file → Upload files. Tarik folder app, tests, tools, dan file AUDIO-MOTION-UPDATE.md dari hasil ekstraksi ke area upload. Browser desktop akan mempertahankan struktur folder. Jangan mengunggah hanya ZIP atau folder pembungkus tambahan.
4. Commit semua file dalam satu perubahan ke main. File bernama sama akan diperbarui; file lainnya tetap ada.
5. Buka Actions → Build Genesis Android, lalu tunggu run terbaru selesai. Jika tidak terpicu, gunakan Run workflow pada main.
6. Setelah build dan database-tests hijau, unduh artifact Genesis-Android-APK dari run terbaru, ekstrak, lalu pasang APK.

Jika memakai clone lokal, salin isi patch ke root clone dan pilih Replace untuk file yang sama, lalu commit dan push.
Jangan menghapus repository atau mengganti project dengan hanya isi patch: ini bukan source lengkap.
Supabase Variables, workflow, dan migrasi database tidak perlu diubah untuk update ini.

## Yang ditambahkan

- Musik ambient sintetis orisinal “Sanctum”, loop 32 detik.
- 10 cue suara summon unik, satu untuk setiap rarity.
- Flip card untuk summon: 10x memakai dua kolom kartu tertutup; ketuk kartu pilihan, gunakan Play reveal sequence, atau Reveal all.
- 1x summon langsung memainkan flip dan efek rarity.
- Race emblem dan rarity badge yang sudah ada tetap dipakai.
- Animasi train dengan aliran naik dan cincin EXP; upgrade dengan pancaran forge; evolution dengan orbit dan sigil.
- Hasil progression menampilkan level/equipment/evolution dan CP sebelum → sesudah berdasarkan data server yang telah dimuat ulang.
- Background music ON/OFF, Sound effects ON/OFF, dua pengatur volume terpisah.
- Reduce motion (juga menghormati animator sistem yang dinonaktifkan), Skip animation, dan preview semua rarity di Settings.
- Audio mengikuti lifecycle Activity dan audio focus; masuk background menghentikan efek serta menjeda musik. Keluar dialog membatalkan animasi dan efek yang masih berjalan.

## Desain rarity

| Rarity | Warna / animasi | Suara |
| --- | --- | --- |
| Common | Silver, cincin berkembang | Satu nada chime |
| Uncommon | Green, enam daun berputar | Dua nada bell |
| Rare | Blue, tiga gelombang melingkar | Tiga nada dengan harmonik |
| Special Rare | Teal, busur orbit dan diamond | Empat nada bergetar lembut |
| Super Rare | Indigo, dua diamond berlawanan | Tiga nada chime tinggi |
| Super Special Rare | Pink, hexagon dan enam titik orbit | Empat nada bell |
| Epic | Violet, dua segitiga dan lingkaran pusat | Lima nada harmonik dengan bass |
| Legendary | Gold, dua belas sinar dan octagon | Fanfare sintetis lima nada |
| Mythical | Rose, tiga orbit dan pentagon | Enam nada berlapis |
| Primordial | Pearl, lingkaran ganda dan sigil sepuluh sisi | Tujuh nada dengan bass rendah |

Efek berupa native Canvas dan property animation, bukan video atau WebView.
Tidak ada animasi yang menentukan rarity, menambah biaya, atau mengirim ulang summon. Hasil summon disimpan sebelum animasi dimulai; menekan Skip/Continue tidak menghilangkan karakter.

## Isi patch

- app/build.gradle: versi aplikasi baru, konfigurasi Supabase tetap.
- app/src/main/java/com/genesis/gacha/MainActivity.java: integrasi audio, presentation, settings, lifecycle.
- app/src/main/java/com/genesis/gacha/GenesisAudio.java: MediaPlayer dan SoundPool.
- app/src/main/java/com/genesis/gacha/GenesisPresentation.java: dialog kartu dan animasi native.
- app/src/main/assets/audio/*.wav: 15 asset audio, sekitar 2.46 MB total.
- tools/generate-audio.py: sumber komposisi audio, Python + numpy; tidak perlu dijalankan saat build karena WAV sudah tersedia.
- CharacterEngineTest.java dan tests/native-backend.sql: menyertakan perbaikan test sebelumnya agar tidak kembali ke versi yang error.

Seluruh audio disintesis khusus untuk update ini tanpa sampel atau rekaman musik pihak ketiga.

## Validasi dan batasan

Pemeriksaan lokal: sintaks Java; 15 WAV unik, tidak kosong, tanpa clipping, mono PCM 22,050 Hz; semua efek di bawah 1 MB decoded; keberadaan asset emblem dan badge; integritas ZIP; perbaikan test sebelumnya dipertahankan.
Build Android, lint, pengujian emulator, playback audio nyata, dan database CI belum dijalankan di lingkungan pembuat patch karena Android SDK/Gradle/PostgreSQL tidak tersedia. Workflow repository tetap menjadi pemeriksaan build berikutnya.

Sesudah APK terpasang:

1. Settings → Preview rarity effects: coba semua 10 pilihan.
2. Uji volume musik dan efek secara terpisah, OFF, serta Reduce motion.
3. Coba summon 10x: kartu manual, sequence, skip di tengah flip, dan Continue sebelum semua kartu terbuka. Cocokkan hasil di Collection.
4. Uji train, upgrade weapon/equipment, dan evolution pada karakter yang memenuhi syarat; pastikan dialog cocok dengan data progression.
5. Saat musik/animasi berjalan, tekan Home atau kunci layar. Audio harus berhenti. Buka kembali dan pastikan hasil tetap tersedia.
6. Kegagalan request tidak boleh memunculkan animasi berhasil. Preview tidak membuat karakter atau mengubah saldo.

Saat Activity dibuat ulang oleh Android, dialog animasi tidak dipulihkan; hasil tetap tersedia dari akun melalui Collection/Progression.
