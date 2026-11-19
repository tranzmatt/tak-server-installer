#!/usr/bin/env bash
# The install folders (ubuntu-22.04, ubuntu-24.04, debian-trixie) are copies of one another with a few
# per-distro changes. The security-relevant blocks must not drift apart: the PostgreSQL and Caddy key
# downloads (ops #728, #730) and lock_key_files (ops #832, #838). This also checks that every copy
# has the platform check and carries no stale "22.04" outside the 22.04 folder. No root, no network:
#   bash .github/ci/test_distro_copies.sh
set -uo pipefail

cd "$(git rev-parse --show-toplevel)" || exit 2
fails=0
ok()   { echo "ok   $1"; }
fail() { echo "FAIL $1"; shift; [ "$#" -gt 0 ] && printf '     %s\n' "$@"; fails=$((fails + 1)); }

BASE_INSTALL=ubuntu-22.04/Ubuntu_22.04_TAK_Server_install.sh
BASE_CADDY=ubuntu-22.04/Ubuntu_22.04_Caddy_setup.sh
BASE_HARDEN=ubuntu-22.04/Ubuntu_22.04_TAK_Server_Hardening.sh
NEW=(ubuntu-24.04/Ubuntu_24.04 debian-trixie/Debian_13)

between() { sed -n "/$2/,/$3/p" "$1"; }

for p in "${NEW[@]}"; do
  inst="${p}_TAK_Server_install.sh"; cad="${p}_Caddy_setup.sh"; har="${p}_TAK_Server_Hardening.sh"
  for f in "$inst" "$cad" "$har"; do
    [ -f "$f" ] || { fail "$f is missing"; continue; }
    grep -q '^# Platform check' "$f" && ok "$f: has the platform check" || fail "$f: no platform check"
    grep -q '22\.04' "$f" && fail "$f: still mentions 22.04" || ok "$f: no stale 22.04"
    [ "$(git ls-files -s -- "$f" | awk '{print $1}')" = "100755" ] || [ ! -d .git ] \
      || fail "$f: not stored as 100755 (git add it after chmod +x)"
  done
  [ "$(between "$BASE_INSTALL" '^# >>> pgdg-key' '^# <<< pgdg-key')" = "$(between "$inst" '^# >>> pgdg-key' '^# <<< pgdg-key')" ] \
    && ok "$inst: PGDG key block matches ubuntu-22.04" || fail "$inst: PGDG key block differs from ubuntu-22.04"
  [ "$(between "$BASE_CADDY" '^# >>> caddy-repo' '^# <<< caddy-repo')" = "$(between "$cad" '^# >>> caddy-repo' '^# <<< caddy-repo')" ] \
    && ok "$cad: Caddy repo block matches ubuntu-22.04" || fail "$cad: Caddy repo block differs from ubuntu-22.04"
  for f in "$inst" "$har"; do
    [ "$(between "$BASE_INSTALL" '^# BEGIN lock_key_files$' '^# END lock_key_files$')" = "$(between "$f" '^# BEGIN lock_key_files$' '^# END lock_key_files$')" ] \
      && ok "$f: lock_key_files matches ubuntu-22.04" || fail "$f: lock_key_files differs from ubuntu-22.04"
  done
done

if [ "$fails" -gt 0 ]; then echo "$fails check(s) failed"; exit 1; fi
echo "all checks passed"
