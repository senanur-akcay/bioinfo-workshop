#!/usr/bin/env bash
# keep-awake.sh -- second half of the codespace's postAttachCommand, after start-rstudio.sh.
# It runs in a VS Code terminal for as long as the VS Code tab is attached.
#
# Why (R62, measured 2026-10-05): GitHub counts only the VS Code tab and VS Code terminals as
# activity. Thirty minutes of work in the RStudio tab alone (editor, Console, RStudio's
# Terminal) ended with "Your codespace will be stopped soon due to inactivity" and a stopped
# machine. Every interactive bash prompt and every R command now touches a marker file
# (bash.bashrc.append, Rprofile.site.append); when the marker has changed since the last look,
# this script prints one line, and that terminal output resets the idle timer. When nobody
# types or runs anything, nothing is printed and the idle timer stops the codespace as before.
marker=/tmp/bioinfo-workshop-activity
interval="${KEEP_AWAKE_INTERVAL:-60}"
touch "${marker}" 2>/dev/null || true
echo "[bioinfo-workshop] Bu terminal, RStudio'da çalıştığınız sürece codespace'i açık tutar."
echo "[bioinfo-workshop] VS Code sekmesini arka planda açık bırakınız; bu terminali kapatmayınız."
last="$(stat -c %Y "${marker}" 2>/dev/null || echo 0)"
while sleep "${interval}"; do
    now="$(stat -c %Y "${marker}" 2>/dev/null || echo 0)"
    if [ "${now}" != "${last}" ]; then
        printf '[bioinfo-workshop] RStudio in use, %s\n' "$(date -u +%H:%M) UTC"
        last="${now}"
    fi
done
