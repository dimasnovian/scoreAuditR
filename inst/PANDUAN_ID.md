# Panduan singkat scoreAuditR versi 0.2.0

Pasang arsip sumber dengan install.packages("scoreAuditR_0.2.0.tar.gz",
repos=NULL,type="source"). Buka library(scoreAuditR), kemudian gunakan
simulate_measurement() dan audit_measurement() untuk contoh pengukuran.
Manual lengkap tersedia pada inst/doc/manual.md dan help(package="scoreAuditR").

Untuk antarmuka, pasang shiny dan jalankan scoreAuditR::run_app(). Tab
Measurement scoring memakai data simulasi berlabel. Tab panel menerima CSV
World Happiness Report tahunan. Data negara bukan respons butir individual.
Laporkan cakupan penskoran bersama galat; RMSE theta tidak sebanding dengan
RMSE rerata butir. Jangan menganggap baris yang tidak diberi skor telah pulih.

Setelah memperbarui pemasangan pada RStudio, pilih Session > Restart R agar
namespace lama tidak tetap aktif, lalu muat paket lagi. Versi yang diuji adalah
0.2.0. Program memerlukan R yang sudah terpasang, bukan executable mandiri.

Hasil eksperimen dan naskah ringkas berada pada kiriman pendamping. Verifikasi
Word dan metadata seluruh penulis masih diperlukan sebelum pengajuan.
