#!/usr/bin/env bash
# check/day1-start.sh -- 1. gün, 10:15 kontrolü (WORKSHOP.md §5 adım 7).
# RStudio'daki Terminal sekmesinde, depo klasöründe çalıştırınız: bash check/day1-start.sh
# Her şey yerindeyse check/day1-start.txt dosyasını yazar; bu dosyayı sürüm (commit)
# olarak kaydedip GitHub'a gönderdiğinizde hazır olduğunuz düzenleyiciye görünür.
PASS=0; FAIL=0; SKIP=0
ok()   { printf '  PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf '  FAIL  %s\n' "$1"; printf '        Düzeltme: %s\n' "$2"; FAIL=$((FAIL + 1)); }
skip() { printf '  SKIP  %s\n' "$1"; printf '        %s\n' "$2"; SKIP=$((SKIP + 1)); }
printf '\n1. gün başlangıç kontrolü\n\n'

marker="${HOME}/.config/bioinfo-workshop/workspace"
ws=""
[ -f "${marker}" ] && ws="$(head -n 1 "${marker}")"
[ -n "${ws}" ] || ws="$(pwd)"
conda_bin=/opt/conda/bin/conda

if [ -f "$(pwd)/bioinfo-workshop.Rproj" ] && [ "$(pwd)" = "${ws}" ]; then
    ok "Çalışma klasörünüz depo klasörüdür"
else
    bad "Çalışma klasörünüz depo klasörü değil (şu an: $(pwd))" "Terminal sekmesinde cd ${ws} yazınız, sonra bu kontrolü yeniden çalıştırınız."
fi

rver="$(Rscript -e 'cat(format(getRversion()))' 2>/dev/null)"
if [ "${rver}" = "4.6.1" ]; then
    ok "R ${rver} çalışıyor"
else
    bad "R 4.6.1 bulunamadı" "Codespace'i siliniz ve deponuzdan yeniden oluşturunuz."
fi

if [ -x "${conda_bin}" ] && "${conda_bin}" env list 2>/dev/null | grep -q '^variants-ready '; then
    ok "conda kurulu"
else
    bad "conda bulunamadı" "Codespace'i siliniz ve deponuzdan yeniden oluşturunuz."
fi

origin="$(git -C "${ws}" remote get-url origin 2>/dev/null)"
if [ -n "${origin}" ]; then
    ok "Depo GitHub'a bağlı: ${origin}"
else
    bad "Bu codespace bir GitHub deposuna bağlı değil" "Bu codespace'i siliniz ve codespace'i kendi bioinfo-workshop deponuzdan açınız (Code > Codespaces)."
fi

if [ -n "$(git config user.name 2>/dev/null)" ] && [ -n "$(git config user.email 2>/dev/null)" ]; then
    ok "git kullanıcı adı ve e-posta tanımlı"
else
    bad "git kullanıcı adı veya e-posta tanımlı değil" "Terminal sekmesinde git config --global user.name \"Adınız Soyadınız\" ve git config --global user.email \"e-posta adresiniz\" komutlarını yazınız."
fi

printf '\n----------------------------------------\n'
printf 'geçti: %s   kaldı: %s   atlandı: %s\n' "$PASS" "$FAIL" "$SKIP"
if [ "$FAIL" -eq 0 ]; then
    user="${GITHUB_USER:-$(git config user.name 2>/dev/null)}"
    {
        printf 'tarih: %s\n' "$(date '+%Y-%m-%d %H:%M %Z')"
        printf 'kullanici: %s\n' "${user}"
        printf 'RESULT: PASS\n'
    } > "${ws}/check/day1-start.txt"
    printf 'RESULT: PASS\n'
    printf 'check/day1-start.txt yazıldı. Bu dosyayı sürüm olarak kaydediniz ve GitHub'"'"'a gönderiniz.\n\n'
    exit 0
fi
printf 'RESULT: FAIL\nYukarıdaki her FAIL satırının altındaki "Düzeltme:" satırını okuyunuz, sonra bu kontrolü yeniden çalıştırınız.\n\n'; exit 1
