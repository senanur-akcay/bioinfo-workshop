#!/usr/bin/env bash
# on-create.sh WORKSPACE -- the codespace's postCreateCommand; runs once, as rstudio.
# Codespaces mounts the repository at /workspaces/<repo>, while RStudio would start
# in /home/rstudio (WORKSHOP.md §8). This records the real folder so that RStudio
# starts there and the R site profile can open the project.
set -euo pipefail
ws="${1:-${CODESPACE_VSCODE_FOLDER:-$PWD}}"
echo "[bioinfo-workshop] workspace folder: ${ws}"
mkdir -p "${HOME}/.config/bioinfo-workshop" "${HOME}/.config/rstudio"
printf '%s\n' "${ws}" > "${HOME}/.config/bioinfo-workshop/workspace"
mkdir -p "${ws}/results"
prefs="${HOME}/.config/rstudio/rstudio-prefs.json"
if [ ! -s "${prefs}" ] || ! jq -e . "${prefs}" >/dev/null 2>&1; then
    echo '{}' > "${prefs}"
fi
tmp="$(mktemp)"
jq --arg ws "${ws}" '.initial_working_directory = $ws' "${prefs}" > "${tmp}"
mv "${tmp}" "${prefs}"
echo "[bioinfo-workshop] RStudio will start in ${ws}"
echo "[bioinfo-workshop] image built: $(cat /usr/local/share/bioinfo-workshop/IMAGE_BUILT 2>/dev/null || echo unknown)"
