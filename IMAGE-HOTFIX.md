Genesis V17.2.1 — Image loading and packaging patch

Pasang di atas V17.2 yang bekerja:
1. Ekstrak ZIP dan upload SEMUA isinya ke root repository yang sama. Timpa file bernama sama, termasuk folder app/src/main/assets/media dan workflow.
2. Jalankan workflow commit terbaru. Pemeriksaan baru memverifikasi 45 gambar lokal di source dan di APK sebelum artifact dibagikan.
3. Setelah workflow berhasil, pasang APK terbaru. Tidak perlu SQL/migrasi atau perubahan variable Supabase.
4. Buka Settings > Check bundled images. Hasil normal: 45 bundled images decoded.
5. Periksa tampilan lewat Settings > Preview rarity effects; tidak perlu membuat karakter baru untuk mengetes gambar.

Perubahan: antrean gambar lokal dipisahkan dari unduhan artwork; gambar yang gagal didekode ditampilkan sebagai Image unavailable dan dicatat di log; fallback unknown untuk emblem yang tidak ditemukan. Logo dan 43 emblem disertakan ulang tanpa perubahan desain. Alur Keep/Discard dan database tidak berubah.

Status: 45 PNG source lolos pemeriksaan hash/format, Java lolos parsing sintaks. Build/lint Android dan tampilan pada perangkat belum dijalankan lokal. Akar masalah APK lama belum dikonfirmasi. Jika masih kosong, kirim hasil Check bundled images beserta screenshot Preview rarity effects.
