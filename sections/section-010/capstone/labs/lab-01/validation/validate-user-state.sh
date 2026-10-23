#!/usr/bin/env bash
# PASS when alice is enabled and has no required actions left.
set -uo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

NAMESPACE="protocolscapstone-demo"
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
if ! kcadm config credentials --server http://localhost:8080 --realm master \
     --user admin --password admin >/dev/null 2>&1; then
  echo "FAIL: could not sign in to Keycloak as the administrator."
  exit 1
fi

ALICE_ID="$(kcadm get users -r inventory -q username=alice -q exact=true --fields id --format csv --noquotes 2>/dev/null | tr -d '\r')"
if [ -z "$ALICE_ID" ]; then
  echo "FAIL: the user alice does not exist in the realm inventory."
  exit 1
fi

# Remove all whitespace so the JSON can be matched as one string.
STATE="$(kcadm get "users/$ALICE_ID" -r inventory --fields enabled,requiredActions 2>/dev/null | tr -d ' \n\r\t')"

if ! printf '%s' "$STATE" | grep -q '"enabled":true'; then
  echo "FAIL: the user alice is disabled."
  exit 1
fi
if printf '%s' "$STATE" | grep -q '"requiredActions":\[[^]]'; then
  echo "FAIL: alice still has required actions: $STATE"
  exit 1
fi

echo "PASS: alice is enabled and has no required actions."
exit 0
