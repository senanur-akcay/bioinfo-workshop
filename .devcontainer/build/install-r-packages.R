# install-r-packages.R -- runs once, as root, during the image build (Dockerfile step 2).
# CRAN packages come as Linux binaries from a dated Posit Package Manager snapshot;
# Bioconductor packages from release 3.23 (R_BIOC_VERSION); pak installs the system
# libraries they need. The script ends by loading every package and printing its
# version, so the build log is the record of what the image contains.

snapshot <- Sys.getenv("CRAN_SNAPSHOT")
if (!nzchar(snapshot)) stop("CRAN_SNAPSHOT is not set")
cran <- sprintf("https://p3m.dev/cran/__linux__/noble/%s", snapshot)
options(repos = c(CRAN = cran), Ncpus = max(1L, parallel::detectCores()))
cat("CRAN snapshot:", cran, "\n")
cat("Bioconductor:", Sys.getenv("R_BIOC_VERSION"), "\n")

install.packages(
  "pak",
  repos = sprintf(
    "https://r-lib.github.io/p/pak/stable/%s/%s/%s",
    .Platform$pkgType, R.Version()$os, R.Version()$arch
  )
)

cran_pkgs <- c(
  "tidyverse", "Seurat", "SeuratObject", "patchwork", "pheatmap", "ggrepel",
  "cowplot", "data.table", "R.utils", "renv", "BiocManager", "rstudioapi",
  "knitr", "rmarkdown",
  # not needed to run Seurat, but renv::init() records them as requirements (Day 3)
  "dqrng", "progress", "RcppProgress"
)
# BiocVersion: renv::init() on Day 3 needs it to record Bioconductor packages without errors
bioc_pkgs <- c("DESeq2", "tximport", "apeglm", "glmGamPoi", "BiocVersion")

Sys.setenv(PKG_SYSREQS = "true")
pak::pkg_install(c(cran_pkgs, paste0("bioc::", bioc_pkgs)), ask = FALSE, upgrade = FALSE)

cat("\n==== installed versions ====\n")
cat(R.version.string, "\n")
failed <- character(0)
for (p in c(cran_pkgs, bioc_pkgs)) {
  ok <- suppressPackageStartupMessages(requireNamespace(p, quietly = TRUE))
  if (isTRUE(ok)) {
    cat(sprintf("%-14s %s\n", p, format(utils::packageVersion(p))))
  } else {
    cat(sprintf("%-14s NOT LOADABLE\n", p))
    failed <- c(failed, p)
  }
}
pak::cache_clean()
if (length(failed) > 0L) stop("packages not loadable: ", paste(failed, collapse = ", "))
