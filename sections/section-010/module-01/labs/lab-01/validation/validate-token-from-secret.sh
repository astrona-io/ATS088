#!/usr/bin/env bash
# PASS when the client secret stored in the Kubernetes Secret
# inventory-reporter-credentials gets an access token with the client
# credentials grant, and the token's azp claim is inventory-reporter.
set -uo pipefail

NAMESPACE="protocols-demo"

ENCODED="$(kubectl -n "$NAMESPACE" get secret inventory-reporter-credentials \
  -o jsonpath='{.data.client-secret}' 2>/dev/null)"
if [ -z "$ENCODED" ]; then
  echo "FAIL: the Secret inventory-reporter-credentials with the key client-secret does not exist in $NAMESPACE."
  exit 1
fi
CLIENT_SECRET="$(printf '%s' "$ENCODED" | base64 --decode)"

# Request the token and read its azp claim inside the tester pod, which has curl and jq.
AZP="$(kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c '
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=client_credentials \
    -d client_id=inventory-reporter \
    --data-urlencode client_secret="$1" \
  | jq -r ".access_token // empty" \
  | jq -rR "split(\".\")[1] | gsub(\"-\";\"+\") | gsub(\"_\";\"/\") | @base64d | fromjson | .azp"
' sh "$CLIENT_SECRET" 2>/dev/null)"

if [ -z "$AZP" ]; then
  echo "FAIL: the client credentials grant with the secret from inventory-reporter-credentials returned no access token."
  exit 1
fi
if [ "$AZP" != "inventory-reporter" ]; then
  echo "FAIL: the token's azp claim is '$AZP', expected 'inventory-reporter'."
  exit 1
fi

echo "PASS: the stored client secret gets an access token for inventory-reporter."
exit 0
