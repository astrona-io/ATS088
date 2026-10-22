#!/usr/bin/env bash
# PASS when alice gets a token from the inventory realm through inventory-cli,
# and the token's issuer and user name are right.
set -uo pipefail

NS="realms-demo"
EXPECTED_ISS="http://keycloak:8080/realms/inventory"

RESULT="$(kubectl -n "$NS" exec -i deploy/tester -- sh -s 2>/dev/null <<'SCRIPT'
response=$(curl -s -d grant_type=password -d client_id=inventory-cli \
  -d username=alice -d password=alice-password \
  http://keycloak:8080/realms/inventory/protocol/openid-connect/token)
token=$(printf '%s' "$response" | jq -r '.access_token // empty' 2>/dev/null)
if [ -z "$token" ]; then
  echo "NOTOKEN $response"
  exit 0
fi
printf '%s' "$token" | jq -R -r 'split(".")[1] | gsub("-";"+") | gsub("_";"/")
  | . + ("=" * ((4 - length % 4) % 4)) | @base64d | fromjson
  | "\(.iss) \(.preferred_username)"'
SCRIPT
)"

if [ -z "$RESULT" ]; then
  echo "FAIL: could not run the token request in the tester pod."
  exit 1
fi
case "$RESULT" in
  NOTOKEN*)
    echo "FAIL: the inventory realm returned no token for alice through inventory-cli. Response: ${RESULT#NOTOKEN }"
    exit 1
    ;;
esac

ISS="${RESULT%% *}"
USERNAME="${RESULT#* }"
if [ "$ISS" != "$EXPECTED_ISS" ]; then
  echo "FAIL: the token's issuer is $ISS, expected $EXPECTED_ISS."
  exit 1
fi
if [ "$USERNAME" != "alice" ]; then
  echo "FAIL: the token's preferred_username is $USERNAME, expected alice."
  exit 1
fi

echo "PASS: alice got a token from $EXPECTED_ISS."
exit 0
