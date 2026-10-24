#!/usr/bin/env bash
# setup/day2.sh -- 2. günün verileri
#
# Bu dosya, 2. gün indireceğiniz dosyaların adreslerini listeler.
# Komutları RStudio'daki Terminal sekmesine birer birer kendiniz yazınız.
# Zaman darsa dosyanın tamamını tek komutla çalıştırabilirsiniz:
#     bash setup/day2.sh
# Dosyaların kaynağı ve kullanım koşulları: data/README.md
set -euo pipefail
if [ ! -f bioinfo-workshop.Rproj ]; then
    echo "Bu komutları depo klasöründe çalıştırınız: cd /workspaces/bioinfo-workshop"
    exit 1
fi

base=https://github.com/onedimkurt/bioinfo-workshop/releases/download/data-v1
mkdir -p data

# 1. Varyant çağırma: insan 20. kromozomu (hg38) ve NA12878'in bu bölgedeki okumaları
curl -L -o data/chr20.fa.gz $base/chr20.fa.gz
curl -L -o data/NA12878_window_1.fastq.gz $base/NA12878_window_1.fastq.gz
curl -L -o data/NA12878_window_2.fastq.gz $base/NA12878_window_2.fastq.gz

# 2. Tek hücre: 10x Genomics PBMC 3k sayım matrisi (sıkıştırılmış arşiv)
curl -L -o data/pbmc3k_filtered_gene_bc_matrices.tar.gz $base/pbmc3k_filtered_gene_bc_matrices.tar.gz

# 3. Sağlama toplamı (checksum): her satırın sonunda OK görmelisiniz
cd data
sha256sum -c --ignore-missing SHA256SUMS
cd ..

# 4. Matrisi açınız: data/filtered_gene_bc_matrices/hg19/ klasörü oluşur
tar -xzf data/pbmc3k_filtered_gene_bc_matrices.tar.gz -C data
ls data/filtered_gene_bc_matrices/hg19
