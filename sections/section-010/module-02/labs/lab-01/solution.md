# Solution: Secure A Single-Page Client With PKCE And Exact Redirect URIs

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the redirect URIs and web origins of `inventory-web` are exact, with no wildcard; the client requires PKCE with `S256` and keeps the standard flow; and direct access grants are off while the client stays public.

## Step 1: Read the client's settings

Define the `kcadm` helper, sign in to the `master` realm as the lab-only administrator, and read the client:

```sh
NAMESPACE=authcode-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get clients -r inventory -q clientId=inventory-web \
  --fields id,clientId,publicClient,standardFlowEnabled,directAccessGrantsEnabled,redirectUris,webOrigins,attributes
```

`redirectUris` and `webOrigins` hold `*`, so any address may receive an authorization code. `directAccessGrantsEnabled` is `true`, so the client can also send user passwords to the token endpoint. The attributes do not contain `pkce.code.challenge.method`, so PKCE is optional.

## Step 2: Change the redirect URI and the web origin

Keep the client's internal ID (the `id` field, a UUID) in a variable. Then replace both lists:

```sh
CLIENT_ID=$(kcadm get clients -r inventory -q clientId=inventory-web --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$CLIENT_ID" -r inventory \
  -s 'redirectUris=["https://inventory.example.test/callback"]' \
  -s 'webOrigins=["https://inventory.example.test"]'
```

In the Admin Console the same fields are on the client's **Settings** tab, under **Valid redirect URIs** and **Web origins**.

## Step 3: Require PKCE and turn off the password grant

```sh
kcadm update "clients/$CLIENT_ID" -r inventory \
  -s 'attributes."pkce.code.challenge.method"=S256' \
  -s directAccessGrantsEnabled=false
```

In the Admin Console, PKCE is **Proof Key for Code Exchange Code Challenge Method** on the **Advanced** tab, under **Advanced settings**. **Direct access grants** is on the **Settings** tab under **Authentication flow**.

## Step 4: Check the result

Read the client again and look at the four values:

```sh
kcadm get clients -r inventory -q clientId=inventory-web \
  --fields publicClient,standardFlowEnabled,directAccessGrantsEnabled,redirectUris,webOrigins,attributes
```

You can also test the behaviour. A request to the authorization endpoint with an unregistered redirect URI must not return the login page any more:

```sh
kubectl -n authcode-demo exec deploy/tester -- \
  curl -s -o /dev/null -w '%{http_code}\n' \
  'http://keycloak:8080/realms/inventory/protocol/openid-connect/auth?client_id=inventory-web&response_type=code&scope=openid&redirect_uri=https://other.example.test/callback'
```

The status code is an error status, not `200`.

## Step 5: Submit

Send the lab for grading:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Keep `*` and add the exact URI to the list | The wildcard still matches every address, so the check for no wildcard fails |
| Turn off the standard flow | The browser application can no longer sign users in |
| Create a second client with the right settings | The task names `inventory-web`; the broken client stays in place |
| Make the client confidential | A browser application cannot keep a secret; the task requires a public client |

## Common mistakes

- Sending `redirectUris` as a plain string instead of a JSON list in `kcadm.sh`.
- Adding a trailing slash to the web origin. An origin has no path.
- Setting the PKCE value in lower case. The value is `S256`.
- Mixing up the client's `id` (a UUID used in Admin REST API paths) with its `clientId` (`inventory-web`).

## Practice on your own

- Use the authorization endpoint with `code_challenge_method=S256` and a valid challenge and check that the login page returns again.
- Change the redirect URI to `https://inventory.example.test/*` and describe in one sentence what it still allows.
- Set the PKCE attribute to an empty value and run `astrona submit` to read which check fails. Then set it back.
