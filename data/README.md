# data/: atölye verileri

Bu klasördeki veriler git'e eklenmez. Depoda yalnızca bu dosya ve `SHA256SUMS` durur.
Veriler bu deponun `data-v1` yayınındadır (release).
Her gün `setup/day1.sh`, `setup/day2.sh` ve `setup/day3.sh` dosyalarındaki komutlarla indirilir.

`SHA256SUMS`, yayımlanan her dosyanın sağlama toplamıdır (checksum).
İndirdiğiniz dosya bozulmuşsa veya eksik inmişse `sha256sum -c` komutu bunu gösterir.

Verileri atölye dışında kullanırsanız aşağıdaki kaynaklara atıf yapınız.

## 1. gün: toplu RNA-seq (airway)

| Dosya | Ne | Kaynak | Kullanım koşulu |
|---|---|---|---|
| `airway_samples.csv` | Sekiz örneğin (sample) tablosu: hücre hattı, dex tedavisi, okuma uzunluğu | Bioconductor `airway` paketi 1.32.0 | LGPL |
| `SRR1039508_1.sub.fastq.gz`, `SRR1039508_2.sub.fastq.gz`, `SRR1039509_1.sub.fastq.gz`, `SRR1039509_2.sub.fastq.gz` | İki örnekten rastgele seçilmiş 1 milyon okuma çifti (seqtk 1.5, tohum 20261001) | ENA, SRR1039508 ve SRR1039509; indirilen dosyalar ENA'nın MD5 değerleriyle doğrulandı | INSDC verileri kısıtlamasız kullanılır |
| `salmon_quant.SRR1039512.tar.gz` … `salmon_quant.SRR1039521.tar.gz` | Öteki altı örneğin salmon 2.8.0 sonuçları, tüm okumalarla | ENA'daki okumalar ve GENCODE 50 transkriptomu | Aynı kaynakların koşulları |
| `gencode.v50.transcripts.chr.fa.gz` | İnsan transkript dizileri, GENCODE 50 (GRCh38); yalnızca referans kromozomlarındaki transkriptler (ek lokus ve yama kopyaları çıkarıldı, GTF dosyasıyla aynı küme) | GENCODE | GENCODE verileri açık erişimlidir |
| `tx2gene.gencode.v50.tsv.gz`, `genes.gencode.v50.tsv.gz` | Transkriptten gene geçiş tablosu; gen adları ve türleri | GENCODE 50 açıklama (annotation) dosyasından çıkarıldı | GENCODE verileri açık erişimlidir |
| `salmon_index.gencode.v50.tar.gz` | Hazır salmon indeksi; yalnızca yedek | GENCODE 50 transkriptomundan | Aynı |

Çalışma: Himes BE ve ark. (2014) RNA-Seq transcriptome profiling identifies CRISPLD2 as a glucocorticoid responsive gene that modulates cytokine function in airway smooth muscle cells. *PLoS One* 9(6): e99625. GEO: GSE52778.

## Varyant çağırma (3. gün) ve tek hücre (2. gün)

Varyant çağırma ilk planda 2. gün için hazırlanmıştı; atölyede 3. gün yapıldı.
Bu nedenle verileri indiren dosyanın adı (`setup/day2.sh`) ilk plana göre kalmıştır.

| Dosya | Ne | Kaynak | Kullanım koşulu |
|---|---|---|---|
| `chr20.fa.gz` | İnsan 20. kromozomu, hg38 (GRCh38) | UCSC Genome Browser | Serbestçe indirilebilir |
| `NA12878_window_1.fastq.gz`, `NA12878_window_2.fastq.gz` | NA12878 bireyinin `chr20:10000000-12000000` bölgesine hizalanmış okumaları, yeniden FASTQ biçiminde; eşi bölge dışında kalan okumalar çıkarıldı | 1000 Genomes 30x yüksek kapsamlı veri, ERR3239334 | Fort Lauderdale anlaşması; IGSR veri kullanım bildirimi |
| `pbmc3k_filtered_gene_bc_matrices.tar.gz` | 2.700 kan hücresinin (PBMC) sayım matrisi, hg19 | 10x Genomics, "3k PBMCs from a Healthy Donor" (Cell Ranger 1.1.0) | CC BY 4.0 |

Çalışmalar: Byrska-Bishop M ve ark. (2022) High-coverage whole-genome sequencing of the expanded 1000 Genomes Project cohort including 602 trios. *Cell* 185(18): 3426-3440. Tek hücre verisi: 10x Genomics, CC BY 4.0.

`chr20.fa.gz` ile 1000 Genomes verisinin kullandığı 20. kromozom aynı dizidir (MD5 b18e6c531b0bd70e949a7fc20859cb01).

Yayında ayrıca `NA12878_GIAB_v4.2.1_window.vcf.gz`, `.tbi` ve `NA12878_GIAB_v4.2.1_window_confident.bed` dosyaları vardır.
Bunlar Genome in a Bottle (NIST) HG001 v4.2.1 doğruluk kümesinin aynı bölgesidir.
Doğruluk karşılaştırması için atölyede ayrıca indirilir; günlük indirme dosyasında (`setup/day2.sh`) yoktur.

## Bitirme çalışması (pasilla)

Bitirme çalışması programdan çıkarılmıştır; dosyaları yayında durmaktadır.

| Dosya | Ne | Kaynak | Kullanım koşulu |
|---|---|---|---|
| `capstone_pasilla_gene_counts.tsv.gz` | Meyve sineği hücrelerinde gen başına okuma sayıları | Bioconductor `pasilla` paketi 1.40.0 | LGPL |
| `capstone_pasilla_samples.csv` | Yedi örneğin tablosu: koşul ve okuma türü | Aynı paket | LGPL |

Çalışma: Brooks AN ve ark. (2011) Conservation of an RNA regulatory map between Drosophila and mammals. *Genome Research* 21(2): 193-202. GEO: GSM461176-GSM461181.

## 3. gün: varyant anotasyonu

Bu dosyalar `chr20:10000000-12000000` bölgesi için hazırlanmıştır.
Sağlama toplamları yayındaki `ANNOTATION.SHA256SUMS` dosyasındadır.

| Dosya | Ne | Kaynak | Kullanım koşulu |
|---|---|---|---|
| `chr20.ensembl116.gff3.gz` | 20. kromozomun gen anotasyonu (annotation): genler, transkriptler, ekzonlar, kodlayan bölgeler; kromozom adı `chr20` olarak değiştirildi | Ensembl 116 (GENCODE 50 ile aynı anotasyon), GRCh38 | Ensembl verileri kısıtlama olmaksızın kullanılabilir |
| `chr20.ensembl116.mane.gff3.gz` | Aynı dosyanın yalnızca MANE Select transkriptlerini içeren hâli (protein kodlayan her gen için bir transkript) | Aynı | Aynı |
| `gnomad.genomes.v4.1.window.vcf.gz`, `.tbi` | gnomAD v4.1 genom verisinin bu bölgedeki PASS varyantları ve alel sıklıkları; kullanılan alanların adlarının başına `gnomAD_` eklendi | gnomAD v4.1, gnomad.broadinstitute.org | ODbL 1.0; bu dosya da ODbL ile paylaşılır |
| `clinvar_20261011.window.vcf.gz`, `.tbi` | ClinVar'ın 11 Ekim 2026 haftalık sürümünün bu bölgedeki kayıtları; kromozom adı `chr20` olarak değiştirildi, Variation ID ayrıca `CLNVID` alanına yazıldı | NCBI ClinVar | Kamu malı (public domain) |
| `README-template.md` | Katılımcı depolarının README şablonu | Atölye | |

Çalışmalar: Karczewski KJ ve ark. (2020) The mutational constraint spectrum quantified from variation in 141,456 humans. *Nature* 581: 434-443 (gnomAD). Chen S ve ark. (2024) A genomic mutational constraint map using variation in 76,156 human genomes. *Nature* 625: 92-100 (gnomAD genomları). Landrum MJ ve ark. (2018) ClinVar: improving access to variant interpretations and supporting evidence. *Nucleic Acids Research* 46(D1): D1062-D1067. Morales J ve ark. (2022) A joint NCBI and EMBL-EBI transcript set for clinical genomics and research. *Nature* 604: 310-315 (MANE).
