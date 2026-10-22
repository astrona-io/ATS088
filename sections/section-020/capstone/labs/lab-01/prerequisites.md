# Prerequisites

Before starting this capstone you should be able to:

- Explain why the `master` realm is only for administration.
- Use `kcadm.sh` to sign in, and to create, read, update and delete realms, users and clients.
- Request a token with `curl` and decode its payload with `jq`.

## What the environment gives you

The capstone environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Keycloak 26.8.1** in development mode in the namespace **`realmscapstone-demo`**, behind the Service `keycloak` on port `8080`, with `kcadm.sh` at `/opt/keycloak/bin/kcadm.sh` inside the pod.
- The administrator `admin` with the password `admin` in `master`. These are lab-only credentials.
- A `tester` pod with `curl` and `jq`.
- The application set up in the wrong place, as the task describes.

## Working rules

- Everything is graded on the **final state of Keycloak**, so request the tokens
  at the end and leave your work in place.
- Change one thing at a time and check it. A token request after each step
  tells you exactly which change made the difference.
- `kubectl`, `jq` and `kcadm.sh` (inside the Keycloak pod) are available. No
  internet access is needed once the environment is up.
