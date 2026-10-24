#!/usr/bin/env bash
# setup/day1.sh -- 1. günün verileri
#
# Bu dosya, 1. gün indireceğiniz dosyaların adreslerini listeler.
# Komutları RStudio'daki Terminal sekmesine birer birer kendiniz yazınız.
# Her komutun ne yaptığını birlikte konuşacağız.
# Zaman darsa dosyanın tamamını tek komutla çalıştırabilirsiniz:
#     bash setup/day1.sh
# Dosyaların kaynağı ve kullanım koşulları: data/README.md
set -euo pipefail
if [ ! -f bioinfo-workshop.Rproj ]; then
    echo "Bu komutları depo klasöründe çalıştırınız: cd /workspaces/bioinfo-workshop"
    exit 1
fi

base=https://github.com/onedimkurt/bioinfo-workshop/releases/download/data-v1
mkdir -p data

# 1. Örnek (sample) tablosu: sekiz örnek, hücre hattı ve tedavi (dex) bilgisi
curl -L -o data/airway_samples.csv $base/airway_samples.csv

# 2. Okumalar (reads): iki örnekten rastgele seçilmiş 1 milyon okuma çifti (paired-end)
curl -L -o data/SRR1039508_1.sub.fastq.gz $base/SRR1039508_1.sub.fastq.gz
curl -L -o data/SRR1039508_2.sub.fastq.gz $base/SRR1039508_2.sub.fastq.gz
curl -L -o data/SRR1039509_1.sub.fastq.gz $base/SRR1039509_1.sub.fastq.gz
curl -L -o data/SRR1039509_2.sub.fastq.gz $base/SRR1039509_2.sub.fastq.gz

# 3. İnsan transkriptomu (GENCODE 50); salmon indeksini bundan siz kuracaksınız
curl -L -o data/gencode.v50.transcripts.chr.fa.gz $base/gencode.v50.transcripts.chr.fa.gz

# 4. Transkriptten gene geçiş tablosu ve gen adları
curl -L -o data/tx2gene.gencode.v50.tsv.gz $base/tx2gene.gencode.v50.tsv.gz
curl -L -o data/genes.gencode.v50.tsv.gz $base/genes.gencode.v50.tsv.gz

# 5. Öteki altı örneğin salmon sonuçları (önceden hesaplandı)
curl -L -o data/salmon_quant.SRR1039512.tar.gz $base/salmon_quant.SRR1039512.tar.gz
curl -L -o data/salmon_quant.SRR1039513.tar.gz $base/salmon_quant.SRR1039513.tar.gz
curl -L -o data/salmon_quant.SRR1039516.tar.gz $base/salmon_quant.SRR1039516.tar.gz
curl -L -o data/salmon_quant.SRR1039517.tar.gz $base/salmon_quant.SRR1039517.tar.gz
curl -L -o data/salmon_quant.SRR1039520.tar.gz $base/salmon_quant.SRR1039520.tar.gz
curl -L -o data/salmon_quant.SRR1039521.tar.gz $base/salmon_quant.SRR1039521.tar.gz

# 6. Sağlama toplamı (checksum): her dosya yayımlanan dosyanın aynısı mı?
#    Her satırın sonunda OK görmelisiniz.
cd data
sha256sum -c --ignore-missing SHA256SUMS
cd ..

# 7. Altı sonucu data/quant/ klasörüne açınız
mkdir -p data/quant
for f in data/salmon_quant.*.tar.gz; do tar -xzf "$f" -C data/quant; done
ls data/quant

# Yedek (yalnızca eğitmen isterse): indeksi kurmak yerine hazır indeksi indirmek
# curl -L -o data/salmon_index.gencode.v50.tar.gz $base/salmon_index.gencode.v50.tar.gz
