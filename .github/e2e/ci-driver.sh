#!/usr/bin/env bash
# ci-driver.sh SRC OUT -- runs e2e-trainee.sh inside the workshop image as user rstudio.
# A local bare repository stands in for GitHub; a fresh clone in a new folder stands in
# for the Day-2 codespace (Day-1 environments gone, files back from "GitHub").
set -u
src="$1"; out="$2"
remote=/tmp/github/bioinfo-workshop.git
rm -rf /tmp/github "$HOME/ws1" "$HOME/ws2"; mkdir -p /tmp/github
git init -q --bare -b main "$remote"
git config --global user.name "E2E Trainee"
git config --global user.email "e2e@example.invalid"

# "Use this template -> Create a new repository": one commit with the template's files
mkdir -p "$HOME/ws1/bioinfo-workshop" && cd "$HOME/ws1/bioinfo-workshop" || exit 1
cp -a "$src/." . && rm -rf .git
git init -q -b main && git add -A && git commit -q -m "Initial commit"
git remote add origin "$remote" && git push -q -u origin main

# What a codespace does when it is created (postCreateCommand) and opened (postAttachCommand)
codespace() {
    export CODESPACES=true GITHUB_USER=e2e-trainee
    /usr/local/share/bioinfo-workshop/on-create.sh "$(pwd)" >/dev/null
    /usr/local/share/bioinfo-workshop/start-rstudio.sh
}
codespace
# The trainee's Terminal: an interactive login bash in the repository
bash -lic 'cd "$0" && . .github/e2e/e2e-trainee.sh pre day1' "$HOME/ws1/bioinfo-workshop"; r1=$?
cp -f results/e2e.log "$out/e2e-part1.log"; cp -f results/e2e.log.detail "$out/e2e-part1.detail" 2>/dev/null

# Day 2: the codespace is deleted and a new one is created from the repository
/opt/conda/bin/conda remove -y -q -n rnaseq --all >/dev/null 2>&1
cd / && rm -rf "$HOME/ws1"
mkdir -p "$HOME/ws2" && git clone -q "$remote" "$HOME/ws2/bioinfo-workshop" && cd "$HOME/ws2/bioinfo-workshop" || exit 1
codespace
bash -lic 'cd "$0" && . .github/e2e/e2e-trainee.sh day2 day3' "$HOME/ws2/bioinfo-workshop"; r2=$?
cp -f results/e2e.log "$out/e2e-part2.log"; cp -f results/e2e.log.detail "$out/e2e-part2.detail" 2>/dev/null
cat /usr/local/share/bioinfo-workshop/IMAGE_BUILT > "$out/image" 2>/dev/null
echo "part1=$r1 part2=$r2" > "$out/result"
[ "$r1" -eq 0 ] && [ "$r2" -eq 0 ]
