# envs/

Bu klasöre conda ortam (environment) dosyalarınızı yazacaksınız.
Bir ortam dosyası, bir projenin araçlarını ve sürümlerini yazılı olarak saklar.
Codespace silinince ortam da silinir; bu dosya kalır ve ortamı yeniden kurar.

Dosyayı satır satır siz yazacaksınız. Sürümleri aşağıdaki tablolardan alınız.
Bir aracın sürümü dosyada şu biçimde yazılır: `- salmon=2.8.0`

## 1. gün: `envs/rnaseq.yml`

Ortamın adı: `rnaseq`. Kanallar (channels), bu sırayla: `conda-forge`, `bioconda`.

| Araç | Sürüm | Ne işe yarar |
|---|---|---|
| salmon | 2.8.0 | Okumaları transkriptlere eşler ve sayar |
| fastp | 1.3.7 | Okumaları kırpar ve kalite özetini yazar |
| fastqc | 0.12.1 | Ham okumaların kalite raporunu hazırlar |
| multiqc | 1.35 | Raporları tek bir sayfada toplar |

## 2. gün: `envs/variants.yml`

Ortamın adı: `variants`. Kanallar, bu sırayla: `conda-forge`, `bioconda`.

| Araç | Sürüm | Ne işe yarar |
|---|---|---|
| bwa | 0.7.19 | Okumaları referans genoma hizalar |
| samtools | 1.24 | BAM dosyalarını sıralar, dizinler ve özetler |
| bcftools | 1.24 | Varyantları çağırır, süzer ve özetler |
| htslib | 1.24 | `bgzip` ve `tabix` komutlarını sağlar |
| fastp | 1.3.7 | Okumaları kırpar ve kalite özetini yazar |
| fastqc | 0.12.1 | Ham okumaların kalite raporunu hazırlar |
| multiqc | 1.35 | Raporları tek bir sayfada toplar |

## 3. gün

3. gün bu klasöre iki dosya daha ekleyeceksiniz:
taşınabilir ortam dosyası (`conda env export --from-history`) ve tam kilit dosyası (`conda list --explicit`).
