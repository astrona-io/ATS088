#!/usr/bin/env bash
# PASS when inventory-web requires PKCE S256 and the standard flow is on.
set -uo pipefail

NAMESPACE="authcode-demo"
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
if ! kcadm config credentials --server http://localhost:8080 --realm master \
     --user admin --password admin >/dev/null 2>&1; then
  echo "FAIL: could not sign in to Keycloak as the administrator."
  exit 1
fi

OUT="$(kcadm get clients -r inventory -q clientId=inventory-web 2>/dev/null)"
if [ -z "$OUT" ] || ! echo "$OUT" | grep -q '"clientId"'; then
  echo "FAIL: the client inventory-web does not exist in the realm inventory."
  exit 1
fi
if ! echo "$OUT" | grep -Eq '"pkce.code.challenge.method"[[:space:]]*:[[:space:]]*"S256"'; then
  echo "FAIL: the attribute pkce.code.challenge.method is not S256."
  exit 1
fi
if ! echo "$OUT" | grep -Eq '"standardFlowEnabled"[[:space:]]*:[[:space:]]*true'; then
  echo "FAIL: the standard flow of inventory-web is off. It must stay on."
  exit 1
fi
echo "PASS: inventory-web requires PKCE with S256 and keeps the standard flow."
exit 0
