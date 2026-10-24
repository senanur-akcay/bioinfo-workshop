#!/usr/bin/env bash
# check/day3-setup.sh -- 3. gün kurulum kontrolü (WORKSHOP.md §5 adım 15).
# RStudio'daki Terminal sekmesinde, depo klasöründe çalıştırınız: bash check/day3-setup.sh
# Yalnızca kurulumu sınar; analiz sonuçlarına ve bitirme çalışmasının içeriğine bakmaz.
PASS=0; FAIL=0; SKIP=0
ok()   { printf '  PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf '  FAIL  %s\n' "$1"; printf '        Düzeltme: %s\n' "$2"; FAIL=$((FAIL + 1)); }
skip() { printf '  SKIP  %s\n' "$1"; printf '        %s\n' "$2"; SKIP=$((SKIP + 1)); }
printf '\n3. gün kurulum kontrolü\n\n'

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

# 2. Depo bağlı, iki günün betikleri depoda, gönderilmemiş sürüm yok
origin="$(git -C "${ws}" remote get-url origin 2>/dev/null)"
if [ -z "${origin}" ]; then
    bad "Bu codespace bir GitHub deposuna bağlı değil" "Bu codespace'i siliniz ve codespace'i kendi bioinfo-workshop deponuzdan açınız (Code > Codespaces)."
else
    ok "Depo GitHub'a bağlı: ${origin}"
    missing=""
    for s in scripts/day1.R scripts/day2.R scripts/day2.sh; do
        git -C "${ws}" ls-files --error-unmatch "${s}" >/dev/null 2>&1 || missing="${missing} ${s}"
    done
    if [ -z "${missing}" ]; then
        ok "Önceki iki günün betikleri depoda"
    else
        bad "Depoda olmayan betik:${missing}" "Betiği git add ile ekleyiniz, sürüm (commit) olarak kaydediniz ve gönderiniz (git push)."
    fi
    git -C "${ws}" fetch -q origin 2>/dev/null
    ahead="$(git -C "${ws}" rev-list --count '@{u}..HEAD' 2>/dev/null || echo '?')"
    if [ "${ahead}" = "0" ]; then
        ok "Gönderilmemiş sürüm (commit) yok"
    else
        bad "GitHub'a gönderilmemiş sürüm var (${ahead})" "git push yazınız."
    fi
fi

# 3. İki ortamın dosyaları depoda, ortamlar bu codespace'te
for e in rnaseq variants; do
    if git -C "${ws}" ls-files --error-unmatch "envs/${e}.yml" >/dev/null 2>&1; then
        ok "envs/${e}.yml depoda"
    else
        bad "envs/${e}.yml depoda yok" "Dosyayı git add ile ekleyiniz, sürüm olarak kaydediniz ve gönderiniz."
    fi
done
envs_list="$("${conda_bin}" env list 2>/dev/null)"
for e in rnaseq variants; do
    if printf '%s\n' "${envs_list}" | grep -qE "^${e}[[:space:]]"; then
        ok "${e} ortamı bu codespace'te var"
    else
        skip "${e} ortamı bu codespace'te yok" "Gerekirse conda env create -f envs/${e}.yml ile yeniden oluşturabilirsiniz; dosyanız depoda olduğu sürece ortam kaybolmaz."
    fi
done

# 4. Bitirme çalışmasının verileri
day3_files="capstone_pasilla_gene_counts.tsv.gz capstone_pasilla_samples.csv"
present=""; absent=""
for f in ${day3_files}; do
    if [ -s "${ws}/data/${f}" ]; then present="${present} ${f}"; else absent="${absent} ${f}"; fi
done
if [ ! -f "${ws}/data/SHA256SUMS" ]; then
    bad "data/SHA256SUMS bulunamadı" "Bu dosya deponuzla gelir. Eğitmene haber veriniz."
elif [ -z "${present}" ]; then
    skip "Bitirme çalışmasının verileri henüz indirilmemiş" "Sırası gelince setup/day3.sh dosyasındaki komutları yazınız (veya bash setup/day3.sh)."
else
    badsum=""
    for f in ${present}; do
        line="$(grep -E "[[:space:]]\*?${f}\$" "${ws}/data/SHA256SUMS")"
        if [ -z "${line}" ] || ! (cd "${ws}/data" && printf '%s\n' "${line}" | sha256sum -c --status - 2>/dev/null); then
            badsum="${badsum} ${f}"
        fi
    done
    if [ -n "${badsum}" ]; then
        bad "Bozuk veya eksik inmiş dosya:${badsum}" "Bu dosyaları siliniz ve setup/day3.sh dosyasındaki curl komutuyla yeniden indiriniz."
    elif [ -n "${absent}" ]; then
        bad "Eksik dosya:${absent}" "setup/day3.sh dosyasındaki ilgili curl komutunu yazınız."
    else
        ok "Bitirme çalışmasının iki dosyası indirilmiş; sağlama toplamları (checksum) doğru"
    fi
fi

printf '\n----------------------------------------\n'
printf 'geçti: %s   kaldı: %s   atlandı: %s\n' "$PASS" "$FAIL" "$SKIP"
if [ "$FAIL" -eq 0 ]; then printf 'RESULT: PASS\n\n'; exit 0; fi
printf 'RESULT: FAIL\nYukarıdaki her FAIL satırının altındaki "Düzeltme:" satırını okuyunuz, sonra bu kontrolü yeniden çalıştırınız.\n\n'; exit 1
