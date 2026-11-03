# Claims A Resource Server Must Check

A valid signature says that Keycloak issued the token. It does not say that the token is still fresh, that it came from the right realm, or that it was meant for this API. Each of these is a claim in the payload, and the resource server must check each one. This part lists the claims, shows how a token is aimed at one API with an audience, and ends with a graded lab that fixes a missing audience.

## The claims to check

| Claim | What it says | What the API checks |
| --- | --- | --- |
| `iss` | The issuer: the URL of the realm that signed the token | Equals the expected realm URL exactly |
| `exp` | The time the token expires, in seconds since 1970 | Is in the future |
| `aud` | The audience: the APIs the token is meant for | Contains this API's identifier |
| `azp` | The authorized party: the client that asked for the token | Is a client the API accepts |
| `scope` | The scopes granted to the client | Contains the scope the call needs |

The check of `iss` stops a token from another realm or another Keycloak server. The check of `exp` stops an old token. The check of `aud` stops a token that was issued for service A from being replayed against service B. Without it, any token from the realm opens every API in the realm.

<!-- astrona:playground:renew -->

Request tokens and read the claims:

```sh
NAMESPACE=tokenval-demo
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
get_tokens
show_claims | jq '{iss, exp, iat, aud, azp, scope}'
```

The issuer is `http://keycloak:8080/realms/inventory`. The difference `exp` minus `iat` is the token lifespan, `300` seconds by default. `azp` is `inventory-cli`. The `aud` claim lists the clients whose roles are in the token, for example `account`, or it is missing. It does not list `inventory-api`, so a resource server that requires its own name in `aud` would reject this token.

## Add an audience with a protocol mapper

Keycloak adds an audience with a protocol mapper of the type **Audience**. The mapper takes a client id and writes it into the `aud` claim. Put it in the **dedicated scope** of the client that asks for the token, which is the scope that belongs to that one client. Use the Admin Console under the client's **Client scopes** tab, or `kcadm.sh`:

```sh
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
CLI_ID=$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes | tr -d '\r')
kcadm create "clients/$CLI_ID/protocol-mappers/models" -r inventory \
  -s name=audience-inventory-api -s protocol=openid-connect \
  -s protocolMapper=oidc-audience-mapper \
  -s 'config."included.client.audience"=inventory-api' \
  -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false'
```

The setting `included.client.audience` takes the id of a registered client. The setting `included.custom.audience` takes any text, for an API that is not a client. Request a new token and read `aud`:

```sh
get_tokens
show_claims | jq '{aud}'
```

The claim now lists `inventory-api`. A mapper changes only tokens issued after it exists, so always request a new token. An audience also appears by itself when you give the user a role of the target client and the **Audience Resolve** mapper of the `roles` scope is active, but an explicit audience mapper is clearer.

You now know which claims an API checks and how to put an audience into a token. The open question is how an API that does not want to verify signatures can still ask Keycloak about a token. That is token introspection, in the next part. First, practise the audience.

## Common pitfalls

> [!WARNING]
> - **Skipping the `aud` check.** A token for one API then works on all APIs in the realm.
> - **Comparing `iss` loosely.** The issuer must match the realm URL exactly, including the scheme and the port.
> - **Adding the audience to a shared client scope.** Every client that uses the scope then gets the audience.
> - **Turning on `id.token.claim` only.** The API reads the access token.
> - **Reading `scope` as the audience.** `scope` says what the client may do. `aud` says which API the token is for.

## Your mission: Add The Audience inventory-api To The Tokens Of inventory-cli

You can now check the claims of a token and add an audience with a mapper. The graded lab gives you a realm where the tokens of `inventory-cli` do not list `inventory-api`, and asks you to add the audience without touching shared client scopes or the token lifespan.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-088-playground-010-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS088.git -c sections/section-010/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-088-lab-010-03
astrona start ats-088-playground-010-03
```
