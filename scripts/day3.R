#kütüphaneleri indir
library(tidyverse)
#varyant call sonuclarini bir degiskene dosya olarak ata
calls <- read_tsv("results/variants/raw_calls.tsv", comment = "#",
                  col_names = c("pos", "ref", "alt", "type", "qual", "dp", "mq", "gt", "gq", "ad"),
                  col_types = "dcccdddcdc") |>
  separate_wider_delim(ad, delim = ",", names = c("ad_ref", "ad_alt"), too_many = "drop", too_few = "align_start") |>
  mutate(across(c(ad_ref, ad_alt), as.numeric),
         alt_fraction = ad_alt / (ad_ref + ad_alt),
         type = if_else(type == "SNP", "SNP", "indel"))
calls

#genel okuma ve varyant calling QC metrikleri #mapping quality (mq) (varyant başka yere oturuyor mu) ve yapılan mappingden ne kadar emin (qual)?
summary(calls[, c("qual", "dp", "mq", "gq")])

#Metriklerin görselleştirilmesi
median_depth <- median(calls$dp)
p1 <- ggplot(calls, aes(qual)) + geom_histogram(bins = 60) + scale_x_log10() +
  labs(x = "QUAL (log scale)", title = "QUAL") + theme_bw()
p2 <- ggplot(calls, aes(dp)) + geom_histogram(binwidth = 2) + coord_cartesian(xlim = c(0, 150)) +
  labs(x = "INFO/DP", title = "Depth at the site") + theme_bw()
p3 <- ggplot(calls, aes(mq)) + geom_histogram(binwidth = 2) +
  labs(x = "INFO/MQ", title = "Mean mapping quality") + theme_bw()
p4 <- ggplot(calls |> filter(gt == "0/1"), aes(alt_fraction)) + geom_histogram(binwidth = 0.025) +
  labs(x = "ALT reads / all reads", title = "Allele balance of heterozygous calls") + theme_bw()
patchwork::wrap_plots(p1, p2, p3, p4, ncol = 2)

#bu noktada terminale gidip filtreleme aşamalarını yaptık. 106. satır.

#filtrelenmis olanlari gorsellestirmek uzere anotasyonlarini gerceklestir
filtered <- read_tsv("results/variants/filtered_calls.tsv", col_names = c("pos", "qual", "dp", "filter"),
                     col_types = "dddc")
filtered |> count(filter)

#Nokta grafiginin olusuturulmasi
ggplot(filtered, aes(dp, qual, colour = filter)) +
  geom_point(size = 0.8, alpha = 0.7) +
  scale_y_log10() +
  geom_hline(yintercept = 30, linetype = "dashed") +
  geom_vline(xintercept = c(10, 100), linetype = "dashed") +
  labs(x = "INFO/DP", y = "QUAL (log scale)", title = "Which calls the chosen filter removes") +
  theme_bw()

library(tidyverse)

#indel ve SNP icin ayri grafiklerin olusturulmasi
read_sites <- function(f) read_tsv(f, col_names = c("pos", "ref", "alt"), col_types = "dcc")
labels <- bind_rows(
  read_sites("results/isec/true_positives.tsv") |> mutate(status = "true positive"),
  read_sites("results/isec/false_positives.tsv") |> mutate(status = "false positive")
)
pass_calls <- read_sites("results/variants/pass_sites.tsv") |>
  left_join(calls, by = c("pos", "ref", "alt")) |>
  left_join(labels, by = c("pos", "ref", "alt")) |>
  mutate(status = replace_na(status, "outside confident regions"),
         genotype = case_when(gt %in% c("0/1", "1/0") ~ "heterozygous",
                              gt == "1/1" ~ "homozygous alt",
                              .default = gt))
pass_calls |> count(type, status)

#ne kadar homo/heterozigot
pass_calls |> count(genotype)


#indel/snp nokta grafigi
ggplot(pass_calls |> filter(status != "outside confident regions"),
       aes(x = dp, y = qual, colour = status)) +
  geom_point(size = 0.9, alpha = 0.7) +
  scale_y_log10() +
  facet_wrap(~ type) +
  labs(x = "INFO/DP", y = "QUAL (log scale)", title = "PASS calls inside the confident regions") +
  theme_bw()

#transition/transversionları bulmak
snvs <- pass_calls |> filter(type == "SNP")
transitions <- c("AG", "GA", "CT", "TC")
snvs |> mutate(change = paste0(ref, alt), class = if_else(change %in% transitions, "transition", "transversion")) |>
  count(class) |> mutate(ratio = n[class == "transition"] / n[class == "transversion"])

#yapısal elementleri yazdır
annot <- read_tsv("results/annot/annotated.tsv", comment = "#", na = ".",
                  col_names = c("pos", "rsid", "ref", "alt", "gt", "bcsq", "gnomad_af", "gnomad_faf95",
                                "clnsig", "clnrevstat", "clnvid"),
                  col_types = "dcccccddccc") |>
  mutate(first_csq = str_split_i(bcsq, ",", 1)) |>
  separate_wider_delim(first_csq, delim = "|", too_few = "align_start", too_many = "drop",
                       names = c("consequence", "gene", "transcript", "biotype", "strand",
                                 "protein_change", "dna_change"))
annot |> count(consequence, sort = TRUE)


#kodlayan bölgelerdeki mutasyonları
coding <- annot |>
  filter(str_detect(consequence, "missense|synonymous|stop|frameshift|inframe|splice|start_lost")) |>
  select(pos, rsid, gt, gene, consequence, protein_change, gnomad_af, gnomad_faf95, clnsig)
coding

#bu kişinin varyantları genel olarak databasede ne kadar yaygın
annot <- annot |>
  mutate(frequency = case_when(is.na(gnomad_af) ~ "not in gnomAD",
                               gnomad_af < 0.001 ~ "below 0.1 %",
                               gnomad_af < 0.01 ~ "0.1-1 %",
                               gnomad_af < 0.05 ~ "1-5 %",
                               .default = "5 % or more"),
         frequency = factor(frequency, levels = c("not in gnomAD", "below 0.1 %", "0.1-1 %", "1-5 %", "5 % or more")))
annot |> count(frequency)


#grafikle de gorelim:
ggplot(filter(annot, !is.na(gnomad_af)), aes(gnomad_af)) +
  geom_histogram(bins = 50) +
  scale_x_log10(labels = scales::label_percent()) +
  geom_vline(xintercept = c(0.001, 0.01, 0.05), linetype = "dashed") +
  labs(x = "allele frequency in gnomAD v4.1 genomes (log scale)", y = "variants",
       title = "How common are this person's variants?") +
  theme_bw()





