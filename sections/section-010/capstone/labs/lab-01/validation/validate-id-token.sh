#!/usr/bin/env bash
# PASS when alice gets an ID token through inventory-cli with the password
# grant and scope=openid, and the token names alice and the realm inventory.
set -uo pipefail

NAMESPACE="protocolscapstone-demo"
EXPECTED_ISSUER="http://keycloak:8080/realms/inventory"

# Request the tokens and read the ID token's claims inside the tester pod,
# which has curl and jq. Prints "<preferred_username> <iss>" or the error.
RESULT="$(kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c '
  RESPONSE=$(curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password \
    -d client_id=inventory-cli \
    -d username=alice \
    -d password=alice-password \
    -d scope=openid)
  ID_TOKEN=$(printf "%s" "$RESPONSE" | jq -r ".id_token // empty")
  if [ -z "$ID_TOKEN" ]; then
    printf "NO_TOKEN %s" "$(printf "%s" "$RESPONSE" | jq -c "{error, error_description}" 2>/dev/null)"
    exit 0
  fi
  printf "%s" "$ID_TOKEN" \
    | jq -rR "split(\".\")[1] | gsub(\"-\";\"+\") | gsub(\"_\";\"/\") | @base64d | fromjson | \"\(.preferred_username) \(.iss)\""
' 2>/dev/null)"

case "$RESULT" in
  "")
    echo "FAIL: could not run curl in the tester pod."
    exit 1 ;;
  NO_TOKEN*)
    echo "FAIL: the token endpoint returned no ID token for alice: ${RESULT#NO_TOKEN }"
    exit 1 ;;
esac

USERNAME="${RESULT%% *}"
ISSUER="${RESULT#* }"
if [ "$USERNAME" != "alice" ]; then
  echo "FAIL: the ID token's preferred_username is '$USERNAME', expected 'alice'."
  exit 1
fi
if [ "$ISSUER" != "$EXPECTED_ISSUER" ]; then
  echo "FAIL: the ID token's iss is '$ISSUER', expected '$EXPECTED_ISSUER'."
  exit 1
fi

echo "PASS: alice gets an ID token from the realm inventory through inventory-cli."
exit 0
