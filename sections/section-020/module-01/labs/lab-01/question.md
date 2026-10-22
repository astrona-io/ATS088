# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Realms

## Scenario

A team wants to move its inventory command-line tool to Keycloak. The server in the namespace `realms-demo` is brand new: it has only the `master` realm and the administrator `admin` (password `admin`, lab-only credentials). The team has asked for a realm of their own, set up from the terminal so the same commands can run on their other servers.

## Your task

Use `kcadm.sh` inside the `keycloak` pod in `realms-demo`:

1. Create the realm `inventory`, enabled.
2. In `inventory`, create the user `alice` with the email `alice@example.com` (marked as verified), the first name `Alice` and the last name `Example`. Give the user the permanent password `alice-password`.
3. In `inventory`, create the client `inventory-cli`: a public client with direct access grants on and the standard flow off.

The password grant (direct access grants) is used here only so the setup can be tested from a terminal. OAuth 2.1 drops it, and a real application uses the authorization code flow.

## Constraints

- **Nothing for the application in `master`.** The `master` realm must not hold a client `inventory-cli` or a user `alice`.
- Do not change the `admin` user or its password.
- The password of `alice` must not be temporary.

## Done when

- The realm `inventory` exists and is enabled.
- `inventory-cli` in `inventory` is a public client with direct access grants on and the standard flow off.
- A password grant request from the `tester` pod to `http://keycloak:8080/realms/inventory/protocol/openid-connect/token` with `inventory-cli`, `alice` and `alice-password` returns an access token whose `iss` is `http://keycloak:8080/realms/inventory` and whose `preferred_username` is `alice`.
- The `master` realm holds no client `inventory-cli` and no user `alice`.
