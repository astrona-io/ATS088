# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** Authorization code flow

## Scenario

The `inventory` team ships a browser application at `https://inventory.example.test`. It signs users in with the authorization code flow through the public client `inventory-web` in the realm `inventory`. During development someone registered the client with wildcards so that every test address works. A security review now says the client is too open.

## Your task

In the realm `inventory` and the namespace `authcode-demo`, change the client `inventory-web` so that:

1. The only valid redirect URI is `https://inventory.example.test/callback`.
2. The only allowed web origin is `https://inventory.example.test`.
3. Keycloak requires PKCE with the `S256` code challenge method for this client.
4. The password grant (direct access grants) is turned off for this client.

## Constraints

- Keep the standard flow turned on and keep `inventory-web` a public client.
- Do not create a new client. Change `inventory-web`.
- Do not change the client `inventory-cli`, the user `alice` or any realm setting.

## Done when

- The redirect URIs of `inventory-web` contain `https://inventory.example.test/callback` and no wildcard.
- The web origins contain `https://inventory.example.test` and no wildcard.
- The client attribute `pkce.code.challenge.method` is `S256`.
- Direct access grants are off, the standard flow is on and `inventory-web` is still a public client.
