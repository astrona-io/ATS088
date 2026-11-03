# Overview: Observe And Operate Keycloak (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`ops-demo`** with these workloads:

  | Workload | What it is |
  | --- | --- |
  | `keycloak` | One Keycloak 26.8.1 pod in development mode with health checks on, behind the Service `keycloak` on port `8080` (`http`) and `9000` (`management`). Metrics are off and logs use the default text format |
  | `tester` | Client pod with `curl` and `jq`; send test requests from here, for example to `http://keycloak:9000/health/ready` |

- The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

Keycloak takes a few minutes to start the first time. When `kubectl -n ops-demo get pods` shows `keycloak` as `1/1`, it is ready.

## Helpers

Paste these once in each new terminal. `show_options` prints the `KC_` environment variables of the Keycloak Deployment. `management_status` prints the HTTP status of a path on the management port.

```sh
NAMESPACE=ops-demo
show_options() {
  kubectl -n "$NAMESPACE" get deploy keycloak \
    -o jsonpath='{range .spec.template.spec.containers[0].env[*]}{.name}={.value}{"\n"}{end}'
}
management_status() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s -o /dev/null -w '%{http_code}\n' "http://keycloak:9000$1"
}
```

## Practice tasks

- Run `management_status /health/ready` and `management_status /metrics` and compare the statuses.
- Read the last lines of `kubectl -n ops-demo logs deploy/keycloak` and note the format.
- Turn on `KC_METRICS_ENABLED` and read the first lines of `/metrics`.
- Switch the log output to JSON with `KC_LOG_CONSOLE_OUTPUT=json` and read a line with `jq`.
- Raise the log level of one category and trigger a sign-in to see the new lines.
- Lower the memory limit of the container on purpose and read the reason in `kubectl describe pod`.
