#!/usr/bin/env bash
# PASS when the hostname and HTTP are set with environment variables:
# KC_HOSTNAME=http://keycloak:8080 and KC_HTTP_ENABLED=true.
set -uo pipefail

NS="image-demo"
C='{.spec.template.spec.containers[?(@.name=="keycloak")]'
HOSTNAME_VALUE="$(kubectl -n "$NS" get deployment keycloak -o jsonpath="$C.env[?(@.name==\"KC_HOSTNAME\")].value}" 2>/dev/null)"
HTTP_VALUE="$(kubectl -n "$NS" get deployment keycloak -o jsonpath="$C.env[?(@.name==\"KC_HTTP_ENABLED\")].value}" 2>/dev/null)"

if [ "$HOSTNAME_VALUE" != "http://keycloak:8080" ]; then
  echo "FAIL: KC_HOSTNAME is '${HOSTNAME_VALUE:-not set}', expected http://keycloak:8080."
  exit 1
fi
if [ "$HTTP_VALUE" != "true" ]; then
  echo "FAIL: KC_HTTP_ENABLED is '${HTTP_VALUE:-not set}', expected true."
  exit 1
fi

echo "PASS: KC_HOSTNAME and KC_HTTP_ENABLED are set as environment variables."
exit 0
