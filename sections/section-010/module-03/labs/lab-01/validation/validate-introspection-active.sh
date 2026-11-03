#!/usr/bin/env bash
# PASS when introspection returns active true.
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

TOKEN_RESPONSE="$(kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli \
    -d username=alice -d password=alice-password -d scope=openid 2>/dev/null)"
ACCESS_TOKEN="$(echo "$TOKEN_RESPONSE" | kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq -r .access_token 2>/dev/null)"
if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
  echo "FAIL: could not get an access token for alice from inventory-cli."
  exit 1
fi
CLAIMS="$(echo "$ACCESS_TOKEN" | kubectl -n "$NAMESPACE" exec -i deploy/tester -- sh -c "jq -R 'split(\".\")[1] | gsub(\"-\";\"+\") | gsub(\"_\";\"/\") | @base64d | fromjson'" 2>/dev/null)"
ACTIVE="$(kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s -u inventory-api:inventory-api-secret \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token/introspect \
    -d token="$ACCESS_TOKEN" 2>/dev/null | jq -r .active 2>/dev/null)"
if [ "$ACTIVE" != "true" ]; then
  echo "FAIL: introspection returned active=$ACTIVE, expected true."
  exit 1
fi
echo "PASS: inventory-api introspects the token as active."
exit 0
