#!/usr/bin/env bash
# PASS when HTTPS on 8443 returns 200 and the right issuer.
set -uo pipefail

NAMESPACE="edge-demo"
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
if ! kcadm config credentials --server http://localhost:8080 --realm master \
     --user admin --password admin >/dev/null 2>&1; then
  echo "FAIL: could not sign in to Keycloak as the administrator."
  exit 1
fi

URL="https://keycloak:8443/realms/master/.well-known/openid-configuration"
STATUS="$(kubectl -n "$NAMESPACE" exec deploy/tester -- curl -sk -o /dev/null -w '%{http_code}' "$URL" 2>/dev/null)"
if [ "$STATUS" != "200" ]; then
  echo "FAIL: $URL returned status $STATUS, expected 200."
  exit 1
fi
ISSUER="$(kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c "curl -sk '$URL' | jq -r .issuer" 2>/dev/null)"
case "$ISSUER" in
  https://id.example.test*) ;;
  *) echo "FAIL: the issuer is '$ISSUER', expected it to start with https://id.example.test."; exit 1 ;;
esac
echo "PASS: HTTPS on port 8443 returns the discovery document with issuer $ISSUER."
exit 0
