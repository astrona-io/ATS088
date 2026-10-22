#!/usr/bin/env bash
# PASS when the realm inventory is enabled and still holds the realm role
# inventory-viewer, which proves it was enabled and not deleted and recreated.
set -uo pipefail

NS="realmscapstone-demo"
kcadm() {
  kubectl -n "$NS" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/grader-kcadm.config
}

if ! kcadm config credentials --server http://localhost:8080 --realm master \
     --user admin --password admin >/dev/null 2>&1; then
  echo "FAIL: the grader could not sign in to master as admin. Do not change the bootstrap administrator."
  exit 1
fi

ENABLED="$(kcadm get realms/inventory --fields enabled --format csv --noquotes 2>/dev/null | tr -d '[:space:]')"
if [ -z "$ENABLED" ]; then
  echo "FAIL: the realm inventory does not exist."
  exit 1
fi
if [ "$ENABLED" != "true" ]; then
  echo "FAIL: the realm inventory is still disabled."
  exit 1
fi

ROLE="$(kcadm get roles/inventory-viewer -r inventory --fields name --format csv --noquotes 2>/dev/null | tr -d '[:space:]')"
if [ "$ROLE" != "inventory-viewer" ]; then
  echo "FAIL: the realm role inventory-viewer is missing. Enable the existing realm; do not delete and recreate it."
  exit 1
fi

echo "PASS: the realm inventory is enabled and kept its realm role inventory-viewer."
exit 0
