# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Realms

## Scenario

The inventory team started on the Keycloak server in `realmscapstone-demo` in a hurry. They created the realm `inventory`, but it did not work at once, so they disabled it. Then they put their command-line client `inventory-cli` and their test user `alice` (password `alice-password`) in `master`, and that worked. Other teams already depend on the realm role `inventory-viewer` that the `inventory` realm holds.

A security review found the application in the administration realm. The team needs it moved before the server goes live.

## Your task

Move the application into its own realm, using `kcadm.sh` inside the `keycloak` pod. The administrator is `admin` with the password `admin` (lab-only credentials).

1. Find what is in `master` that does not belong there, and find why the `inventory` realm cannot issue tokens.
2. Make the `inventory` realm issue tokens.
3. Give `inventory` a client `inventory-cli` (a public client with direct access grants on and the standard flow off) and a user `alice` with the email `alice@example.com` (verified), the first name `Alice`, the last name `Example`, and the permanent password `alice-password`.
4. Remove the application's client and user from `master`.

The password grant (direct access grants) is used here only so the setup can be tested from a terminal. OAuth 2.1 drops it, and a real application uses the authorization code flow.

## Constraints

- **Do not delete and recreate the `inventory` realm.** It holds the realm role `inventory-viewer`, which must still exist at the end.
- Do not change the `admin` user or its password, and do not delete any built-in client of `master`.
- `master` must end with no client `inventory-cli` and no user `alice`.

## Done when

- The realm `inventory` is enabled and still holds the realm role `inventory-viewer`.
- `inventory-cli` in `inventory` is a public client with direct access grants on and the standard flow off.
- A password grant from the `tester` pod to `http://keycloak:8080/realms/inventory/protocol/openid-connect/token` with `inventory-cli`, `alice` and `alice-password` returns an access token whose `iss` is `http://keycloak:8080/realms/inventory` and whose `preferred_username` is `alice`.
- The same request sent to the `master` realm is refused, and `master` holds no client `inventory-cli` and no user `alice`.
- `admin` still signs in to `master` with the password `admin` through the client `admin-cli`.
