# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Identity protocols

## Scenario

The command-line tool `inventory-cli` signs users in to the realm `inventory` and reads who they are from the ID token. Since a change last week, the user `alice` cannot get any token. Her password is `alice-password`, and she has not changed it. This request from the `tester` pod should return an access token and an ID token, but it does not:

```sh
kubectl -n protocolscapstone-demo exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password \
    -d client_id=inventory-cli \
    -d username=alice \
    -d password=alice-password \
    -d scope=openid
```

The password grant is used here only so you can test from a terminal. A real application would use the authorization code flow.

## Your task

In the realm `inventory` and the namespace `protocolscapstone-demo`:

1. Find every reason the request fails. Use the `error` and `error_description` fields of each response, and the settings of the client and the user. There is more than one fault, and each fault hides the next one.
2. Fix each fault so that the request above returns an ID token.
3. Prove the result by decoding the ID token.

## Constraints

- **Fix the objects that exist.** Do not delete or recreate the user `alice` or the client `inventory-cli`. The grader compares their IDs with the ones the lab started with.
- `inventory-cli` must stay a public client. Do not give it a client secret.
- Keep `alice`'s password as `alice-password`.
- Do not change the ConfigMap `capstone-baseline`.

## Done when

- The request above returns an `id_token` whose `preferred_username` is `alice` and whose `iss` is `http://keycloak:8080/realms/inventory`.
- `alice` is enabled and has no required actions.
- `alice` and `inventory-cli` have the same IDs as at the start, and `inventory-cli` is still a public client.
