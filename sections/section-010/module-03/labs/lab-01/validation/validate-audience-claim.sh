#!/usr/bin/env bash
# PASS when aud lists inventory-api and iss and user are right.
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
AUD="$(echo "$CLAIMS" | kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq -r '[.aud] | flatten | join(",")' 2>/dev/null)"
if ! echo ",$AUD," | grep -q ',inventory-api,'; then
  echo "FAIL: aud is '$AUD', expected it to list inventory-api."
  exit 1
fi
ISS="$(echo "$CLAIMS" | kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq -r .iss 2>/dev/null)"
USER_NAME="$(echo "$CLAIMS" | kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq -r .preferred_username 2>/dev/null)"
if [ "$ISS" != "http://keycloak:8080/realms/inventory" ] || [ "$USER_NAME" != "alice" ]; then
  echo "FAIL: iss is '$ISS' and preferred_username is '$USER_NAME'."
  exit 1
fi
echo "PASS: the access token lists inventory-api in aud."
exit 0
