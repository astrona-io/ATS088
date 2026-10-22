#!/usr/bin/env bash
# PASS when Keycloak runs in production mode: the entrypoint is kept, the first
# argument is `start`, `start-dev` appears nowhere, and hostname-strict is not
# turned off.
set -uo pipefail

NS="image-demo"
C='{.spec.template.spec.containers[?(@.name=="keycloak")]'
COMMAND="$(kubectl -n "$NS" get deployment keycloak -o jsonpath="$C.command[*]}" 2>/dev/null)"
ARGS="$(kubectl -n "$NS" get deployment keycloak -o jsonpath="$C.args[*]}" 2>/dev/null)"
FIRST="${ARGS%% *}"
STRICT="$(kubectl -n "$NS" get deployment keycloak -o jsonpath="$C.env[?(@.name==\"KC_HOSTNAME_STRICT\")].value}" 2>/dev/null)"

if [ -n "$COMMAND" ]; then
  echo "FAIL: the container sets command ($COMMAND). Keep the image entrypoint and use args."
  exit 1
fi
if [ "$FIRST" != "start" ]; then
  echo "FAIL: the first argument is '${FIRST:-none}', not 'start'. Args: $ARGS"
  exit 1
fi
if printf '%s' "$ARGS" | grep -q 'start-dev'; then
  echo "FAIL: the arguments still contain start-dev: $ARGS"
  exit 1
fi
if [ "$STRICT" = "false" ] || printf '%s' "$ARGS" | grep -q 'hostname-strict=false'; then
  echo "FAIL: hostname-strict is turned off. Set a hostname instead."
  exit 1
fi

echo "PASS: Keycloak runs with 'start' in production mode and hostname-strict stays on."
exit 0
