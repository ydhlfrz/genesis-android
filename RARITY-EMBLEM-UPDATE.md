# Genesis V16.5.2 — Rarity & Emblem

Patch kumulatif untuk project native V16.4.5 / V16.5 / V16.5.1 yang sudah berjalan.
versionCode 5, versionName 16.5.2-native.1.

## Pemasangan

Ekstrak ZIP. Upload folder app, tools, tests, dan RARITY-EMBLEM-UPDATE.md ke root repository yang sama; pertahankan struktur folder. Commit semua file ke main dalam satu perubahan, lalu tunggu workflow terbaru. Setelah build dan database-tests hijau, unduh artifact Genesis-Android-APK dan instal APK baru.
Tidak perlu menghapus repository. Jangan menjadikan isi patch sebagai repository baru karena source dasar tetap diperlukan. Tidak ada perubahan Supabase Variables atau migrasi database.

## Reveal baru

Emblem sekarang memiliki komposisi tiga lapisan: aura di belakang, artwork asli di tengah, dan partikel highlight di tepi. Emblem masuk dari skala kecil, sedikit melampaui ukuran akhir, lalu menetap. Badge rarity masuk dengan gerakan tersendiri. Efek memiliki durasi terbatas dan berhenti pada hasil statis.

| Rarity | Desain |
| --- | --- |
| Common | Halo perak dan busur cahaya |
| Uncommon | Kelopak hijau dan partikel |
| Rare | Delapan pecahan kristal biru |
| Special Rare | Tiga busur energi teal |
| Super Rare | Pecahan indigo dan orbit ganda |
| Super Special Rare | Orbit berlapis dan kristal pink |
| Epic | Fragmen rune berputar dan pecahan ungu |
| Legendary | Corona emas dan dua belas pancaran cahaya |
| Mythical | Pita aurora berlapis dan pecahan bercahaya |
| Primordial | Horizon gerhana, orbit, dan partikel bintang |

Di atas desain rarity, race family menambahkan motif:

- Mortal: busur heraldik.
- Fae: daun bercahaya.
- Beast: garis sapuan di sisi emblem.
- Undead: aliran kabut hijau.
- Celestial: kipas sinar biru-putih.
- Infernal: bara jingga naik.
- Divine: sinar emas.
- Draconic: bara amber.
- Eldritch: aliran kabut violet.
- Ancient: lempeng simbol berputar.
- Elemental: gelombang melingkar.
- Spirit: aliran kabut biru lembut.
- Construct: lempeng geometris.
- Special Bloodline: bara rose.

Ini adalah animasi di sekitar emblem PNG yang sudah ada, bukan animasi anggota tubuh di dalam gambar. Hidden race menggunakan base race emblem seperti sebelumnya, dengan family dari data karakter.

Area emblem dan kartu diperbesar untuk memberi ruang efek. Informasi teks berada di luar area partikel. Animasi ini dipakai dalam summon/reveal dan progression; koleksi tetap statis untuk menghindari banyak animasi aktif sekaligus.

## Preview

Settings → Preview rarity effects → pilih rarity → pilih race family.
Tersedia 10 rarity × 14 family untuk preview visual. Preview tidak membuat karakter atau mengubah saldo; kombinasi preview tidak menyatakan kombinasi tersebut dapat diperoleh melalui summon.

## Kontrol

Skip dan Continue tetap tersedia. Reduce motion menampilkan hasil statis dengan aura ringan. Membuka kartu manual dilakukan satu per satu agar efek dan audio tidak bertumpuk; Play reveal sequence tetap menuntaskan kartu sisanya. Background/close membatalkan animator dan mengembalikan emblem/badge ke posisi akhir.
Musik, suara rarity, dan Sanctum Ritual dari patch sebelumnya tetap disertakan.

## Validasi

Diperiksa lokal: sintaks Java, pemetaan 14 family terhadap catalog, keberadaan 14 contoh race emblem, seluruh file audio, dan integritas ZIP.
Belum diuji: build APK, lint Android, tampilan aktual, dan performa di HP; Android SDK tidak tersedia di lingkungan pembuat patch. Gunakan workflow dan preview di HP untuk validasi berikutnya.

Uji preview Epic, Legendary, Mythical, Primordial dengan family yang berbeda; lalu coba 10x manual/sequence/skip, Reduce motion, dan background saat flip. Pastikan emblem, badge, dan teks tetap terbaca setelah Skip.
