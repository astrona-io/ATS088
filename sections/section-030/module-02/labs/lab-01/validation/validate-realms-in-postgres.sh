#!/usr/bin/env bash
# PASS when the PostgreSQL database keycloak holds the master and inventory
# realms, which proves Keycloak writes its data there and not to dev-file.
set -uo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

NS="database-demo"
REALMS="$(kubectl -n "$NS" exec deploy/postgres -- \
  psql -U keycloak -d keycloak -tAc 'select name from realm order by name;' 2>/dev/null)"

for realm in master inventory; do
  if ! printf '%s\n' "$REALMS" | grep -qx "$realm"; then
    echo "FAIL: realm '$realm' is not in the PostgreSQL table realm. Found: ${REALMS:-nothing}"
    exit 1
  fi
done

echo "PASS: PostgreSQL holds the realms master and inventory."
exit 0
