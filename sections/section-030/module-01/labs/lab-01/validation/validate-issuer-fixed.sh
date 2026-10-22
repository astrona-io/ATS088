#!/usr/bin/env bash
# PASS when the master realm's issuer is http://keycloak:8080/realms/master, also
# for a request that claims another Host. That only holds when Keycloak uses a
# fixed hostname with hostname-strict on.
set -uo pipefail

NS="image-demo"
EXPECTED="http://keycloak:8080/realms/master"
URL="http://keycloak:8080/realms/master/.well-known/openid-configuration"

PLAIN="$(kubectl -n "$NS" exec deploy/tester -- sh -c "curl -s --max-time 10 $URL | jq -r .issuer" 2>/dev/null)"
OTHER="$(kubectl -n "$NS" exec deploy/tester -- sh -c "curl -s --max-time 10 -H 'Host: localhost:8080' $URL | jq -r .issuer" 2>/dev/null)"

if [ "$PLAIN" != "$EXPECTED" ]; then
  echo "FAIL: the issuer is '${PLAIN:-no response}', expected $EXPECTED."
  exit 1
fi
if [ "$OTHER" != "$EXPECTED" ]; then
  echo "FAIL: with 'Host: localhost:8080' the issuer becomes '${OTHER:-no response}'. The hostname is not fixed."
  exit 1
fi

echo "PASS: the issuer is $EXPECTED, whatever Host the request uses."
exit 0
