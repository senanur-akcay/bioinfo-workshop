#!/usr/bin/env bash
# check/day2-setup.sh -- 2. gün kurulum kontrolü (WORKSHOP.md §5 adım 13-14).
# RStudio'daki Terminal sekmesinde, depo klasöründe çalıştırınız: bash check/day2-setup.sh
# Gün içinde birkaç kez çalıştırabilirsiniz. Henüz sırası gelmeyen adımlar SKIP olur.
# Yalnızca kurulumu sınar; analiz sonuçlarına bakmaz.
PASS=0; FAIL=0; SKIP=0
ok()   { printf '  PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf '  FAIL  %s\n' "$1"; printf '        Düzeltme: %s\n' "$2"; FAIL=$((FAIL + 1)); }
skip() { printf '  SKIP  %s\n' "$1"; printf '        %s\n' "$2"; SKIP=$((SKIP + 1)); }
printf '\n2. gün kurulum kontrolü\n\n'

marker="${HOME}/.config/bioinfo-workshop/workspace"
ws=""
[ -f "${marker}" ] && ws="$(head -n 1 "${marker}")"
[ -n "${ws}" ] || ws="$(pwd)"
conda_bin=/opt/conda/bin/conda

# 1. Çalışma klasörü
if [ -f "$(pwd)/bioinfo-workshop.Rproj" ] && [ "$(pwd)" = "${ws}" ]; then
    ok "Çalışma klasörünüz depo klasörüdür"
else
    bad "Çalışma klasörünüz depo klasörü değil (şu an: $(pwd))" "Terminal sekmesinde cd ${ws} yazınız, sonra bu kontrolü yeniden çalıştırınız."
fi

# 2. Makine: 4 çekirdek, 16 GB
cores="$(nproc 2>/dev/null || echo 0)"
mem_kb="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null)"
mem_gb=$(( (${mem_kb:-0} + 524288) / 1048576 ))
if [ "${cores}" -ge 4 ] && [ "${mem_kb:-0}" -ge 15000000 ]; then
    ok "Makine: ${cores} çekirdek, yaklaşık ${mem_gb} GB bellek"
else
    bad "Makine küçük: ${cores} çekirdek, yaklaşık ${mem_gb} GB bellek (2. gün için 4 çekirdek, 16 GB gerekir)" "Dünkü işinizi gönderdiyseniz (push) bu codespace'i siliniz. Deponuzda Code > Codespaces > ... > New with options seçiniz, Machine type olarak 4-core seçiniz ve Create codespace düğmesine basınız."
fi

# 3. Depo GitHub'a bağlı ve dünkü çalışma burada
origin="$(git -C "${ws}" remote get-url origin 2>/dev/null)"
if [ -z "${origin}" ]; then
    bad "Bu codespace bir GitHub deposuna bağlı değil" "Bu codespace'i siliniz ve codespace'i kendi bioinfo-workshop deponuzdan açınız (Code > Codespaces)."
else
    ok "Depo GitHub'a bağlı: ${origin}"
    if git -C "${ws}" ls-files --error-unmatch scripts/day1.R >/dev/null 2>&1; then
        ok "Dünkü betik (scripts/day1.R) depoda"
    else
        bad "scripts/day1.R depoda yok" "Dünkü çalışmanız GitHub'a gönderilmemiş olabilir. Eğitmene haber veriniz; dünkü codespace silinmediyse oradan git add, git commit ve git push yapılabilir."
    fi
fi

# 4. Veriler: setup/day2.sh ile indirilmiş ve bozulmamış mı
day2_files="chr20.fa.gz NA12878_window_1.fastq.gz NA12878_window_2.fastq.gz pbmc3k_filtered_gene_bc_matrices.tar.gz"
present=""; absent=""
for f in ${day2_files}; do
    if [ -s "${ws}/data/${f}" ]; then present="${present} ${f}"; else absent="${absent} ${f}"; fi
done
if [ ! -f "${ws}/data/SHA256SUMS" ]; then
    bad "data/SHA256SUMS bulunamadı" "Bu dosya deponuzla gelir. Eğitmene haber veriniz."
elif [ -z "${present}" ]; then
    skip "2. günün verileri henüz indirilmemiş" "Sırası gelince setup/day2.sh dosyasındaki komutları yazınız (veya bash setup/day2.sh)."
else
    badsum=""
    for f in ${present}; do
        line="$(grep -E "[[:space:]]\*?${f}\$" "${ws}/data/SHA256SUMS")"
        if [ -z "${line}" ] || ! (cd "${ws}/data" && printf '%s\n' "${line}" | sha256sum -c --status - 2>/dev/null); then
            badsum="${badsum} ${f}"
        fi
    done
    if [ -n "${badsum}" ]; then
        bad "Bozuk veya eksik inmiş dosya:${badsum}" "Bu dosyaları siliniz ve setup/day2.sh dosyasındaki curl komutuyla yeniden indiriniz."
    elif [ -n "${absent}" ]; then
        bad "Eksik dosya:${absent}" "setup/day2.sh dosyasındaki ilgili curl komutunu yazınız."
    else
        ok "2. günün dört dosyası indirilmiş; sağlama toplamları (checksum) doğru"
    fi
    if [ -s "${ws}/data/pbmc3k_filtered_gene_bc_matrices.tar.gz" ]; then
        if [ -s "${ws}/data/filtered_gene_bc_matrices/hg19/matrix.mtx" ]; then
            ok "PBMC 3k matrisi açılmış (data/filtered_gene_bc_matrices/hg19)"
        else
            bad "PBMC 3k arşivi açılmamış" "tar -xzf data/pbmc3k_filtered_gene_bc_matrices.tar.gz -C data yazınız."
        fi
    fi
fi

# 5. Ortam: envs/variants.yml ve variants ortamı (sabah yazılır)
envs_list="$("${conda_bin}" env list 2>/dev/null)"
has_env() { printf '%s\n' "${envs_list}" | grep -qE "^$1[[:space:]]"; }
f="${ws}/envs/variants.yml"
if [ ! -f "${f}" ]; then
    skip "envs/variants.yml henüz yok" "Sırası gelince slayttaki listeye bakarak envs/variants.yml dosyasını yazınız."
else
    missing=""
    for tool in bwa samtools bcftools fastp fastqc multiqc; do
        grep -qE "^[[:space:]]*-[[:space:]]*${tool}([=<> ]|\$)" "${f}" || missing="${missing} ${tool}"
    done
    if ! grep -qE '^name:[[:space:]]*variants[[:space:]]*$' "${f}"; then
        bad "envs/variants.yml içinde name: variants satırı yok" "Dosyanın ilk satırı name: variants olmalıdır."
    elif [ -n "${missing}" ]; then
        bad "envs/variants.yml içinde eksik araç:${missing}" "Slayttaki listeyle dosyanızı satır satır karşılaştırınız."
    else
        ok "envs/variants.yml yazılmış (ad ve altı araç doğru)"
    fi
    if has_env variants && [ -x /opt/conda/envs/variants/bin/bcftools ]; then
        ok "variants ortamı oluşturulmuş"
    elif has_env variants-ready; then
        skip "variants ortamı henüz yok" "conda env create -f envs/variants.yml yazınız. Olmazsa eğitmen variants-ready ortamını kullanmanızı söyler."
    else
        bad "Ne variants ne variants-ready ortamı var" "Codespace'i siliniz ve deponuzdan yeniden oluşturunuz."
    fi
fi

printf '\n----------------------------------------\n'
printf 'geçti: %s   kaldı: %s   atlandı: %s\n' "$PASS" "$FAIL" "$SKIP"
if [ "$FAIL" -eq 0 ]; then printf 'RESULT: PASS\n\n'; exit 0; fi
printf 'RESULT: FAIL\nYukarıdaki her FAIL satırının altındaki "Düzeltme:" satırını okuyunuz, sonra bu kontrolü yeniden çalıştırınız.\n\n'; exit 1
