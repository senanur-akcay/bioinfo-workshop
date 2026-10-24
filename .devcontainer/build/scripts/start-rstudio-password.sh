#!/usr/bin/env bash
# start-rstudio-password.sh -- organiser's last-resort fallback only (WORKSHOP.md §5
# step 11d), run as root through sudo by start-rstudio.sh. Never used by trainees.
# rocker's pam-helper accepts user rstudio with the password in $PASSWORD.
# RStudio listens on 127.0.0.1:8788; the proxy started by start-rstudio.sh serves 8787.
set -euo pipefail
if [ -z "${RSTUDIO_PASSWORD:-}" ]; then
    echo "RSTUDIO_PASSWORD is empty; not starting password mode." >&2
    exit 1
fi
export USER=rstudio
export PASSWORD="${RSTUDIO_PASSWORD}"
exec /usr/lib/rstudio-server/bin/rserver --server-user=rstudio --auth-none=0 \
    --www-address=127.0.0.1 --www-port=8788 --server-daemonize=1
