# Overview: Run Keycloak From The Container Image In Production Mode (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak and a client pod, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`image-demo`** with these workloads:

  | Workload | What it is |
  | --- | --- |
  | `keycloak` | One pod of **Keycloak 26.8.1** (image `quay.io/keycloak/keycloak:26.8.1`), started with `start-dev`. The Service `keycloak` has port `8080` for HTTP and port `9000` for the management interface, which serves the health endpoints |
  | `tester` | Client pod with `curl` and `jq`; send test requests from here |

- The Keycloak Deployment uses the `Recreate` strategy: Kubernetes stops the old pod before it starts a new one, so only one Keycloak pod runs at a time.
- The first administrator of the `master` realm is the user `admin` with the password `admin`, taken from the Secret `keycloak-admin`. These are lab-only credentials.

## Helpers

Paste these once in each new terminal. `show_args` prints the arguments the Keycloak container runs with. `show_issuer` asks the `master` realm's discovery document for its issuer from the `tester` pod. `check_ready` asks the ready endpoint on the management port.

```sh
show_args() {
  kubectl -n image-demo get deployment keycloak \
    -o jsonpath='{.spec.template.spec.containers[0].args}{"\n"}'
}
show_issuer() {
  kubectl -n image-demo exec deploy/tester -- \
    curl -s http://keycloak:8080/realms/master/.well-known/openid-configuration | jq -r .issuer
}
check_ready() {
  kubectl -n image-demo exec deploy/tester -- curl -s http://keycloak:9000/health/ready
}
```

Use them like this: `show_args`, `show_issuer`, `check_ready`.

## Practice tasks

- List `/opt/keycloak/bin`, `/opt/keycloak/conf` and `/opt/keycloak/providers` with `kubectl -n image-demo exec deploy/keycloak -- ls`, and say what each folder is for before you look it up.
- Run `show_issuer`, then the same request with `-H 'Host: localhost:8080'`. Explain why the issuer changes in development mode.
- Change `args` to `start` only, read `kubectl -n image-demo logs deploy/keycloak`, and name the settings production mode asks for.
- Start in production mode once with `--hostname` and `--http-enabled` as command-line options, and once with `KC_HOSTNAME` and `KC_HTTP_ENABLED` as environment variables. Set both at once with different hostnames and predict which one wins.
- Remove `KC_HEALTH_ENABLED` from the Deployment and watch what the probes do with `kubectl -n image-demo describe pod -l app=keycloak`. Put it back afterwards.
