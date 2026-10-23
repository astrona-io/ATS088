#!/usr/bin/env bash
# PASS when the inventory-realm ConfigMap is mounted at /opt/keycloak/data/import
# and Keycloak starts with --import-realm.
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
ARGS="$(kubectl -n "$NS" get deployment keycloak -o jsonpath='{.spec.template.spec.containers[?(@.name=="keycloak")].args[*]}' 2>/dev/null)"
MOUNT_VOLUME="$(kubectl -n "$NS" get deployment keycloak \
  -o jsonpath='{.spec.template.spec.containers[?(@.name=="keycloak")].volumeMounts[?(@.mountPath=="/opt/keycloak/data/import")].name}' 2>/dev/null)"

if ! printf '%s' "$ARGS" | grep -q -- '--import-realm'; then
  echo "FAIL: Keycloak does not start with --import-realm. Args: ${ARGS:-none}"
  exit 1
fi
if [ -z "$MOUNT_VOLUME" ]; then
  echo "FAIL: nothing is mounted at /opt/keycloak/data/import."
  exit 1
fi
CONFIGMAP="$(kubectl -n "$NS" get deployment keycloak \
  -o jsonpath="{.spec.template.spec.volumes[?(@.name==\"$MOUNT_VOLUME\")].configMap.name}" 2>/dev/null)"
if [ "$CONFIGMAP" != "inventory-realm" ]; then
  echo "FAIL: the volume at /opt/keycloak/data/import is not the inventory-realm ConfigMap."
  exit 1
fi

echo "PASS: the inventory-realm ConfigMap is mounted at the import folder and --import-realm is set."
exit 0
