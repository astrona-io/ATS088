#!/usr/bin/env bash
# PASS when direct access grants are off and the client is still public.
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
if ! echo "$OUT" | grep -Eq '"directAccessGrantsEnabled"[[:space:]]*:[[:space:]]*false'; then
  echo "FAIL: direct access grants are still on for inventory-web."
  exit 1
fi
if ! echo "$OUT" | grep -Eq '"publicClient"[[:space:]]*:[[:space:]]*true'; then
  echo "FAIL: inventory-web is no longer a public client."
  exit 1
fi
echo "PASS: the password grant is off and inventory-web is still public."
exit 0
