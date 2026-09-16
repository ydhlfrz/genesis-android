# Combat Polish 0.2 — patch untuk Practice yang sudah berjalan

Upload hanya PracticeActivity.java dan PracticeCombat.java ke:
`app/src/main/java/com/genesis/gacha/`

Ganti file lama dengan nama persis tanpa (1). Gunakan workflow commit terakhir yang memuat kedua file, lalu install APK dan buka Adventure · Practice. Tidak ada perubahan SQL, manifest, MainActivity atau asset. Jika memakai ZIP, ekstrak dulu; jangan hanya upload ZIP ke repository.

Perubahan:
- Buffer Attack 120 ms agar tap menjelang akhir recovery tidak terbuang. Tap terlalu awal kedaluwarsa; pause/cancel membuang input tertunda.
- Collision pemain/boss dengan radius 0.3/0.65, termasuk saat dash dan charge. Resolusi sederhana dapat mendorong posisi di dekat dinding.
- Efek tebasan hanya tampil saat hit aktif; angka damage terbaru per pihak tampil 0.65 detik.
- Nada Android sederhana untuk hit dan dodge; SFX On/Off, volume media, berhenti saat pause/background. Ini bukan rekaman pedang final. Setting suara berlaku selama Activity hidup.
- Charge mengunci arah pada 0.35 detik terakhir telegraph; cue teks menunjukkan serangan atau kesempatan menyerang ketika boss recovery.
- Hasil latihan menampilkan waktu aktif, damage aktual diberikan/diterima tanpa overkill, dan dodge evasions. Evasion dihitung sekali per serangan ketika jendela kebal mengabaikan hit; bukan jumlah penekanan Dodge. Serangan yang masih aktif bisa mengenai pemain setelah kebal habis.
- Retry mereset statistik dan input. Tidak ada reward atau perubahan akun.

Validasi: 22 tes combat lama dan 10 tes polish berhasil dijalankan ulang. Dua kelas dikompilasi terhadap API Android 15 dari Robolectric; bukan build APK Gradle/lint penuh. Tampilan, sound dan multi-touch masih perlu diuji di HP. Source tes dalam ZIP opsional; tidak diperlukan untuk memasang patch.

Cek di HP: gerak sambil Attack, tap menjelang recovery selesai, collision dekat dinding, arah charge terkunci, SFX Off, pause/resume melalui Home, ringkasan hasil dan reset setelah Retry. Visual tetap placeholder.
