#!/usr/bin/env bash
# check/day1-envs.sh -- 1. gün, ortamlar (environment) bölümünün sonu (WORKSHOP.md §6).
# RStudio'daki Terminal sekmesinde, depo klasöründe çalıştırınız: bash check/day1-envs.sh
# Yalnızca kurulumu sınar: dosyalar yerinde mi, ortamlar var mı. Analiz sonucuna bakmaz.
PASS=0; FAIL=0; SKIP=0
ok()   { printf '  PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf '  FAIL  %s\n' "$1"; printf '        Düzeltme: %s\n' "$2"; FAIL=$((FAIL + 1)); }
skip() { printf '  SKIP  %s\n' "$1"; printf '        %s\n' "$2"; SKIP=$((SKIP + 1)); }
printf '\n1. gün ortam (environment) kontrolü\n\n'

conda_bin=/opt/conda/bin/conda
envs_list="$("${conda_bin}" env list 2>/dev/null)"
has_env() { printf '%s\n' "${envs_list}" | grep -qE "^$1[[:space:]]"; }

# deneme alıştırması
if [ -f envs/deneme.yml ] && grep -qE '^[[:space:]]*-[[:space:]]*([a-z-]+::)?seqkit([=<> ]|$)' envs/deneme.yml; then
    ok "envs/deneme.yml var ve içinde seqkit yazılı"
elif [ -f envs/deneme.yml ]; then
    bad "envs/deneme.yml var ama içinde seqkit satırı yok" "Ortamı silmeden önce conda env export --from-history ile dışa aktarmanız gerekir; dosyayı yeniden oluşturunuz."
else
    bad "envs/deneme.yml bulunamadı" "deneme ortamını envs/deneme.yml dosyasına dışa aktarınız (conda env export --from-history)."
fi
if has_env deneme; then
    bad "deneme ortamı hâlâ duruyor" "Alıştırmanın son adımı ortamı silmektir: conda env remove -n deneme yazınız."
else
    ok "deneme ortamı silinmiş"
fi

# envs/rnaseq.yml
f=envs/rnaseq.yml
if [ ! -f "${f}" ]; then
    bad "envs/rnaseq.yml bulunamadı" "Slayttaki listeye bakarak envs/rnaseq.yml dosyasını yazınız ve envs/ klasörüne kaydediniz."
else
    ok "envs/rnaseq.yml var"
    if grep -qE '^name:[[:space:]]*rnaseq[[:space:]]*$' "${f}"; then
        ok "envs/rnaseq.yml içinde ortamın adı rnaseq"
    else
        bad "envs/rnaseq.yml içinde name: rnaseq satırı yok" "Dosyanın ilk satırı name: rnaseq olmalıdır."
    fi
    if grep -qE '^[[:space:]]*-[[:space:]]*conda-forge' "${f}" && grep -qE '^[[:space:]]*-[[:space:]]*bioconda' "${f}"; then
        ok "Kanallar (channels) yazılı: conda-forge ve bioconda"
    else
        bad "channels bölümünde conda-forge ve bioconda yok" "channels: altına önce conda-forge, sonra bioconda yazınız."
    fi
    missing=""
    for tool in salmon fastp fastqc multiqc; do
        grep -qE "^[[:space:]]*-[[:space:]]*${tool}([=<> ]|\$)" "${f}" || missing="${missing} ${tool}"
    done
    if [ -z "${missing}" ]; then
        ok "Dört araç yazılı: salmon, fastp, fastqc, multiqc"
    else
        bad "dependencies bölümünde eksik araç:${missing}" "Slayttaki listeyle dosyanızı satır satır karşılaştırınız."
    fi
fi

# rnaseq ortamı
if has_env rnaseq; then
    ok "rnaseq ortamı oluşturulmuş"
    if [ -x /opt/conda/envs/rnaseq/bin/salmon ] && /opt/conda/envs/rnaseq/bin/salmon --version >/dev/null 2>&1; then
        ok "rnaseq ortamında salmon çalışıyor"
    else
        bad "rnaseq ortamında salmon çalışmıyor" "conda env remove -n rnaseq yazınız, sonra conda env create -f envs/rnaseq.yml ile yeniden oluşturunuz."
    fi
else
    bad "rnaseq ortamı yok" "conda env create -f envs/rnaseq.yml yazınız."
fi

printf '\n----------------------------------------\n'
printf 'geçti: %s   kaldı: %s   atlandı: %s\n' "$PASS" "$FAIL" "$SKIP"
if [ "$FAIL" -eq 0 ]; then printf 'RESULT: PASS\n\n'; exit 0; fi
printf 'RESULT: FAIL\nYukarıdaki her FAIL satırının altındaki "Düzeltme:" satırını okuyunuz, sonra bu kontrolü yeniden çalıştırınız.\n\n'; exit 1
