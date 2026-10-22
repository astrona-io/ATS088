#!/usr/bin/env bash
# PASS when the inventory-realm ConfigMap is mounted at /opt/keycloak/data/import
# and Keycloak starts with --import-realm.
set -uo pipefail

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
