# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** Identity protocols

## Scenario

A nightly report job must call the inventory API with its own access token. No user is signed in when it runs. A colleague created the client `inventory-reporter` in the realm `inventory` for it, but the job cannot get a token. This request from the `tester` pod fails:

```sh
kubectl -n protocols-demo exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=client_credentials \
    -d client_id=inventory-reporter
```

## Your task

In the realm `inventory` and the namespace `protocols-demo`:

1. Find out from the token endpoint's response and the client's settings why the request fails.
2. Change `inventory-reporter` so it can use the client credentials grant: it must be a confidential client that proves who it is with a client secret, and it must have a service account.
3. Store the client's secret in a Kubernetes Secret named `inventory-reporter-credentials` in the namespace `protocols-demo`, under the key `client-secret`. The report job will read it from there.

## Constraints

- **Turn on only what the job needs.** Direct access grants (the password grant) and the standard flow (the browser sign-in) must stay off for `inventory-reporter`.
- Do not create a new client. Fix `inventory-reporter`.
- Do not change the client `inventory-cli` or the user `alice`.

## Done when

- `inventory-reporter` is a confidential client with service accounts on, and direct access grants and the standard flow are off.
- The Secret `inventory-reporter-credentials` holds the client's current secret under `client-secret`.
- A client credentials request from the `tester` pod with that secret returns an access token whose `azp` claim is `inventory-reporter`.
