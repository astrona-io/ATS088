# Prerequisites

Before starting this capstone you should be able to:

- Request a token from a realm's token endpoint with `curl`, and read the `error` and `error_description` fields of a refusal.
- Decode a JSON Web Token (JWT) payload with `jq` and read its claims.
- Read and change client and user settings with `kcadm.sh` or the Admin Console.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Keycloak 26.8.1** in development mode in the namespace **`protocolscapstone-demo`**, behind the Service `keycloak` on port `8080`.
- A `tester` pod with `curl` and `jq`.
- The realm `inventory`, prepared as the task describes. The administrator of the `master` realm is `admin` with the password `admin` (lab-only credentials).
- A ConfigMap `capstone-baseline` that the grader uses. Do not change it.

## Working rules

- Everything is graded on the **final state** of Keycloak, so request the tokens again at the end and leave the fixes in place.
- Change one setting at a time and request a token after each change. Each fault gives a different error, so the error tells you which one is next.
- `kubectl`, `curl` and `jq` are available, and `kcadm.sh` is in the Keycloak pod at `/opt/keycloak/bin/kcadm.sh`. You may also use the Admin Console through `kubectl -n protocolscapstone-demo port-forward svc/keycloak 8080:8080`.
