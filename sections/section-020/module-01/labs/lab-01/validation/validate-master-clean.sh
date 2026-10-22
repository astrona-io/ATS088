#!/usr/bin/env bash
# PASS when the master realm holds no client inventory-cli and no user alice.
# Creating the application in master is the wrong fix this lab rejects.
set -uo pipefail

NS="realms-demo"
kcadm() {
  kubectl -n "$NS" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/grader-kcadm.config
}

if ! kcadm config credentials --server http://localhost:8080 --realm master \
     --user admin --password admin >/dev/null 2>&1; then
  echo "FAIL: the grader could not sign in to master as admin."
  exit 1
fi

CLIENT="$(kcadm get clients -r master -q clientId=inventory-cli --fields clientId --format csv --noquotes 2>/dev/null | tr -d '[:space:]')"
if [ -n "$CLIENT" ]; then
  echo "FAIL: the master realm holds a client inventory-cli. The application belongs in the inventory realm only."
  exit 1
fi

FOUND_USER="$(kcadm get users -r master -q username=alice -q exact=true --fields username --format csv --noquotes 2>/dev/null | tr -d '[:space:]')"
if [ -n "$FOUND_USER" ]; then
  echo "FAIL: the master realm holds a user alice. Application users belong in the inventory realm only."
  exit 1
fi

echo "PASS: the master realm holds no application client or user."
exit 0
