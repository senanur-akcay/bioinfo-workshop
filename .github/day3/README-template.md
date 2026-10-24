# Uygulamalı Biyoenformatik Atölyesi: çalışma deposu

Bu depo, **[Adınız Soyadınız]** tarafından Uygulamalı Biyoenformatik Atölyesi (Ekim 2026) süresince yazılan
betikleri ve yazılım ortamı dosyalarını içermektedir. Betiklerin tamamı atölyede, her adımın gerekçesi ve
sonuçların yorumu tartışılarak satır satır yazılmıştır.

## Üç günün analizleri

| Gün | Analiz | Veri | Betikler | Ortam dosyası |
|---|---|---|---|---|
| 1 | Bulk RNA-seq: okuma kalitesinin kontrolü, Salmon ile transkript düzeyinde sayım, DESeq2 ile diferansiyel ifade analizi | Deksametazon uygulanmış hava yolu düz kas hücreleri (Himes ve ark. 2014, GEO GSE52778) | [`scripts/day1.sh`](scripts/day1.sh), [`scripts/day1.R`](scripts/day1.R) | [`envs/rnaseq.yml`](envs/rnaseq.yml) |
| 2 | Single-cell RNA-seq: kalite kontrol, normalizasyon, PCA, kümeleme, UMAP ve hücre tiplerinin belirlenmesi (Seurat) | 10x Genomics PBMC 3k: sağlıklı bir bireyin periferik kan mononükleer hücreleri (PBMC) | [`scripts/day2.sh`](scripts/day2.sh), [`scripts/day2.R`](scripts/day2.R) | R paketleri codespace imajındadır |
| 3 | Germline varyant analizi: okuma kalitesinin kontrolü, bwa ile hizalama, bcftools ile varyant çağırma ve filtreleme, Genome in a Bottle doğruluk kümesiyle karşılaştırma, varyant anotasyonu (Ensembl, gnomAD, ClinVar) | NA12878 (GIAB HG001), 20. kromozomun 10-12 Mb bölgesi (1000 Genomes, 30x) | [`scripts/day3.sh`](scripts/day3.sh), [`scripts/day3.R`](scripts/day3.R) | [`envs/variants.yml`](envs/variants.yml) |

## Analizler nasıl yeniden çalıştırılır

Veriler ve sonuç dosyaları bu depoda tutulmaz; betikler verileri indirir ve sonuçları yeniden üretir.

1. Bu deponun sayfasında **Code > Codespaces > Create codespace on main** ile bir codespace oluşturulur;
   RStudio birkaç dakika içinde açılır.
2. O günün Terminal betiği (`scripts/dayN.sh`) RStudio'da açılır ve komutları Terminal sekmesinde sırayla
   çalıştırılır. Betik, gerektiğinde yazılım ortamını `envs/` klasöründeki dosyadan oluşturur ve o günün
   verilerini indirir; örneğin 3. günün betiği `conda env create -f envs/variants.yml`, `conda activate variants`
   ve `bash setup/day2.sh` satırlarını içerir. Ortam aynı codespace'te daha önce oluşturulduysa `conda env create`
   satırı atlanabilir; betikteki `git` satırlarının yeniden çalıştırılmasına gerek yoktur.
3. O günün R betiği (`scripts/dayN.R`) RStudio'da açılır ve baştan sona çalıştırılır.

## Klasörler

| Klasör | İçerik |
|---|---|
| `scripts/` | Üç günün betikleri |
| `envs/` | conda ortam dosyaları (atölyede elle yazıldı) |
| `setup/` | Her günün veri indirme komutları |
| `check/` | Atölyenin kurulum kontrolleri |
| `data/` | Verilerin kaynakları ve kullanım koşulları (`data/README.md`); verilerin kendisi depoda tutulmaz |

Bu depo, atölyenin şablon deposundan ([onedimkurt/bioinfo-workshop](https://github.com/onedimkurt/bioinfo-workshop)) oluşturulmuştur.

## English summary

This repository contains the scripts and environment files written by **[Your Name]** during a three-day
applied bioinformatics workshop (October 2026): bulk RNA-seq (Salmon, DESeq2), single-cell RNA-seq (Seurat),
and germline variant calling, benchmarking and annotation (bwa, samtools, bcftools; Genome in a Bottle,
Ensembl, gnomAD, ClinVar). Every line was written by hand during the workshop.
