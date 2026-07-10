#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$repo_root"

echo "::group::Repository hygiene"
crlf_matches=$(git grep -I -n $'\r' -- . || true)
if [[ -n "$crlf_matches" ]]; then
  echo "CRLF line endings found:"
  echo "$crlf_matches"
  exit 1
fi

large_files=$(git ls-files -z | xargs -0 -r du -b | awk '$1 > 10485760 { print $2 " " $1 " bytes" }')
if [[ -n "$large_files" ]]; then
  echo "Tracked files over 10 MiB found:"
  echo "$large_files"
  exit 1
fi
echo "Repository hygiene checks passed."
echo "::endgroup::"

echo "::group::JavaScript syntax"
mapfile -d '' js_files < <(git ls-files -z '*.js')
if (( ${#js_files[@]} == 0 )); then
  echo "No JavaScript files tracked."
else
  for file in "${js_files[@]}"; do
    echo "node --check $file"
    node --check "$file"
  done
fi
echo "::endgroup::"

echo "::group::Futex PoC C syntax"
clang -Wall -Wextra -fsyntax-only IonStack/CVE-2026-43499/poc/poc.c
echo "Futex PoC syntax check passed."
echo "::endgroup::"

echo "::group::Exploit artifact guard"
if find . -type f \( -name '*.o' -o -name '*.so' -o -name '*.ko' -o -name 'ghostlock-poc' -o -name 'preload.so' \) -print -quit | grep -q .; then
  echo "Generated binary artifacts are present in the working tree."
  find . -type f \( -name '*.o' -o -name '*.so' -o -name '*.ko' -o -name 'ghostlock-poc' -o -name 'preload.so' \) -print
  exit 1
fi
echo "No generated exploit artifacts found."
echo "::endgroup::"