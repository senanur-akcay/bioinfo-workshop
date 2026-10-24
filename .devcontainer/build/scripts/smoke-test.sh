#!/usr/bin/env bash
# smoke-test.sh -- run by .github/workflows/image.yml inside the freshly built image,
# as user rstudio, before anything is pushed. Every FAIL stops the push.
# It also prints the facts the next steps need: tool versions (to pin envs/README.md),
# disk sizes, conda timings, RStudio start.
set -uo pipefail
fails=0

check() {
    local name="$1"; shift
    local out
    if out="$("$@" 2>&1)"; then
        printf 'PASS  %-38s %s\n' "${name}" "$(printf '%s' "${out}" | tail -n 1)"
    else
        printf 'FAIL  %-38s\n%s\n' "${name}" "$(printf '%s' "${out}" | tail -n 25)"
        fails=$((fails + 1))
    fi
}

echo "== bioinfo-workshop image smoke test =="
echo "image built: $(cat /usr/local/share/bioinfo-workshop/IMAGE_BUILT)"

# --- user, R, packages -------------------------------------------------------
check "runs as rstudio"                bash -c '[ "$(id -un)" = rstudio ] && id'
check "R is 4.6.1"                     Rscript -e 'stopifnot(getRversion() == "4.6.1"); cat(R.version.string, "\n")'
check "Rprofile.site parses"           Rscript -e 'invisible(parse("/usr/local/lib/R/etc/Rprofile.site")); cat("ok\n")'
check "CRAN option is the snapshot"    Rscript -e 'r <- getOption("repos")[["CRAN"]]; stopifnot(grepl("2026-09-18", r)); cat(r, "\n")'
check "R packages load"                Rscript -e 'for (p in c("tidyverse", "Seurat", "patchwork", "pheatmap", "ggrepel", "DESeq2", "tximport", "apeglm", "glmGamPoi", "renv", "rstudioapi", "rmarkdown")) suppressPackageStartupMessages(library(p, character.only = TRUE)); cat("all loaded\n")'
check "rstudio can install R packages" bash -c '[ -w /usr/local/lib/R/site-library ] && echo writable'
check "locale tr_TR.UTF-8 exists"      bash -c 'locale -a | grep -i "^tr_TR.utf8$"'
check "quarto present"                 quarto --version

# --- conda -------------------------------------------------------------------
check "conda in interactive bash"      bash -ic 'conda --version'
check "base active, prompt (base)"     bash -ic '[ "${CONDA_DEFAULT_ENV:-}" = base ] && case "$PS1" in "(base) "*) echo "base; prompt starts with (base)";; *) echo "prompt: $PS1"; false;; esac'
check "same in a login shell (RStudio)" bash -lic '[ "${CONDA_DEFAULT_ENV:-}" = base ] && case "$PS1" in "(base) "*) echo "base; prompt starts with (base)";; *) echo "prompt: $PS1"; false;; esac'
check "activate shows the new name"     bash -ic 'conda activate rnaseq-ready && case "$PS1" in "(rnaseq-ready) "*) echo "prompt starts with (rnaseq-ready)";; *) echo "prompt: $PS1"; false;; esac'
# A terminal RStudio restores after a stop inherits the old conda variables (no prompt).
check "restored terminal: (base) shown"  bash -c 'env CONDA_DEFAULT_ENV=base CONDA_SHLVL=1 CONDA_PREFIX=/opt/conda PATH="/opt/conda/bin:$PATH" bash -ic '"'"'case "$PS1" in "(base) "*) echo "prompt starts with (base)";; *) echo "prompt: $PS1"; false;; esac'"'"''
check "restored terminal: env kept, shown" bash -c 'env CONDA_DEFAULT_ENV=rnaseq-ready CONDA_SHLVL=2 CONDA_PREFIX=/opt/conda/envs/rnaseq-ready CONDA_PREFIX_1=/opt/conda PATH="/opt/conda/envs/rnaseq-ready/bin:/opt/conda/bin:$PATH" bash -ic '"'"'case "$PS1" in "(rnaseq-ready) "*) command -v salmon;; *) echo "prompt: $PS1"; false;; esac'"'"''
check "conda in login bash"            bash -lc 'type conda >/dev/null && echo function'
check "two fallback environments"      bash -ic 'n=$(conda env list | grep -cE "^(rnaseq-ready|variants-ready) "); [ "$n" -eq 2 ] && conda env list | grep -v "^#" | tr -s " " | tr "\n" ";"'
check "names rnaseq/variants are free" bash -ic '! conda env list | grep -qE "^(rnaseq|variants) "'
check "channels conda-forge, bioconda" bash -ic 'conda config --show channels | tr "\n" " " | grep -q "conda-forge.*bioconda" && echo ok'
check "/opt/conda writable by rstudio" bash -c '[ -w /opt/conda/envs ] && [ -w /opt/conda/pkgs ] && echo writable'
for spec in "rnaseq-ready salmon" "rnaseq-ready fastp" "rnaseq-ready fastqc" "rnaseq-ready multiqc" \
            "variants-ready bwa" "variants-ready samtools" "variants-ready bcftools" "variants-ready bgzip" \
            "variants-ready tabix" "variants-ready fastp" "variants-ready fastqc" "variants-ready multiqc"; do
    set -- ${spec}
    check "tool $2 in $1" bash -ic "conda activate $1 && command -v $2"
done
check "R Console does not see conda tools" Rscript -e 'stopifnot(!nzchar(Sys.which("salmon"))); cat("salmon not on R PATH, as taught\n")'

echo
echo "== solved versions (for envs/README.md and the pinned build files) =="
for e in rnaseq-ready variants-ready; do
    echo "-- ${e}"
    bash -ic "conda list -n ${e} '^(salmon|fastp|fastqc|multiqc|bwa|samtools|bcftools|htslib|openjdk|python)$'" 2>/dev/null | grep -v '^#'
done
echo "-- package cache: seqkit, seqtk"
ls -d /opt/conda/pkgs/seqkit-* /opt/conda/pkgs/seqtk-* 2>/dev/null

echo
echo "== live exercise timings (WORKSHOP.md §6 step 3) =="
start=$(date +%s)
check "conda create deneme --offline"  bash -ic 'conda create -y -q -n deneme --offline seqkit >/dev/null && conda activate deneme && seqkit version'
echo "      took $(( $(date +%s) - start )) s"
check "remove deneme"                  bash -ic 'conda remove -y -q -n deneme --all >/dev/null && ! conda env list | grep -q "^deneme " && echo removed'
start=$(date +%s)
check "conda create deneme (online)"   bash -ic 'conda create -y -q -n deneme seqkit >/dev/null && conda activate deneme && seqkit version'
echo "      took $(( $(date +%s) - start )) s"
check "export --from-history"          bash -ic 'conda env export -n deneme --from-history | grep -q seqkit && echo has-seqkit'
# The command the trainees are taught (day1-envs.sh fix text): conda env remove -n deneme
check "conda env remove -n deneme"     bash -ic 'yes | conda env remove -n deneme >/dev/null 2>&1; ! conda env list | grep -q "^deneme " && echo removed'
bash -ic 'conda remove -y -q -n deneme --all' >/dev/null 2>&1

# --- RStudio -----------------------------------------------------------------
echo
echo "== RStudio =="
check "on-create writes prefs"         bash -c 'mkdir -p /tmp/ws && /usr/local/share/bioinfo-workshop/on-create.sh /tmp/ws >/dev/null && jq -r .initial_working_directory ~/.config/rstudio/rstudio-prefs.json | grep -qx /tmp/ws && echo /tmp/ws'
check "start-rstudio.sh starts RStudio"  /usr/local/share/bioinfo-workshop/start-rstudio.sh
check "RStudio itself on 127.0.0.1:8788"   bash -c 'curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8788/ | grep -E "^(200|302)$"'
check "proxy on 8787 answers"            bash -c 'curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8787/ | grep -E "^(200|302)$"'
# Codespaces forwards with "Host: localhost:8787"; every redirect must stay relative.
# RStudio sends curl to unsupported_browser.htm, so the browser flow uses a Chrome user agent.
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36"
export UA
check "redirects stay relative (curl)"   bash -c 'curl -s -D - -o /dev/null -H "Host: localhost:8787" http://127.0.0.1:8787/ | grep -i "^location:" | tr -d "\r" | tee /tmp/locs0; ! grep -qi "://" /tmp/locs0 && echo "relative"'
check "redirects stay relative (Chrome)" bash -c 'rm -f /tmp/jar /tmp/hdr; curl -s -L --max-redirs 6 -A "$UA" -c /tmp/jar -b /tmp/jar -H "Host: localhost:8787" -D /tmp/hdr -o /dev/null http://127.0.0.1:8787/; grep -i "^location:" /tmp/hdr | tr -d "\r" | sort | uniq -c | tee /tmp/locs; ! grep -qi "://" /tmp/locs && echo "relative: $(tr -s " " < /tmp/locs | tr "\n" ";")"'
# A browser keeps a cookie only if it has no Domain attribute pointing elsewhere (the
# browser's host is ...-8787.app.github.dev, RStudio sees localhost:8787).
check "sign-in cookie names rstudio"     bash -c 'curl -s -D /tmp/h2 -o /dev/null -A "$UA" -H "Host: localhost:8787" "http://127.0.0.1:8787/auth-sign-in?appUri=%2F"; tr -d "\r" < /tmp/h2 | grep -i -e "^HTTP" -e "^location:" -e "^set-cookie:" | tee /tmp/h2s; grep -qi "^set-cookie: *user-id=rstudio|" /tmp/h2s && ! grep -i "^set-cookie:" /tmp/h2s | grep -qi "domain=" && echo "user-id=rstudio, no Domain attribute"'
check "sign-in leads to the IDE"         bash -c 'ck=$(sed -n "s/^[Ss]et-[Cc]ookie: *\([^;]*\).*/\1/p" /tmp/h2s | paste -sd ";" -); code=$(curl -s -o /tmp/page.html -w "%{http_code}" -A "$UA" -H "Host: localhost:8787" -H "Cookie: ${ck}" http://127.0.0.1:8787/); echo "GET / with the sign-in cookie: ${code}"; [ "${code}" = 200 ] && grep -qi "rstudio" /tmp/page.html && ! grep -qi "sign in to rstudio" /tmp/page.html && echo "IDE page, $(wc -c < /tmp/page.html) bytes"'
echo "      (for the record) sign-in response through the proxy:"
sed 's/^/        /' /tmp/h2s 2>/dev/null
check "second start is a no-op"          /usr/local/share/bioinfo-workshop/start-rstudio.sh
# R86: the codespace's variables (dummy values here) must reach an R session that
# starts with a clean environment, as RStudio's sessions do.
cat > /tmp/session-env-test.sh <<'EOS'
set -u
export GITHUB_TOKEN=smoke-not-a-token GITHUB_USER=smoke-user CODESPACES=true
export GIT_COMMITTER_NAME="Smoke O'Test"
/usr/local/share/bioinfo-workshop/start-rstudio.sh >/dev/null
f="$HOME/.local/share/rstudio-server/session.env"
[ "$(stat -c %a "$f")" = 600 ] || { echo "session.env mode is $(stat -c %a "$f"), not 600"; exit 1; }
env -i HOME="$HOME" PATH=/usr/local/bin:/usr/bin:/bin Rscript -e '
  stopifnot(Sys.getenv("GITHUB_USER") == "smoke-user",
            Sys.getenv("GITHUB_TOKEN") == "smoke-not-a-token",
            Sys.getenv("GIT_COMMITTER_NAME") == "Smoke O'"'"'Test",
            Sys.getenv("CODESPACES") == "true")
  cat("mode 600; the variables arrive in a clean R session\n")'
env -i HOME="$HOME" PATH=/usr/local/bin:/usr/bin:/bin GITHUB_USER=already-set Rscript -e '
  stopifnot(Sys.getenv("GITHUB_USER") == "already-set"); cat("an existing value is kept\n")'
EOS
check "codespace variables reach R"      bash /tmp/session-env-test.sh
echo "      (for the record) RStudio's own sign-in redirect without the proxy:"
curl -s -D - -o /dev/null -H "Host: localhost:8787" "http://127.0.0.1:8788/auth-sign-in?appUri=%2F" | grep -i "^location:" | sed 's/^/        /'
# R62: work in the RStudio tab must leave a trace that keep-awake.sh turns into VS Code
# terminal output (GitHub counts only that). Bash prompts and R commands touch the marker.
check "bash prompt touches the marker"  bash -c 'rm -f /tmp/bioinfo-workshop-activity; bash -ic "eval \"\$PROMPT_COMMAND\"" >/dev/null 2>&1; [ -f /tmp/bioinfo-workshop-activity ] && echo touched'
check "R command touches the marker"    bash -c 'rm -f /tmp/bioinfo-workshop-activity; echo "x <- 1" | R --interactive --quiet --no-save >/dev/null 2>&1; [ -f /tmp/bioinfo-workshop-activity ] && echo touched'
check "keep-awake prints on activity"   bash -c '( KEEP_AWAKE_INTERVAL=1 timeout 4 /usr/local/share/bioinfo-workshop/keep-awake.sh > /tmp/ka.out & sleep 1.5; touch -d "+5 seconds" /tmp/bioinfo-workshop-activity; wait ); grep -c "RStudio in use" /tmp/ka.out | grep -qx 1 && echo "one line after one change"'
check "keep-awake silent when idle"     bash -c 'KEEP_AWAKE_INTERVAL=1 timeout 3 /usr/local/share/bioinfo-workshop/keep-awake.sh > /tmp/ka2.out; ! grep -q "RStudio in use" /tmp/ka2.out && echo "nothing printed"'
check "sudo rule is narrow"            bash -c 'sudo -n -l | grep -q start-rstudio-password.sh && ! sudo -n true 2>/dev/null && echo only-the-script'

echo
echo "== sizes =="
du -sh /opt/conda /opt/conda/pkgs /usr/local/lib/R/site-library 2>/dev/null
df -h / | tail -n 1

echo
if [ "${fails}" -eq 0 ]; then
    echo "SMOKE TEST: PASS"
    exit 0
fi
echo "SMOKE TEST: FAIL (${fails})"
exit 1
