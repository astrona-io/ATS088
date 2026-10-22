#!/usr/bin/env bash
# PASS when inventory-reporter is a confidential client with service accounts on.
set -uo pipefail

NAMESPACE="protocols-demo"
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
if ! kcadm config credentials --server http://localhost:8080 --realm master \
     --user admin --password admin >/dev/null 2>&1; then
  echo "FAIL: could not sign in to Keycloak as the administrator."
  exit 1
fi

client_field() {
  kcadm get clients -r inventory -q clientId=inventory-reporter \
    --fields "$1" --format csv --noquotes 2>/dev/null | tr -d '\r'
}

PUBLIC="$(client_field publicClient)"
SERVICE_ACCOUNTS="$(client_field serviceAccountsEnabled)"

if [ -z "$PUBLIC" ]; then
  echo "FAIL: the client inventory-reporter does not exist in the realm inventory."
  exit 1
fi
if [ "$PUBLIC" != "false" ]; then
  echo "FAIL: inventory-reporter is still a public client (publicClient=$PUBLIC)."
  exit 1
fi
if [ "$SERVICE_ACCOUNTS" != "true" ]; then
  echo "FAIL: inventory-reporter has no service account (serviceAccountsEnabled=$SERVICE_ACCOUNTS)."
  exit 1
fi

echo "PASS: inventory-reporter is a confidential client with service accounts on."
exit 0
