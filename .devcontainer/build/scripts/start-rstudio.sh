#!/usr/bin/env bash
# start-rstudio.sh -- the codespace's postAttachCommand; runs as rstudio each time a
# browser tab attaches. Starts RStudio Server (127.0.0.1:8788) and the small proxy in
# front of it (port 8787, the forwarded port) unless they are already up.
# Port 8787 is private to the codespace's owner, so no login screen (WORKSHOP.md §8);
# with RSTUDIO_PASSWORD set, RStudio starts with password login instead (§5 step 11d).
set -uo pipefail
# RStudio (auth-none) names the signed-in user after $USER; an empty $USER gives a
# sign-in cookie with no user name and an endless sign-in loop (smoke test, run #6).
export USER="$(id -un)"
FRONT=8787
BACK=8788
data="${HOME}/.local/share/rstudio-server"
log="${data}/start.log"
ngx=/tmp/bioinfo-workshop-nginx
mkdir -p "${data}/run" "${ngx}"

# RStudio starts its R sessions with a clean environment, so its Terminal and Git pane
# would miss the codespace's documented variables, GITHUB_TOKEN among them, and
# `git push` would ask for a username (seen 2026-10-01, R86). Hand them over in a
# file only this user can read; Rprofile.site loads it into every R session. The
# file lives in the home folder, never in the repository, and is rewritten at each
# attach so it always holds the current values.
umask 077
envfile="${data}/session.env"
: > "${envfile}.tmp"
for v in CODESPACE_NAME CODESPACES GIT_COMMITTER_EMAIL GIT_COMMITTER_NAME \
         GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN GITHUB_API_URL GITHUB_GRAPHQL_URL \
         GITHUB_REPOSITORY GITHUB_SERVER_URL GITHUB_TOKEN GITHUB_USER; do
    if [ -n "${!v:-}" ]; then printf '%s=%s\n' "${v}" "${!v}" >> "${envfile}.tmp"; fi
done
chmod 600 "${envfile}.tmp" && mv -f "${envfile}.tmp" "${envfile}"
umask 022

back_up()  { curl -sf -o /dev/null --max-time 2 "http://127.0.0.1:${BACK}/"; }
front_up() { curl -sf -o /dev/null --max-time 2 "http://127.0.0.1:${FRONT}/"; }

if back_up && front_up; then
    echo "[bioinfo-workshop] RStudio is already running on port ${FRONT}."
    exit 0
fi

if ! back_up; then
    if [ -n "${RSTUDIO_PASSWORD:-}" ]; then
        echo "[bioinfo-workshop] RSTUDIO_PASSWORD is set: starting RStudio with password login."
        sudo -n /usr/local/share/bioinfo-workshop/start-rstudio-password.sh >>"${log}" 2>&1
    else
        if [ ! -f "${data}/dbconf.conf" ]; then
            printf 'provider=sqlite\ndirectory=%s\n' "${data}" > "${data}/dbconf.conf"
        fi
        rserver \
            --server-user="$(id -un)" \
            --auth-none=1 \
            --www-address=127.0.0.1 \
            --www-port="${BACK}" \
            --server-daemonize=1 \
            --server-data-dir="${data}/run" \
            --server-pid-file="${data}/rserver.pid" \
            --secure-cookie-key-file="${data}/secure-cookie-key" \
            --database-config-file="${data}/dbconf.conf" >>"${log}" 2>&1
    fi
fi

if ! pgrep -u "$(id -u)" -x nginx >/dev/null 2>&1; then
    nginx -c /etc/bioinfo-workshop/nginx.conf -e "${ngx}/error.log" >>"${log}" 2>&1
fi

for _ in $(seq 1 30); do
    if back_up && front_up; then
        echo "[bioinfo-workshop] RStudio is running on port ${FRONT} (PORTS tab, label RStudio)."
        exit 0
    fi
    sleep 1
done
echo "[bioinfo-workshop] RStudio did not answer within 30 seconds. Last lines of ${log}:"
tail -n 20 "${log}" 2>/dev/null
tail -n 5 "${ngx}/error.log" 2>/dev/null
exit 1
