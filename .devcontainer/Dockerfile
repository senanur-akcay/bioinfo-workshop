# syntax=docker/dockerfile:1
#
# Image for the bioinfo-workshop codespaces (WORKSHOP.md D2, D6, D12; Phase 1).
# Built by .github/workflows/image.yml in GitHub Actions and pulled by every
# codespace from ghcr.io/onedimkurt/bioinfo-workshop:latest. Never built at
# codespace creation (no prebuilds, D1).
#
# Layers go from rarely changed to often changed, so that a change to the small
# scripts at the end does not rebuild R or conda.

FROM rocker/rstudio:4.6.1

# Pinned package sources: CRAN as of the module's sessionInfo (R20), Bioconductor 3.23.
ARG CRAN_SNAPSHOT=2026-09-18
ENV CRAN_SNAPSHOT=${CRAN_SNAPSHOT} \
    R_BIOC_VERSION=3.23 \
    TZ=Europe/Istanbul \
    LANG=C.UTF-8

# 1. Operating-system tools trainees and checkers use.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        bc ca-certificates curl file htop jq less locales nano time tree tzdata unzip zip; \
    sed -i -e 's/^# *tr_TR.UTF-8 UTF-8/tr_TR.UTF-8 UTF-8/' -e 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen; \
    locale-gen; \
    rm -rf /var/lib/apt/lists/*

# 2. R packages: binaries from the dated CRAN snapshot, Bioconductor 3.23, system
#    requirements installed by pak. The script prints every version it installed.
COPY .devcontainer/build/install-r-packages.R /tmp/install-r-packages.R
RUN Rscript /tmp/install-r-packages.R && rm -rf /tmp/* /var/lib/apt/lists/* /root/.cache

# 3. conda (Miniforge) with the two fallback environments and a package cache that
#    the trainees' own environments reuse (WORKSHOP.md §6). Everything under
#    /opt/conda is owned by rstudio, in this same layer, so that the trainee can
#    create environments and conda can hard-link from the cache.
COPY .devcontainer/build/envs/ /opt/bioinfo-workshop/envs/
COPY .devcontainer/build/condarc /opt/bioinfo-workshop/condarc
RUN set -eux; \
    curl -fsSL -o /tmp/miniforge.sh \
        https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh; \
    bash /tmp/miniforge.sh -b -p /opt/conda; \
    rm -f /tmp/miniforge.sh; \
    cp /opt/bioinfo-workshop/condarc /opt/conda/.condarc; \
    /opt/conda/bin/conda env create -f /opt/bioinfo-workshop/envs/rnaseq-ready.yml; \
    /opt/conda/bin/conda env create -f /opt/bioinfo-workshop/envs/variants-ready.yml; \
    /opt/conda/bin/conda env create -f /opt/bioinfo-workshop/envs/cache-warm.yml; \
    /opt/conda/bin/conda remove -y -n cache-warm --all; \
    /opt/conda/bin/conda clean -y --tarballs; \
    /opt/conda/bin/conda list -n rnaseq-ready --explicit > /opt/bioinfo-workshop/envs/rnaseq-ready.lock.txt; \
    /opt/conda/bin/conda list -n variants-ready --explicit > /opt/bioinfo-workshop/envs/variants-ready.lock.txt; \
    chown -R rstudio:rstudio /opt/conda; \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh

# 4. Workshop configuration: shell hook, R profile, RStudio start scripts, smoke test.
#    Small and often changed, so it comes last.
COPY .devcontainer/build/bash.bashrc.append /tmp/bash.bashrc.append
COPY .devcontainer/build/home-bashrc.append /tmp/home-bashrc.append
COPY .devcontainer/build/Rprofile.site.append /tmp/Rprofile.site.append
COPY .devcontainer/build/scripts/ /usr/local/share/bioinfo-workshop/
COPY .devcontainer/build/sudoers-rstudio-password /etc/sudoers.d/bioinfo-workshop
COPY .devcontainer/build/etc/nginx.conf /etc/bioinfo-workshop/nginx.conf
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends nginx; \
    rm -rf /var/lib/apt/lists/*; \
    mkdir -p /tmp/bioinfo-workshop-nginx; \
    nginx -t -c /etc/bioinfo-workshop/nginx.conf -e /tmp/bioinfo-workshop-nginx/error.log; \
    rm -rf /tmp/bioinfo-workshop-nginx; \
    cat /tmp/bash.bashrc.append >> /etc/bash.bashrc; \
    [ -f /home/rstudio/.bashrc ] || cp /etc/skel/.bashrc /home/rstudio/.bashrc; \
    cat /tmp/home-bashrc.append >> /home/rstudio/.bashrc; \
    cat /tmp/Rprofile.site.append >> /usr/local/lib/R/etc/Rprofile.site; \
    # renv in a Bioconductor project loads BiocManager itself while activating and then warns that
    # BiocManager "was loaded before renv activated this project" (harmless; seen in the Day-3 reference)
    echo 'RENV_CONFIG_NAMESPACES_CHECK=FALSE' >> /usr/local/lib/R/etc/Renviron.site; \
    rm -f /tmp/bash.bashrc.append /tmp/home-bashrc.append /tmp/Rprofile.site.append; \
    chmod 0755 /usr/local/share/bioinfo-workshop/*.sh; \
    chown root:root /usr/local/share/bioinfo-workshop/start-rstudio-password.sh; \
    chmod 0440 /etc/sudoers.d/bioinfo-workshop; \
    visudo -cf /etc/sudoers.d/bioinfo-workshop; \
    mkdir -p /home/rstudio/.config/rstudio /home/rstudio/.local/share/rstudio-server; \
    jq '. + {"save_workspace": "never", "load_workspace": false, "always_save_history": false, "posix_terminal_shell": "bash"}' \
        /home/rstudio/.config/rstudio/rstudio-prefs.json > /tmp/prefs.json; \
    mv /tmp/prefs.json /home/rstudio/.config/rstudio/rstudio-prefs.json; \
    chown -R rstudio:rstudio /home/rstudio; \
    date '+%Y-%m-%d %H:%M %Z' > /usr/local/share/bioinfo-workshop/IMAGE_BUILT
