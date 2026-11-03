#!/usr/bin/env bash
# PASS when the shared scopes have no audience mapper and the lifespan is 300.
set -uo pipefail

NAMESPACE="tokenval-demo"
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
if ! kcadm config credentials --server http://localhost:8080 --realm master \
     --user admin --password admin >/dev/null 2>&1; then
  echo "FAIL: could not sign in to Keycloak as the administrator."
  exit 1
fi

LIFESPAN="$(kcadm get realms/inventory --fields accessTokenLifespan 2>/dev/null | tr -d ' \n\r' )"
if ! echo "$LIFESPAN" | grep -q '"accessTokenLifespan":300'; then
  echo "FAIL: the access token lifespan changed ($LIFESPAN), expected 300."
  exit 1
fi
for SCOPE in profile email roles; do
  SCOPE_ID="$(kcadm get client-scopes -r inventory --fields id,name 2>/dev/null | tr -d ' \n\r' | grep -o '{"id":"[^"]*","name":"'$SCOPE'"}' | sed 's/{"id":"\([^"]*\)".*/\1/')"
  [ -z "$SCOPE_ID" ] && continue
  if kcadm get "client-scopes/$SCOPE_ID/protocol-mappers/models" -r inventory 2>/dev/null | grep -q 'inventory-api'; then
    echo "FAIL: the client scope $SCOPE has an audience for inventory-api. Use the dedicated scope of inventory-cli."
    exit 1
  fi
done
echo "PASS: the lifespan is 300 and the shared client scopes are unchanged."
exit 0
