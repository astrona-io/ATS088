# Overview: Secure Keycloak Traffic With TLS And A Reverse Proxy (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak in development mode, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`edge-demo`** with these workloads:

  | Workload | What it is |
  | --- | --- |
  | `keycloak` | One Keycloak 26.8.1 pod in development mode (`start-dev`) with HTTP only, behind the Service `keycloak` on port `8080` (`http`) and `9000` (`management`). Port `8443` is not open yet |
  | `tester` | Client pod with `curl`, `jq` and `openssl`; send test requests from here to `http://keycloak:8080` |

- The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.
- No TLS certificate exists yet. The module's second part creates one with `openssl` on your machine and stores it in a Kubernetes TLS Secret.

Keycloak takes a few minutes to start the first time. When `kubectl -n edge-demo get pods` shows `keycloak` as `1/1`, it is ready.

## Helpers

Paste these once in each new terminal.

`show_issuer` prints the `issuer` of the `master` realm that Keycloak reports for a request. It takes the base URL as the first argument. Further arguments are passed to `curl`, for example `-H` options. `show_start_options` prints the `KC_` environment variables of the Keycloak Deployment.

```sh
NAMESPACE=edge-demo
show_issuer() {
  base_url="$1"; shift
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -sk "$@" "$base_url/realms/master/.well-known/openid-configuration" | jq -r .issuer
}
show_start_options() {
  kubectl -n "$NAMESPACE" get deploy keycloak \
    -o jsonpath='{range .spec.template.spec.containers[0].env[*]}{.name}={.value}{"\n"}{end}'
}
```

## Practice tasks

- Run `show_issuer http://keycloak:8080` and note the issuer.
- Try `curl -sk https://keycloak:8443` from the tester pod and read the result while no certificate is configured.
- Create a self-signed certificate with `openssl`, store it as the TLS Secret `keycloak-tls`, mount it and open port `8443`.
- Read the certificate the server presents with `openssl s_client -connect keycloak:8443 -servername keycloak` from the tester pod.
- Send `X-Forwarded-Proto: https` and `X-Forwarded-Host: id.example.test` headers with and without `KC_PROXY_HEADERS=xforwarded`, and compare the issuers.
- Set `KC_HOSTNAME=https://id.example.test` and repeat the request with different forwarded headers.
- Start the server with a wrong certificate path and read the error in `kubectl logs`.
