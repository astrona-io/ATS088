#!/usr/bin/env bash
# PASS when alice gets a token from the inventory realm with the password grant
# and its claims name alice and the issuer http://keycloak:8080/realms/inventory.
set -uo pipefail

NS="runcapstone-demo"
EXPECTED_ISSUER="http://keycloak:8080/realms/inventory"

TOKEN_JSON="$(kubectl -n "$NS" exec deploy/tester -- curl -s --max-time 15 \
  -d grant_type=password -d client_id=inventory-cli \
  -d username=alice -d password=alice-password -d scope=openid \
  http://keycloak:8080/realms/inventory/protocol/openid-connect/token 2>/dev/null)"

if ! printf '%s' "$TOKEN_JSON" | grep -q '"access_token"'; then
  echo "FAIL: no access token for alice. Response: ${TOKEN_JSON:-no response}"
  exit 1
fi

# Decode the payload of the access token inside the tester pod, which has jq.
CLAIMS="$(printf '%s' "$TOKEN_JSON" | kubectl -n "$NS" exec -i deploy/tester -- \
  jq -r '.access_token | split(".")[1] | gsub("-";"+") | gsub("_";"/")
         | . + ("=" * ((4 - (length % 4)) % 4)) | @base64d | fromjson
         | "\(.iss) \(.preferred_username)"' 2>/dev/null)"

if [ "$CLAIMS" != "$EXPECTED_ISSUER alice" ]; then
  echo "FAIL: the token claims are '${CLAIMS:-unreadable}', expected '$EXPECTED_ISSUER alice'."
  exit 1
fi

echo "PASS: alice gets a token from the inventory realm with issuer $EXPECTED_ISSUER."
exit 0
