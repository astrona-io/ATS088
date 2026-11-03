# Prerequisites

Before starting this lab you should be able to:

- Request an access token from the token endpoint with `curl` and decode its payload with `jq`.
- Explain what the `aud` (audience) claim of a token says and who checks it.
- Create a protocol mapper with `kcadm.sh`.
- Call the token introspection endpoint with client authentication.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Keycloak 26.8.1** in the namespace **`tokenval-demo`**, in development mode, behind the Service `keycloak` on port `8080`.
- The realm **`inventory`** with the user `alice` (password `alice-password`), the public client `inventory-cli` with direct access grants on, and the confidential client `inventory-api` with the secret `inventory-api-secret`.
- A `tester` pod with `curl` and `jq`.
- The administrator of the `master` realm is `admin` with the password `admin` (lab-only credentials).

## Working rules

- Everything is graded on the **final state** of Keycloak: a fresh token for `alice` from `inventory-cli` and an introspection call by `inventory-api`.
- The password grant is on the client only so you and the grader can get a user token from a terminal. A real application uses the authorization code flow.
- Keycloak runs on `http://keycloak:8080` inside the cluster, so the issuer is `http://keycloak:8080/realms/inventory`.
