#!/usr/bin/env bash
# e2e-trainee.sh -- organiser-only end-to-end test of every SETUP step a trainee performs
# (README pre-flight, WORKSHOP.md §5 steps 6-8 and 13-15, §6). Not analysis: Phase 2.
#
# Source it from the repository folder in an interactive bash, as a trainee's terminal:
#     . .github/e2e/e2e-trainee.sh pre day1      (first codespace)
#     . .github/e2e/e2e-trainee.sh day2 day3     (after the Day-2 recreate on 4-core)
# Every step prints PASS/FAIL, seconds and what it checked; the log goes to results/e2e.log
# (results/ is not tracked). Removed from the template at the freeze (ORGANISER.md §2, R84).

e2e_main() {
    local LOG="results/e2e.log" P=0 F=0
    mkdir -p results
    printf '\n== e2e %s  %s  %s ==\n' "$*" "$(date '+%F %T %Z')" "$(hostname)" | tee -a "$LOG"

    st() {  # st ID "what is checked" function
        local id="$1" what="$2" fn="$3" t0 rc out dt
        t0=$(date +%s)
        out="$($fn 2>&1)"; rc=$?
        dt=$(( $(date +%s) - t0 ))
        if [ "$rc" -eq 0 ]; then P=$((P + 1)); printf '%-6s PASS %4ss  %s\n' "$id" "$dt" "$what" | tee -a "$LOG"
        else F=$((F + 1)); printf '%-6s FAIL %4ss  %s\n' "$id" "$dt" "$what" | tee -a "$LOG"
             printf '%s\n' "$out" | tail -n 20 | sed 's/^/          | /' | tee -a "$LOG"; fi
        printf '%s\n' "$out" | tail -n 40 | sed "s/^/  [$id] /" >> "$LOG.detail"
    }
    pushed() { [ "$(git rev-parse HEAD)" = "$(git ls-remote origin refs/heads/main | cut -f1)" ]; }
    commit_push() { git add -A && git commit -q -m "$1" && GIT_TERMINAL_PROMPT=0 timeout 60 git push -q && pushed; }

    local phase
    for phase in "$@"; do case "${phase}" in
    pre)
        p1() { [ -f bioinfo-workshop.Rproj ] && [ "$(pwd)" = "$(head -n1 ~/.config/bioinfo-workshop/workspace)" ] && pwd; }
        p2() { case "${PS1:-}" in "(base) "*) echo "prompt starts with (base)";; *) echo "prompt: ${PS1:-}"; false;; esac; }
        p3() { local o; o="$(bash check/preflight.sh)"; printf '%s\n' "$o"; printf '%s\n' "$o" | grep -q '^RESULT: PASS$' && ! printf '%s\n' "$o" | grep -q '^  FAIL'; }
        p4() { Rscript -e 'stopifnot(!nzchar(Sys.which("salmon"))); cat("R does not see conda tools\n")'; }
        p5() { git check-ignore -q data/x.fastq.gz && git check-ignore -q results/x.png && git check-ignore -q .Rproj.user/x && ! git check-ignore -q envs/rnaseq.yml && echo "data/, results/, .Rproj.user ignored; envs/ tracked"; }
        st P1 "Terminal opens in the repository folder" p1
        st P2 "First prompt shows (base)" p2
        st P3 "bash check/preflight.sh -> RESULT: PASS, no FAIL" p3
        st P4 "R Console does not see conda tools" p4
        st P5 ".gitignore: data/, results/ out; envs/ in" p5
        ;;
    day1)
        d1() { git status | grep -q "nothing to commit, working tree clean" && echo clean; }
        d2() { local l; l="$(conda env list)"; printf '%s\n' "$l"; printf '%s\n' "$l" | grep -qE '^base ' && printf '%s\n' "$l" | grep -qE '^rnaseq-ready ' && printf '%s\n' "$l" | grep -qE '^variants-ready ' && ! printf '%s\n' "$l" | grep -qE '^(rnaseq|variants|deneme) '; }
        d3() { bash check/day1-start.sh && grep -q '^RESULT: PASS$' check/day1-start.txt; }
        d4() { commit_push "Day 1 start"; }
        d5() { conda config --show channels | tr '\n' ' ' | grep -q 'conda-forge.*bioconda' && echo "conda-forge, bioconda"; }
        d6() { conda create -y -n deneme -c bioconda seqkit; }
        d7() { conda activate deneme && [ "$(command -v seqkit)" = /opt/conda/envs/deneme/bin/seqkit ] && seqkit version; }
        d8() { conda activate deneme && conda deactivate && ! command -v seqkit && echo "seqkit gone after deactivate"; }
        d9() { conda list -n variants-ready | grep -E '^bcftools '; }
        d10() { conda install -y -n deneme -c bioconda seqtk; }
        d11() { conda env export -n deneme --from-history > envs/deneme.yml && cat envs/deneme.yml && grep -q seqkit envs/deneme.yml && grep -q seqtk envs/deneme.yml && ! grep -qE '=[0-9].*=' envs/deneme.yml; }
        d11b() { conda env create -q -n deneme-kopya -f envs/deneme.yml >/dev/null && conda activate deneme-kopya && command -v seqkit seqtk && conda deactivate && conda remove -y -q -n deneme-kopya --all >/dev/null && echo "the exported file rebuilds the environment"; }
        d12() { conda env list | grep -qE '^deneme ' || { echo "deneme did not exist before the removal"; return 1; }; yes | conda env remove -n deneme >/dev/null 2>&1; conda env list >/dev/null && ! conda env list | grep -qE '^deneme ' && echo "deneme removed"; }
        d13() { printf 'name: rnaseq\nchannels:\n  - conda-forge\n  - bioconda\ndependencies:\n  - salmon=2.8.0\n  - fastp=1.3.7\n  - fastqc=0.12.1\n  - multiqc=1.35\n' > envs/rnaseq.yml && conda env create -f envs/rnaseq.yml; }
        d14() { conda activate rnaseq && salmon --version 2>&1 | grep -x 'salmon 2.8.0' && fastp --version 2>&1 | grep -q '1.3.7' && multiqc --version | grep -q '1.35'; }
        d15() { bash check/day1-envs.sh; }
        d16() { bash setup/day1.sh > results/setup-day1.out 2>&1; local rc=$?; tail -n 8 results/setup-day1.out; [ $rc -eq 0 ] && [ "$(grep -c ': OK$' results/setup-day1.out)" -ge 14 ] && [ "$(ls -d data/quant/SRR* | wc -l)" -eq 6 ]; }
        d17() { [ -z "$(git status --porcelain data results)" ] && echo "downloads and outputs stay out of git"; }
        d18() { mkdir -p scripts && echo '# 1. gün betiği (e2e test)' > scripts/day1.R && echo '# 1. gün komutları (e2e test)' > scripts/day1.sh && commit_push "Day 1: envs and scripts"; }
        st D1.1  "git status: nothing to commit" d1
        st D1.2  "conda env list: base, rnaseq-ready, variants-ready; rnaseq/variants/deneme free" d2
        st D1.3  "bash check/day1-start.sh -> PASS, writes check/day1-start.txt" d3
        st D1.4  "git add, commit, push (no prompt) -> on GitHub" d4
        st D1.5  "conda config --show channels: conda-forge then bioconda" d5
        st D1.6  "conda create -n deneme -c bioconda seqkit" d6
        st D1.7  "conda activate deneme; which seqkit; seqkit version" d7
        st D1.8  "conda deactivate -> seqkit no longer found" d8
        st D1.9  "conda list -n variants-ready shows bcftools" d9
        st D1.10 "conda install -n deneme -c bioconda seqtk" d10
        st D1.11 "conda env export --from-history > envs/deneme.yml (seqkit, seqtk, no build strings)" d11
        st D1.11b "the exported envs/deneme.yml rebuilds the environment under a new name" d11b
        st D1.12 "conda env remove -n deneme" d12
        st D1.13 "write envs/rnaseq.yml from envs/README.md; conda env create -f" d13
        st D1.14 "conda activate rnaseq: salmon 2.8.0, fastp 1.3.7, multiqc 1.35" d14
        st D1.15 "bash check/day1-envs.sh -> PASS" d15
        st D1.16 "bash setup/day1.sh: 14 files OK, 6 quant folders" d16
        st D1.17 "data/ and results/ do not show in git status" d17
        st D1.18 "commit and push envs/ and scripts/" d18
        ;;
    day2)
        e1() { git status | grep -q "nothing to commit, working tree clean" && git ls-files --error-unmatch scripts/day1.R envs/rnaseq.yml check/day1-start.txt; }
        e2() { ! conda env list | grep -qE '^(rnaseq|deneme) ' && echo "a new codespace: Day-1 environments are gone, files came back"; }
        e3() { local o; o="$(bash check/day2-setup.sh)"; printf '%s\n' "$o"; printf '%s\n' "$o" | grep -q '^RESULT: PASS$' && printf '%s\n' "$o" | grep -q 'PASS  Makine'; }
        e4() { bash setup/day2.sh > results/setup-day2.out 2>&1; local rc=$?; tail -n 6 results/setup-day2.out; [ $rc -eq 0 ] && [ -s data/filtered_gene_bc_matrices/hg19/matrix.mtx ]; }
        e5() { printf 'name: variants\nchannels:\n  - conda-forge\n  - bioconda\ndependencies:\n  - bwa=0.7.19\n  - samtools=1.24\n  - bcftools=1.24\n  - htslib=1.24\n  - fastp=1.3.7\n  - fastqc=0.12.1\n  - multiqc=1.35\n' > envs/variants.yml && conda env create -f envs/variants.yml; }
        e6() { conda activate variants && samtools --version | grep -q '^samtools 1.24' && bcftools --version | grep -q '^bcftools 1.24' && command -v bgzip tabix bwa && echo "variants env works"; }
        e7() { local o; o="$(bash check/day2-setup.sh)"; printf '%s\n' "$o"; printf '%s\n' "$o" | grep -q '^RESULT: PASS$' && ! printf '%s\n' "$o" | grep -q '^  SKIP'; }
        e8() { echo '# 2. gün (e2e test)' > scripts/day2.sh && echo '# 2. gün (e2e test)' > scripts/day2.R && commit_push "Day 2: variants env and scripts"; }
        st D2.1 "after the recreate: clean, Day-1 files back from GitHub" e1
        st D2.2 "Day-1 environments are gone in the new codespace" e2
        st D2.3 "bash check/day2-setup.sh -> PASS (4-core machine)" e3
        st D2.4 "bash setup/day2.sh: files OK, PBMC matrix unpacked" e4
        st D2.5 "write envs/variants.yml; conda env create -f" e5
        st D2.6 "conda activate variants: samtools/bcftools 1.24, bwa, bgzip, tabix" e6
        st D2.7 "bash check/day2-setup.sh -> PASS, nothing skipped" e7
        st D2.8 "commit and push Day-2 files" e8
        ;;
    day3)
        f1() { bash setup/day3.sh > results/setup-day3.out 2>&1; local rc=$?; tail -n 4 results/setup-day3.out; [ $rc -eq 0 ] && grep -q 'capstone_pasilla_samples.csv: OK' results/setup-day3.out; }
        f2() { conda env export -n variants --from-history > envs/variants.yml && conda list -n variants --explicit > envs/variants.lock.txt && grep -q bcftools envs/variants.yml && grep -q '^@EXPLICIT' envs/variants.lock.txt && echo "portable file and explicit lock written"; }
        f3() { Rscript -e 'si <- sessionInfo(); cat(si$R.version$version.string, "\n"); stopifnot(getRversion() == "4.6.1")'; }
        f4() { Rscript -e 'install.packages("praise", lib = tempfile("lib")); cat("binary install from the snapshot OK\n")' 2>&1 | tail -n 3; }
        f5() { commit_push "Day 3: reproducibility files"; }
        f6() { local o; o="$(bash check/day3-setup.sh)"; printf '%s\n' "$o"; printf '%s\n' "$o" | grep -q '^RESULT: PASS$'; }
        f7() { [ "$(git log --oneline origin/main | wc -l)" -ge 5 ] && git log --oneline origin/main | head -n 6; }
        st D3.1 "bash setup/day3.sh: capstone files OK" f1
        st D3.2 "conda env export --from-history and conda list --explicit" f2
        st D3.3 "sessionInfo(): R 4.6.1" f3
        st D3.4 "install.packages() of a small package from the snapshot" f4
        st D3.5 "commit and push" f5
        st D3.6 "bash check/day3-setup.sh -> PASS" f6
        st D3.7 "history on GitHub has every day's commits" f7
        ;;
    *) echo "unknown phase: ${phase}" | tee -a "$LOG"; F=$((F + 1));;
    esac; done
    printf '== e2e result: %s PASS, %s FAIL ==\n' "$P" "$F" | tee -a "$LOG"
    [ "$F" -eq 0 ]
}
e2e_main "$@"
