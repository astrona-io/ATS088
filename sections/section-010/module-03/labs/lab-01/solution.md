# Solution: Add The Audience inventory-api To The Tokens Of inventory-cli

Work the task yourself first. Running `astrona submit -c sections/section-010/module-03/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: a fresh token for `alice` lists `inventory-api` in `aud` and still has the right issuer and user; the introspection endpoint returns `active: true` for it; and the lifespan did not change.

## Step 1: Define the helpers

```sh
NAMESPACE=tokenval-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
get_tokens() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=alice -d password=alice-password -d scope=openid > tokens.json
}
show_claims() {
  jq -r .access_token tokens.json \
    | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson'
}
```

## Step 2: Read the starting state

```sh
get_tokens
show_claims | jq '{iss, preferred_username, aud}'
```

The `aud` claim does not list `inventory-api`. It holds the clients whose roles are in the token, or it is missing.

## Step 3: Add the audience mapper

Find the internal id of `inventory-cli` and add a mapper of the type `oidc-audience-mapper` to its dedicated scope:

```sh
CLI_ID=$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes | tr -d '\r')
kcadm create "clients/$CLI_ID/protocol-mappers/models" -r inventory \
  -s name=audience-inventory-api -s protocol=openid-connect \
  -s protocolMapper=oidc-audience-mapper \
  -s 'config."included.client.audience"=inventory-api' \
  -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false'
```

## Step 4: Check the new token

```sh
get_tokens
show_claims | jq '{iss, preferred_username, aud}'
```

`aud` now lists `inventory-api`. Introspect the access token as the resource server:

```sh
ACCESS_TOKEN=$(jq -r .access_token tokens.json)
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s -u inventory-api:inventory-api-secret \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token/introspect \
    -d token="$ACCESS_TOKEN" | jq '{active, aud, username}'
```

`active` is `true`.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Add the mapper to the `profile` client scope | Every client that uses `profile` now lists `inventory-api` |
| Make the API skip the `aud` check | The API accepts tokens meant for other services |
| Raise the access token lifespan | It does not add the audience, and it makes leaked tokens last longer |

## Common mistakes

- Using `included.custom.audience` for a value that is a client id. For a registered client use `included.client.audience`.
- Turning on only `id.token.claim`. The API reads the access token.
- Checking an old token. A mapper changes only tokens issued after it.

## Practice on your own

- Call the UserInfo endpoint with the new token.
- Add the audience mapper for a second API client and read `aud` as a list.
- Log out with the refresh token and introspect the access token again.
