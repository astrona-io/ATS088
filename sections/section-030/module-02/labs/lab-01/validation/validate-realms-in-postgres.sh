#!/usr/bin/env bash
# PASS when the PostgreSQL database keycloak holds the master and inventory
# realms, which proves Keycloak writes its data there and not to dev-file.
set -uo pipefail

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
