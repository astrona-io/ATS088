#!/usr/bin/env bash
# PASS when alice and inventory-cli are the same objects the lab started with
# (same IDs as in the ConfigMap capstone-baseline), and inventory-cli is still
# a public client. Deleting and recreating them, or turning the client
# confidential, is the wrong fix.
set -uo pipefail

NAMESPACE="protocolscapstone-demo"
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
if ! kcadm config credentials --server http://localhost:8080 --realm master \
     --user admin --password admin >/dev/null 2>&1; then
  echo "FAIL: could not sign in to Keycloak as the administrator."
  exit 1
fi

baseline() {
  kubectl -n "$NAMESPACE" get configmap capstone-baseline -o jsonpath="{.data.$1}" 2>/dev/null
}
BASE_ALICE_ID="$(baseline alice-id)"
BASE_CLI_ID="$(baseline inventory-cli-id)"
if [ -z "$BASE_ALICE_ID" ] || [ -z "$BASE_CLI_ID" ]; then
  echo "FAIL: the ConfigMap capstone-baseline is missing or incomplete. Do not change it."
  exit 1
fi

ALICE_ID="$(kcadm get users -r inventory -q username=alice -q exact=true --fields id --format csv --noquotes 2>/dev/null | tr -d '\r')"
CLI_ID="$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes 2>/dev/null | tr -d '\r')"
CLI_PUBLIC="$(kcadm get clients -r inventory -q clientId=inventory-cli --fields publicClient --format csv --noquotes 2>/dev/null | tr -d '\r')"

if [ "$ALICE_ID" != "$BASE_ALICE_ID" ]; then
  echo "FAIL: the user alice is not the original user (ID '$ALICE_ID', expected '$BASE_ALICE_ID'). Fix the user; do not recreate it."
  exit 1
fi
if [ "$CLI_ID" != "$BASE_CLI_ID" ]; then
  echo "FAIL: the client inventory-cli is not the original client (ID '$CLI_ID', expected '$BASE_CLI_ID'). Fix the client; do not recreate it."
  exit 1
fi
if [ "$CLI_PUBLIC" != "true" ]; then
  echo "FAIL: inventory-cli is no longer a public client (publicClient=$CLI_PUBLIC)."
  exit 1
fi

echo "PASS: alice and inventory-cli are the original objects, and inventory-cli is still public."
exit 0
