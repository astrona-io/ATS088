# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Server configuration

## Scenario

Keycloak in the namespace `edge-demo` runs in production mode behind a reverse proxy that is not part of this lab. The proxy ends public TLS for `https://id.example.test` and sends plain HTTP to Keycloak. The security team now also wants encrypted traffic inside the cluster. Keycloak must serve HTTPS on port `8443` with the certificate in the Secret `keycloak-tls`, and it must trust the `X-Forwarded-*` headers that the proxy sets.

## Your task

In the namespace `edge-demo`:

1. Mount the Secret `keycloak-tls` into the Keycloak container and set the options `KC_HTTPS_CERTIFICATE_FILE` and `KC_HTTPS_CERTIFICATE_KEY_FILE` to the mounted files.
2. Set `KC_PROXY_HEADERS` to `xforwarded`.
3. Open port `8443` on the container and on the Service `keycloak`, named `https`.
4. Wait until the new pod is ready, then request the discovery document of the `master` realm over HTTPS from the `tester` pod.

## Constraints

- Keep `start` as the command. Do not switch to `start-dev`.
- Keep `KC_HOSTNAME` as `https://id.example.test` and keep HTTP on, because the proxy still uses port `8080`.
- Do not change the Secret, `KC_HTTP_MANAGEMENT_SCHEME` or the health probes.
- Do not put the certificate or the key in the Deployment as text.

## Done when

- The Deployment mounts `keycloak-tls` and sets both `KC_HTTPS_*` options and `KC_PROXY_HEADERS=xforwarded`.
- The Service `keycloak` has a port `8443` named `https`.
- `https://keycloak:8443/realms/master/.well-known/openid-configuration` returns status `200` from the `tester` pod, and its `issuer` starts with `https://id.example.test`.
- The `keycloak` Deployment is available.
