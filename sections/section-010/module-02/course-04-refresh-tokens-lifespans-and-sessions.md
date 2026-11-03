# Refresh Tokens, Token Lifespans And Sessions

An access token lives for five minutes by default. That is short on purpose: a stolen token stops working soon. A user still expects to stay signed in for hours, so the client needs a way to get new tokens without a new login. This part covers the refresh token, the settings that control how long each token and session lives, and the offline token for long-running access.

## Three lifetimes

Keycloak keeps three different clocks, and mixing them up is the most common mistake with sessions.

The **access token lifespan** is how long one access token stays valid. The default is 5 minutes. The **SSO session** is the user's signed-in state at Keycloak, created at login and kept by a cookie in the browser. It ends after the **SSO Session Idle** time without use (30 minutes by default) or the **SSO Session Max** time in total (10 hours by default). A **refresh token** belongs to a session: it can get new tokens as long as the session lives and the refresh token itself is not expired.

<!-- astrona:playground:renew -->

Read the three settings of the realm. They are realm attributes, in seconds:

```sh
NAMESPACE=authcode-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get realms/inventory --fields accessTokenLifespan,ssoSessionIdleTimeout,ssoSessionMaxLifespan,revokeRefreshToken
```

The values are `300`, `1800`, `36000` and `false` for a new realm. In the Admin Console they are on **Realm settings**, on the **Tokens** and **Sessions** tabs.

## Use a refresh token

Get tokens for `alice` and look at the response keys, then use the refresh token. The first command saves the whole response; the second prints the key names and the lifetimes:

```sh
kubectl -n authcode-demo exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli \
    -d username=alice -d password=alice-password -d scope=openid > token-response.json
jq '{expires_in, refresh_expires_in, token_type}' token-response.json
```

`expires_in` is the access token lifespan in seconds. `refresh_expires_in` is how long the refresh token lives; for a normal refresh token it follows the SSO session. Now send the refresh token to the token endpoint:

```sh
REFRESH_TOKEN=$(jq -r .refresh_token token-response.json)
kubectl -n authcode-demo exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=refresh_token -d client_id=inventory-cli \
    -d refresh_token="$REFRESH_TOKEN" | jq '{expires_in, has_access_token: (.access_token != null)}'
```

The answer holds a new access token, and a new refresh token. A public client sends only its `client_id`; a confidential client also sends its secret. The new access token carries the same user and scopes as before.

## Shorten the lifespan and rotate refresh tokens

Shorter access tokens limit the damage of a leak. Set the lifespan to 120 seconds and turn on refresh token rotation, which makes Keycloak refuse a refresh token the second time it is used:

```sh
kcadm update realms/inventory -s accessTokenLifespan=120 -s revokeRefreshToken=true
```

New tokens now show `expires_in` of `120`. With `revokeRefreshToken` on, each refresh returns a new refresh token and the old one stops working. Use the same `REFRESH_TOKEN` twice and the second request returns an `error` of `invalid_grant`. A client that stores the refresh token must always replace it with the newest one.

## Offline tokens

A normal refresh token ends with the SSO session. A client that must keep access for days, such as a mobile application that syncs in the background, asks for the optional scope `offline_access`. Keycloak then issues an **offline token**: a refresh token tied to an offline session, which survives a logout and a server restart, and expires after the **Offline Session Idle** time (30 days by default). Request one and compare the lifetimes:

```sh
kubectl -n authcode-demo exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli \
    -d username=alice -d password=alice-password -d 'scope=openid offline_access' \
  | jq '{refresh_expires_in}'
```

The offline token response shows `refresh_expires_in` as `0`, which means the refresh token does not end with the SSO session. The user must consent to this scope, and an administrator can revoke offline sessions.

You now know the three lifetimes, how a refresh token replaces a login, how to shorten tokens and rotate refresh tokens, and what the offline scope changes. A client that keeps these settings short and exact gets a flow that is safe for a browser.

## Common pitfalls

> [!WARNING]
> - **Mixing the lifetimes.** Raising the access token lifespan does not extend the SSO session, and a long SSO session does not lengthen the access token.
> - **Very long access tokens.** A leaked access token cannot be recalled until it expires. Keep it in minutes.
> - **Reusing an old refresh token after rotation.** With `revokeRefreshToken` on, only the newest one works.
> - **Treating `offline_access` as a default.** It creates long-lived sessions that stay stored in Keycloak. Ask for it only when the client needs it.
> - **Storing refresh tokens in browser local storage.** Any script on the page can read them.
