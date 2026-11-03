# Prerequisites

Before starting this lab you should be able to:

- Set environment variables on a Deployment with `kubectl set env`.
- Read pod logs with `kubectl logs` and filter them with `jq`.
- Explain what the Keycloak management port `9000` serves.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Keycloak 26.8.1** in the namespace **`ops-demo`**, in development mode, with `KC_HEALTH_ENABLED=true`, behind the Service `keycloak` on port `8080` and `9000`.
- A `tester` pod with `curl` and `jq`.
- The administrator of the `master` realm is `admin` with the password `admin` (lab-only credentials).

## Working rules

- Everything is graded on the **final state**: the options of the Deployment, the management endpoint and the log format of the running pod.
- Keycloak takes a few minutes to restart. Wait until the new pod is ready before you test.
- Metrics are a build option, so the server rebuilds its configuration at the next start. A restart after the change is slower than a normal restart.
