#!/usr/bin/env bash
# setup/day3.sh -- 3. günün verileri (bitirme çalışması)
#
# Bu dosya, bitirme çalışmasının verilerinin adreslerini listeler.
# Komutları RStudio'daki Terminal sekmesine birer birer kendiniz yazınız.
# Zaman darsa dosyanın tamamını tek komutla çalıştırabilirsiniz:
#     bash setup/day3.sh
# Dosyaların kaynağı ve kullanım koşulları: data/README.md
set -euo pipefail
if [ ! -f bioinfo-workshop.Rproj ]; then
    echo "Bu komutları depo klasöründe çalıştırınız: cd /workspaces/bioinfo-workshop"
    exit 1
fi

base=https://github.com/onedimkurt/bioinfo-workshop/releases/download/data-v1
mkdir -p data

# 1. Sayım tablosu ve örnek (sample) tablosu
curl -L -o data/capstone_pasilla_gene_counts.tsv.gz $base/capstone_pasilla_gene_counts.tsv.gz
curl -L -o data/capstone_pasilla_samples.csv $base/capstone_pasilla_samples.csv

# 2. Sağlama toplamı (checksum): her satırın sonunda OK görmelisiniz
cd data
sha256sum -c --ignore-missing SHA256SUMS
cd ..
