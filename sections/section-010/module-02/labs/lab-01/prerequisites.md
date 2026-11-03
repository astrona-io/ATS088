# Prerequisites

Before starting this lab you should be able to:

- Use `kubectl` to run commands in a pod with `kubectl exec`.
- Read a client's settings with `kcadm.sh get clients`.
- Explain what a redirect URI is and what the authorization code flow sends to it.
- Explain why a public client needs PKCE (Proof Key for Code Exchange).

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Keycloak 26.8.1** in development mode in the namespace **`authcode-demo`**, behind the Service `keycloak` on port `8080`.
- A `tester` pod with `curl`, `jq` and `openssl`.
- The realm `inventory` with the user `alice` and the client `inventory-web`, prepared as the task describes. The administrator of the `master` realm is `admin` with the password `admin` (lab-only credentials).

## Working rules

- Everything is graded on the **final state** of the client in Keycloak, so leave the fix in place.
- Change the client with `kcadm.sh update`, not by creating a new client.
- `kcadm.sh` is in the Keycloak pod at `/opt/keycloak/bin/kcadm.sh`. You may also use the Admin Console through `kubectl -n authcode-demo port-forward svc/keycloak 8080:8080`.
