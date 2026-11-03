#!/usr/bin/env bash
# PASS when the server options and the Secret volume are set.
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

ENV_LINES="$(kubectl -n "$NAMESPACE" get deploy keycloak -o jsonpath='{range .spec.template.spec.containers[0].env[*]}{.name}={.value}{"\n"}{end}' 2>/dev/null)"
for WANTED in "KC_PROXY_HEADERS=xforwarded" "KC_HOSTNAME=https://id.example.test" "KC_HTTP_ENABLED=true"; do
  if ! echo "$ENV_LINES" | grep -qxF "$WANTED"; then
    echo "FAIL: the Deployment does not set $WANTED."
    exit 1
  fi
done
CERT_FILE="$(echo "$ENV_LINES" | grep '^KC_HTTPS_CERTIFICATE_FILE=' | cut -d= -f2-)"
KEY_FILE="$(echo "$ENV_LINES" | grep '^KC_HTTPS_CERTIFICATE_KEY_FILE=' | cut -d= -f2-)"
if [ -z "$CERT_FILE" ] || [ -z "$KEY_FILE" ]; then
  echo "FAIL: KC_HTTPS_CERTIFICATE_FILE and KC_HTTPS_CERTIFICATE_KEY_FILE must both be set."
  exit 1
fi
if echo "$ENV_LINES" | grep -q 'BEGIN'; then
  echo "FAIL: a certificate or key is written into the Deployment. Mount the Secret instead."
  exit 1
fi
SECRET_NAME="$(kubectl -n "$NAMESPACE" get deploy keycloak -o jsonpath='{.spec.template.spec.volumes[*].secret.secretName}' 2>/dev/null)"
if ! echo "$SECRET_NAME" | grep -qw 'keycloak-tls'; then
  echo "FAIL: the Deployment does not mount the Secret keycloak-tls."
  exit 1
fi
MOUNT_PATHS="$(kubectl -n "$NAMESPACE" get deploy keycloak -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[*].mountPath}' 2>/dev/null)"
CERT_DIR="$(dirname "$CERT_FILE")"
if ! echo "$MOUNT_PATHS" | tr ' ' '\n' | grep -qxF "$CERT_DIR"; then
  echo "FAIL: no volume is mounted at $CERT_DIR, the directory of the certificate file."
  exit 1
fi
ARGS="$(kubectl -n "$NAMESPACE" get deploy keycloak -o jsonpath='{.spec.template.spec.containers[0].args[*]}' 2>/dev/null)"
if [ "$ARGS" != "start" ]; then
  echo "FAIL: the container arguments are '$ARGS', expected 'start'."
  exit 1
fi
echo "PASS: the Deployment mounts keycloak-tls and sets the HTTPS and proxy options."
exit 0
