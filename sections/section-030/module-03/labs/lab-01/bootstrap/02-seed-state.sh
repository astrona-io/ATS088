#!/usr/bin/env bash
# Creates the starting state for ats-088-lab-030-03.
# Creates the TLS Secret keycloak-tls. Keycloak starts in production mode over HTTP only.
# Mounting the Secret and opening port 8443 is the task.
set -euo pipefail

NAMESPACE="edge-demo"

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin

echo "[lab] Creating a self-signed certificate in the tester pod..."
kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c '
openssl req -x509 -newkey rsa:2048 -nodes -days 30 \
  -keyout /tmp/tls.key -out /tmp/tls.crt -subj "/CN=id.example.test" \
  -addext "subjectAltName=DNS:keycloak,DNS:keycloak.edge-demo.svc,DNS:id.example.test" >/dev/null 2>&1'
WORKDIR="$(mktemp -d)"
kubectl -n "$NAMESPACE" exec deploy/tester -- cat /tmp/tls.crt > "$WORKDIR/tls.crt"
kubectl -n "$NAMESPACE" exec deploy/tester -- cat /tmp/tls.key > "$WORKDIR/tls.key"
kubectl -n "$NAMESPACE" create secret tls keycloak-tls --cert="$WORKDIR/tls.crt" --key="$WORKDIR/tls.key"
rm -f "$WORKDIR/tls.crt" "$WORKDIR/tls.key"
rmdir "$WORKDIR"
echo "[lab] Starting state ready. Keycloak serves HTTP only. Serving HTTPS is the task."
