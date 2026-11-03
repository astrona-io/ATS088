#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

NAMESPACE="edge-demo"

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin

kubectl -n "$NAMESPACE" patch deployment keycloak --type=json -p '[
 {"op":"add","path":"/spec/template/spec/volumes","value":[{"name":"tls","secret":{"secretName":"keycloak-tls"}}]},
 {"op":"add","path":"/spec/template/spec/containers/0/volumeMounts","value":[{"name":"tls","mountPath":"/opt/keycloak/conf/tls","readOnly":true}]},
 {"op":"add","path":"/spec/template/spec/containers/0/ports/-","value":{"name":"https","containerPort":8443}},
 {"op":"add","path":"/spec/template/spec/containers/0/env/-","value":{"name":"KC_PROXY_HEADERS","value":"xforwarded"}},
 {"op":"add","path":"/spec/template/spec/containers/0/env/-","value":{"name":"KC_HTTPS_CERTIFICATE_FILE","value":"/opt/keycloak/conf/tls/tls.crt"}},
 {"op":"add","path":"/spec/template/spec/containers/0/env/-","value":{"name":"KC_HTTPS_CERTIFICATE_KEY_FILE","value":"/opt/keycloak/conf/tls/tls.key"}}
]'
kubectl -n "$NAMESPACE" patch service keycloak --type=json -p '[
 {"op":"add","path":"/spec/ports/-","value":{"name":"https","port":8443,"targetPort":"https"}}
]'
kubectl -n "$NAMESPACE" rollout status deployment/keycloak --timeout=600s
