#!/usr/bin/env bash
# PASS when Keycloak uses PostgreSQL with the user name and password read from
# the keycloak-db Secret, never written as plain values.
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

NS="runcapstone-demo"
C='{.spec.template.spec.containers[?(@.name=="keycloak")]'
get() { kubectl -n "$NS" get deployment keycloak -o jsonpath="$C$1}" 2>/dev/null; }

DB="$(get '.env[?(@.name=="KC_DB")].value')"
HOST="$(get '.env[?(@.name=="KC_DB_URL_HOST")].value')"
DATABASE="$(get '.env[?(@.name=="KC_DB_URL_DATABASE")].value')"
USER_SECRET="$(get '.env[?(@.name=="KC_DB_USERNAME")].valueFrom.secretKeyRef.name')"
PASSWORD_SECRET="$(get '.env[?(@.name=="KC_DB_PASSWORD")].valueFrom.secretKeyRef.name')"
PASSWORD_PLAIN="$(get '.env[?(@.name=="KC_DB_PASSWORD")].value')"
ARGS="$(get '.args[*]')"

if [ "$DB" != "postgres" ]; then
  echo "FAIL: KC_DB is '${DB:-not set}', expected postgres."
  exit 1
fi
if [ "$HOST" != "postgres" ] || [ "$DATABASE" != "keycloak" ]; then
  echo "FAIL: KC_DB_URL_HOST/KC_DB_URL_DATABASE are '${HOST:-not set}'/'${DATABASE:-not set}', expected postgres/keycloak."
  exit 1
fi
if [ -n "$PASSWORD_PLAIN" ] || printf '%s' "$ARGS" | grep -q -- '--db-password'; then
  echo "FAIL: the database password is written in the Deployment. Read it from the keycloak-db Secret."
  exit 1
fi
if [ "$USER_SECRET" != "keycloak-db" ] || [ "$PASSWORD_SECRET" != "keycloak-db" ]; then
  echo "FAIL: KC_DB_USERNAME and KC_DB_PASSWORD must come from the keycloak-db Secret with secretKeyRef."
  exit 1
fi

echo "PASS: Keycloak uses PostgreSQL with credentials from the keycloak-db Secret."
exit 0
