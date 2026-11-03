# Prerequisites

Before starting this lab you should be able to:

- Use `kubectl` to run commands in a pod with `kubectl exec`.
- Request a token with the client credentials grant using `curl`.
- Use `kcadm.sh` to read and change objects in a realm.
- Say what an HTTP `401` and an HTTP `403` mean.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Keycloak 26.8.1** in development mode in the namespace **`adminapi-demo`**, behind the Service `keycloak` on port `8080`.
- A `tester` pod with `curl` and `jq`.
- The realm `inventory` with the user `alice` and the client `inventory-auditor`, prepared as the task describes. The administrator of the `master` realm is `admin` with the password `admin` (lab-only credentials).

## Working rules

- Everything is graded on the **final state** of Keycloak, so leave the fix in place and test again at the end.
- Give the service account only the role the task names. A larger role passes your own test and fails the grader.
- `kcadm.sh` is in the Keycloak pod at `/opt/keycloak/bin/kcadm.sh`.
