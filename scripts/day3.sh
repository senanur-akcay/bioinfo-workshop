#analiz ortamını oluşturma
conda env create -f envs/variants.yml
#toolların versiyonlarını kontrol et
conda activate variants
bwa 2>&1 | grep Version
samtools --version | head -1
bcftools --version | head -1
which bgzip tabix


#data indirme
bash setup/day2.sh
#data kontrol
ls -lh data/


#okuma satır kontrolü
zcat data/NA12878_window_1.fastq.gz | head -4
for r in 1 2; do
  echo "R$r: $(( $(zcat data/NA12878_window_$r.fastq.gz | wc -l) / 4 )) reads"
done
zcat data/NA12878_window_1.fastq.gz | head -40000 | awk 'NR % 4 == 2 { print length($0) }' | sort -n | uniq -c | sort -k1,1nr | head -3

#FASTQC
mkdir -p results/fastqc
fastqc -t 4 --extract -o results/fastqc data/NA12878_window_1.fastq.gz data/NA12878_window_2.fastq.gz

#örnek sonuç yazdırma, FASTQC
cat results/fastqc/*_fastqc/summary.txt | sort -k2,2 -t$'\t' | cut -f1,2,3

#FASTp, dosyada değişiklik yapan ilk QC adımı #bu adımda sadece adaptörler kırpıldı, asıl kırpma sonrasında gerçekleştirilecektir.
mkdir -p results/fastp
fastp -i data/NA12878_window_1.fastq.gz -I data/NA12878_window_2.fastq.gz \
      -o results/fastp/NA12878_1.trim.fastq.gz -O results/fastp/NA12878_2.trim.fastq.gz \
      --detect_adapter_for_pe -w 4 \
      -j results/fastp/NA12878.fastp.json -h results/fastp/NA12878.fastp.html

#tekrar FASTQC
mkdir -p results/fastqc_trimmed
fastqc -t 4 --extract -o results/fastqc_trimmed results/fastp/NA12878_1.trim.fastq.gz results/fastp/NA12878_2.trim.fastq.gz

#HANGİLERİ GEÇTİ/HANGİLERİ KALDI
cat results/fastqc_trimmed/*_fastqc/summary.txt | sort -k2,2 -t$'\t' | cut -f1,2,3

#multiqc
multiqc -q -o results/multiqc results/fastqc results/fastqc_trimmed results/fastp

#referans ve index indirme (index referansta aradığın kromozom parçasının nerede old. gösterir.)
mkdir -p results/ref
gunzip -c data/chr20.fa.gz > results/ref/chr20.fa
samtools faidx results/ref/chr20.fa
cut -f1,2 results/ref/chr20.fa.fai
bwa index results/ref/chr20.fa 2>&1 | tail -3
ls -lh results/ref/

#BWA ile hizalama
mkdir -p results/align
bwa mem -t 4 -R '@RG\tID:NA12878\tSM:NA12878\tPL:ILLUMINA' results/ref/chr20.fa \
    results/fastp/NA12878_1.trim.fastq.gz results/fastp/NA12878_2.trim.fastq.gz 2> results/align/bwa.log \
  | samtools fixmate -m - - \
  | samtools sort -@ 4 -o results/align/NA12878.sorted.bam -   #binary alignment map (bam) elimdeki veri referansta var mı, nerede?
tail -3 results/align/bwa.log
ls -lh results/align/

#duplikatlar/indexler inceleme
samtools markdup -s results/align/NA12878.sorted.bam results/align/NA12878.bam 2>&1 | head -20
samtools index results/align/NA12878.bam

samtools flagstat results/align/NA12878.bam

#BAN dosyasının birkaç satırı
samtools view -H results/align/NA12878.bam | grep -v '^@SQ' | head
samtools view -H results/align/NA12878.bam | grep -c '^@SQ'
samtools view results/align/NA12878.bam chr20:10500000-10500300 | head -3 | cut -f1-9

#kapsam ve derinlik
samtools coverage -r chr20:10000000-12000000 results/align/NA12878.bam
samtools view -F 0xB04 results/align/NA12878.bam | cut -f5 > results/align/mapq.txt
sort -n results/align/mapq.txt | uniq -c | sort -k1,1nr | head -5

#Önemli not: kullandığınız panel ve sekanslama ne olursa olsun whole genome'a allign yapma daha uygun olur. false allignment önlenir.

#elde edilen hizlanmış ve sıralanmış dosyaları varyant bulma için hizalama
mkdir -p results/variants #mpileup varyant olasılığını hesaplar. 
bcftools mpileup -f results/ref/chr20.fa -r chr20:10000000-12000000 -a FORMAT/AD,FORMAT/DP -Ou results/align/NA12878.bam \ 
  | bcftools call -m -v -a GQ -Oz -o results/variants/NA12878.raw.vcf.gz
bcftools index -t results/variants/NA12878.raw.vcf.gz

#VCF dosyasını okumak
bcftools view -h results/variants/NA12878.raw.vcf.gz | grep -E '^##(INFO|FORMAT)=<ID=(DP|MQ|GT|GQ|AD|PL),'
bcftools view -h results/variants/NA12878.raw.vcf.gz | tail -1
bcftools head -h 0 -n 3 results/variants/NA12878.raw.vcf.gz | cut -f1-10

#Ne kadar SNP/Indel var? #henüz filtrelenmedi, filtrelemeden önce grafikte bakılır.
echo "all:    $(bcftools view -H results/variants/NA12878.raw.vcf.gz | wc -l)"
echo "SNPs:   $(bcftools view -H -v snps results/variants/NA12878.raw.vcf.gz | wc -l)"
echo "indels: $(bcftools view -H -v indels results/variants/NA12878.raw.vcf.gz | wc -l)"

#raw_variants dosyasini olusturacak
bcftools norm -f results/ref/chr20.fa -m -any -Oz -o results/variants/NA12878.raw.norm.vcf.gz results/variants/NA12878.raw.vcf.gz
bcftools index -t results/variants/NA12878.raw.norm.vcf.gz
bcftools query -H -f '%POS\t%REF\t%ALT\t%TYPE\t%QUAL\t%INFO/DP\t%INFO/MQ[\t%GT\t%GQ\t%AD]\n' \
  results/variants/NA12878.raw.norm.vcf.gz > results/variants/raw_calls.tsv
head -4 results/variants/raw_calls.tsv

#Filtreleme asamalari
bcftools filter -s LowQual -e 'QUAL<30 || INFO/DP<10 || INFO/DP>100 || INFO/MQ<30' \
  -Oz -o results/variants/NA12878.filtered.vcf.gz results/variants/NA12878.raw.norm.vcf.gz
bcftools index -t results/variants/NA12878.filtered.vcf.gz
bcftools view -H results/variants/NA12878.filtered.vcf.gz | cut -f7 | sort | uniq -c
bcftools view -f PASS -Oz -o results/variants/NA12878.pass.vcf.gz results/variants/NA12878.filtered.vcf.gz
bcftools index -t results/variants/NA12878.pass.vcf.g

#filtrelemeyi gecenlerin istatsitik degerlerini dosyaya yazdir
bcftools stats results/variants/NA12878.pass.vcf.gz > results/variants/pass.stats.txt
grep -E '^SN' results/variants/pass.stats.txt | cut -f3-
grep -E '^TSTV' results/variants/pass.stats.txt | cut -f3-5


#Filtrelenmis olanlari tek bir dosyaya topla
bcftools query -f '%POS\t%QUAL\t%INFO/DP\t%FILTER\n' results/variants/NA12878.filtered.vcf.gz > results/variants/filtered_calls.tsv
head -3 results/variants/filtered_calls.tsv
#bu noktada r scripte geçip grafik oluştur.


#varyant calling ne kadar doğru, test edilmesi? (gerçek hayatta cevap anahtarı yok. Bu data set golden standart olduğu için bu varyantlar değişmez. Normalde bunu bir ndikatör gibi kulanılır, yazılımsal güncellemeler veri setinde analizde değişikliğe neden oluyor mu bunu anlamak için kullanılan bir data)
#bashte calisacak
#Varyant cagirma islemimizin dogrulugunun test edilmesi
base=https://github.com/onedimkurt/bioinfo-workshop/releases/download/data-v1
for f in NA12878_GIAB_v4.2.1_window.vcf.gz NA12878_GIAB_v4.2.1_window.vcf.gz.tbi NA12878_GIAB_v4.2.1_window_confident.bed; do
  curl -L -o data/$f $base/$f
done
(cd data && grep NA12878_GIAB SHA256SUMS | sha256sum -c -)


#cevap anahtari ile karsilastirmak uzere loop dondur

bcftools norm -f results/ref/chr20.fa -m -any -Oz -o results/variants/truth.norm.vcf.gz data/NA12878_GIAB_v4.2.1_window.vcf.gz
bcftools index -t results/variants/truth.norm.vcf.gz
bcftools isec -R data/NA12878_GIAB_v4.2.1_window_confident.bed -p results/isec -Oz \
  results/variants/NA12878.pass.vcf.gz results/variants/truth.norm.vcf.gz
cat results/isec/README.txt | grep -E '^results'
tp=$(bcftools view -H results/isec/0002.vcf.gz | wc -l)
fp=$(bcftools view -H results/isec/0000.vcf.gz | wc -l)
fn=$(bcftools view -H results/isec/0001.vcf.gz | wc -l)
echo "TP $tp  FP $fp  FN $fn"
awk -v tp=$tp -v fp=$fp -v fn=$fn 'BEGIN { printf "precision %.3f  recall %.3f\n", tp/(tp+fp), tp/(tp+fn) }'
for v in snps indels; do
  tp=$(bcftools view -H -v $v results/isec/0002.vcf.gz | wc -l)
  fp=$(bcftools view -H -v $v results/isec/0000.vcf.gz | wc -l)
  fn=$(bcftools view -H -v $v results/isec/0001.vcf.gz | wc -l)
  awk -v v=$v -v tp=$tp -v fp=$fp -v fn=$fn 'BEGIN { printf "%-6s TP %4d FP %4d FN %4d  precision %.3f  recall %.3f\n", v, tp, fp, fn, tp/(tp+fp), tp/(tp+fn) }'
done


#indel ve snpler içinvaryant callari ve doğrulukları filtrele/dosya oluştur
bcftools query -f '%POS\t%REF\t%ALT\n' results/isec/0002.vcf.gz > results/isec/true_positives.tsv
bcftools query -f '%POS\t%REF\t%ALT\n' results/isec/0000.vcf.gz > results/isec/false_positives.tsv
bcftools query -f '%POS\t%REF\t%ALT\n' results/variants/NA12878.pass.vcf.gz > results/variants/pass_sites.tsv
wc -l results/isec/*.tsv results/variants/pass_sites.tsv


#error almıştım onu düzelttik, dosyalar boş çıkmıştı.
ls -l results/isec/

bcftools index -t -f results/variants/NA12878.pass.vcf.gz
bcftools index -t -f results/variants/truth.norm.vcf.gz
rm -rf results/isec
bcftools isec -R data/NA12878_GIAB_v4.2.1_window_confident.bed -p results/isec -Oz \
  results/variants/NA12878.pass.vcf.gz results/variants/truth.norm.vcf.gz

ls -l results/isec/
bcftools view -H results/isec/0002.vcf.gz | head -2
#bu kod ile boş olan dosyaya veriler yazıldı.

#fonksyionel elementlerin durumunu bulabilmek icin anotasyon dosyasini indir
base=https://github.com/onedimkurt/bioinfo-workshop/releases/download/data-v1
for f in ANNOTATION.SHA256SUMS chr20.ensembl116.mane.gff3.gz \
         gnomad.genomes.v4.1.window.vcf.gz gnomad.genomes.v4.1.window.vcf.gz.tbi \
         clinvar_20261011.window.vcf.gz clinvar_20261011.window.vcf.gz.tbi; do
  curl -L -o data/$f $base/$f
done
(cd data && sha256sum -c --ignore-missing ANNOTATION.SHA256SUMS)


#varyantlar genomik olarak hangi elementlerin(intron/ekzon/utr, etc.) içindedir?
mkdir -p results/annot
bcftools csq -f results/ref/chr20.fa -g data/chr20.ensembl116.mane.gff3.gz -p a \
  -Oz -o results/annot/NA12878.csq.vcf.gz results/variants/NA12878.pass.vcf.gz
bcftools index -t results/annot/NA12878.csq.vcf.gz

#clinvardaki bilinen varyantlarla eşleştirilecek. 
bcftools annotate -a data/gnomad.genomes.v4.1.window.vcf.gz -c ID,INFO \
  -Oz -o results/annot/NA12878.gnomad.vcf.gz results/annot/NA12878.csq.vcf.gz
bcftools index -t results/annot/NA12878.gnomad.vcf.gz
bcftools annotate -a data/clinvar_20261011.window.vcf.gz -c INFO \
  -Oz -o results/annot/NA12878.annotated.vcf.gz results/annot/NA12878.gnomad.vcf.gz
bcftools index -t results/annot/NA12878.annotated.vcf.gz
bcftools view -h results/annot/NA12878.annotated.vcf.gz \
  | grep -E '^##INFO=<ID=(BCSQ|gnomAD_AF|gnomAD_FAF95|CLNSIG|CLNREVSTAT|CLNVID),'

#ilk 3 satıra bakarak gatanın yapısını görelim
bcftools query -H -f '%POS\t%ID\t%REF\t%ALT[\t%GT]\t%INFO/BCSQ\t%INFO/gnomAD_AF\t%INFO/gnomAD_FAF95\t%INFO/CLNSIG\t%INFO/CLNREVSTAT\t%INFO/CLNVID\n' \
  results/annot/NA12878.annotated.vcf.gz > results/annot/annotated.tsv
head -3 results/annot/annotated.tsv

#bir false positive örneği

fp=$(head -1 results/isec/false_positives.tsv | cut -f1)
echo "first false positive: chr20:$fp"
bcftools view -H -r chr20:$fp results/variants/NA12878.pass.vcf.gz | cut -f1-6,10
samtools tview -d T -w 100 -p chr20:$((fp - 40)) results/align/NA12878.bam results/ref/chr20.fa | head -25








