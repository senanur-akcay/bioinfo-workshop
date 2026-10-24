#!/usr/bin/env bash
# check/preflight.sh -- atölyeden bir hafta önceki ön kontrol (WORKSHOP.md §5 adım 3).
# RStudio'daki Terminal sekmesinde, depo klasöründe çalıştırınız: bash check/preflight.sh
# Hiçbir şeyi değiştirmez; yalnızca okur ve sınar.
PASS=0; FAIL=0; SKIP=0
ok()   { printf '  PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf '  FAIL  %s\n' "$1"; printf '        Düzeltme: %s\n' "$2"; FAIL=$((FAIL + 1)); }
skip() { printf '  SKIP  %s\n' "$1"; printf '        %s\n' "$2"; SKIP=$((SKIP + 1)); }
printf '\nÖn kontrol (pre-flight)\n\n'

marker="${HOME}/.config/bioinfo-workshop/workspace"
ws=""
[ -f "${marker}" ] && ws="$(head -n 1 "${marker}")"
[ -n "${ws}" ] || ws="$(pwd)"
conda_bin=/opt/conda/bin/conda

# 1. Çalışma klasörü
if [ -f "$(pwd)/bioinfo-workshop.Rproj" ] && [ "$(pwd)" = "${ws}" ]; then
    ok "Çalışma klasörünüz depo klasörüdür ($(pwd))"
else
    bad "Çalışma klasörünüz depo klasörü değil (şu an: $(pwd))" "Terminal sekmesinde cd ${ws} yazınız, sonra bu kontrolü yeniden çalıştırınız."
fi

# 2. R
rver="$(Rscript -e 'cat(format(getRversion()))' 2>/dev/null)"
if [ "${rver}" = "4.6.1" ]; then
    ok "R ${rver} çalışıyor"
else
    bad "R 4.6.1 bulunamadı (bulunan: ${rver:-yok})" "Bu codespace atölye şablonundan açılmamış olabilir. Codespace'i siliniz ve kendi bioinfo-workshop deponuzdan yeniden oluşturunuz."
fi

# 3. Paketler
printf '        (paketler yükleniyor, yaklaşık 20 saniye sürer)\n'
if Rscript -e 'for (p in c("tidyverse", "DESeq2", "Seurat")) suppressPackageStartupMessages(library(p, character.only = TRUE))' >/dev/null 2>&1; then
    ok "Atölye paketleri yükleniyor (tidyverse, DESeq2, Seurat)"
else
    bad "Atölye paketlerinden biri yüklenemedi" "Codespace'i siliniz ve deponuzdan yeniden oluşturunuz. Sorun sürerse nedim.kurt@outlook.com adresine yazınız."
fi

# 4. conda
if [ -x "${conda_bin}" ] && "${conda_bin}" env list 2>/dev/null | grep -q '^rnaseq-ready ' && "${conda_bin}" env list 2>/dev/null | grep -q '^variants-ready '; then
    ok "conda kurulu; yedek ortamlar (environment) hazır"
else
    bad "conda veya yedek ortamlar bulunamadı" "Codespace'i siliniz ve deponuzdan yeniden oluşturunuz."
fi

# 5. Depo: kendi hesabınızdaki depo mu
origin="$(git -C "${ws}" remote get-url origin 2>/dev/null)"
owner="$(printf '%s' "${origin}" | sed -E 's#^https://github.com/([^/]+)/.*#\1#; s#^git@github.com:([^/]+)/.*#\1#')"
if [ -z "${origin}" ]; then
    bad "Bu codespace bir GitHub deposuna bağlı değil" "Codespace büyük olasılıkla \"Use this template > Open in a codespace\" ile açıldı. Bu codespace'i siliniz. Önce kendi deponuzu oluşturunuz (README, 3. adım), sonra codespace'i o depodan açınız (Code > Codespaces, 4. adım)."
elif [ "${owner}" = "onedimkurt" ] && [ "${GITHUB_USER:-onedimkurt}" != "onedimkurt" ]; then
    bad "Bu codespace atölye şablonundan açılmış, kendi deponuzdan değil" "Önce şablonda Use this template > Create a new repository ile kendi deponuzu oluşturunuz; codespace'i o depodan açınız."
else
    ok "Depo kendi hesabınızda: ${origin}"
fi

# 6. git kimliği
gname="$(git config user.name 2>/dev/null)"; gmail="$(git config user.email 2>/dev/null)"
if [ -n "${gname}" ] && [ -n "${gmail}" ]; then
    ok "git kullanıcı adı ve e-posta tanımlı (${gname})"
else
    bad "git kullanıcı adı veya e-posta tanımlı değil" "Terminal sekmesinde git config --global user.name \"Adınız Soyadınız\" ve git config --global user.email \"e-posta adresiniz\" komutlarını yazınız."
fi

# 7. Gönderme izni
if [ -n "${origin}" ] && GIT_TERMINAL_PROMPT=0 timeout 40 git -C "${ws}" push --dry-run origin HEAD >/dev/null 2>&1; then
    ok "GitHub'a gönderme (push) izni var"
elif [ -z "${origin}" ]; then
    skip "GitHub'a gönderme (push) izni" "Depo bağlantısı olmadığı için sınanmadı (madde 5)."
else
    bad "GitHub'a gönderme (push) denemesi başarısız" "İnternet bağlantınızı kontrol ediniz. Sorun sürerse codespace'i kendi deponuzdan yeniden oluşturunuz."
fi

# 8. Makine
cores="$(nproc 2>/dev/null || echo 0)"
mem_kb="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null)"
mem_gb=$(( (${mem_kb:-0} + 524288) / 1048576 ))
if [ "${cores}" -ge 2 ] && [ "${mem_kb:-0}" -ge 7000000 ]; then
    ok "Makine: ${cores} çekirdek, yaklaşık ${mem_gb} GB bellek"
else
    bad "Makine küçük: ${cores} çekirdek, ${mem_gb} GB bellek" "Codespace'i siliniz; yeniden oluştururken 2-core makineyi seçiniz."
fi

# 9. Disk
free_gb="$(df -BG --output=avail "${ws}" 2>/dev/null | tail -n 1 | tr -dc '0-9')"
if [ -n "${free_gb}" ] && [ "${free_gb}" -ge 10 ]; then
    ok "Diskte ${free_gb} GB boş yer var"
else
    bad "Diskte 10 GB'tan az boş yer var (${free_gb:-?} GB)" "results/ klasöründeki büyük dosyaları siliniz veya codespace'i yeniden oluşturunuz."
fi

printf '\n----------------------------------------\n'
printf 'geçti: %s   kaldı: %s   atlandı: %s\n' "$PASS" "$FAIL" "$SKIP"
if [ "$FAIL" -eq 0 ]; then printf 'RESULT: PASS\n\n'; exit 0; fi
printf 'RESULT: FAIL\nYukarıdaki her FAIL satırının altındaki "Düzeltme:" satırını okuyunuz, sonra bu kontrolü yeniden çalıştırınız.\n\n'; exit 1
