# Prerequisites

Before starting this lab you should be able to:

- Use `kubectl exec` to run a command in a pod.
- Explain what a realm, a user and a client are in Keycloak.
- Read a JSON response with `jq`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Keycloak 26.8.1** in development mode in the namespace **`realms-demo`**, behind the Service `keycloak` on port `8080`, with `kcadm.sh` at `/opt/keycloak/bin/kcadm.sh` inside the pod.
- Only the `master` realm, with the administrator `admin` and the password `admin`. These are lab-only credentials.
- A `tester` pod with `curl` and `jq`.

Nothing the task asks you to create has been created for you.

## Working rules

- Everything is graded on the **final state of Keycloak**, so request the token
  at the end and leave your work in place.
- Do not change the `admin` user or its password; the grader signs in with it.
- `kubectl`, `jq` and `kcadm.sh` (inside the Keycloak pod) are available. No
  internet access is needed once the environment is up.
