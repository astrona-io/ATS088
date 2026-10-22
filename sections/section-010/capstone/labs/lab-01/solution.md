# Solution: Make A User Sign-In Work End To End

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: `alice` gets an ID token through `inventory-cli` with the right `preferred_username` and `iss`, `alice` is enabled and has no required actions, and `alice` and `inventory-cli` are the original objects, with `inventory-cli` still public.

Three faults stand in the way, and Keycloak checks them in order: first the client, then the user. Each fix moves the error to the next fault, so the method is the same every time: request a token, read the error, fix one thing, request again.

## Step 1: Set up the helpers

Define a helper that sends the task's request and prints only the fields that matter, and the `kcadm` helper for the administration tool:

```sh
NAMESPACE=protocolscapstone-demo
request_tokens() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password \
      -d client_id=inventory-cli \
      -d username=alice \
      -d password=alice-password \
      -d scope=openid
}
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

## Step 2: The client does not allow the password grant

Send the request and read the error:

```sh
request_tokens | jq '{error, error_description}'
```

The `error` is about the client, and the `error_description` says the client is not allowed to use direct access grants. Direct access grants is Keycloak's name for the password grant. Check the client's settings:

```sh
kcadm get clients -r inventory -q clientId=inventory-cli \
  --fields id,clientId,publicClient,directAccessGrantsEnabled
```

`directAccessGrantsEnabled` is `false`. `publicClient` is `true`, which is correct for a command-line tool and must stay that way. Turn on only the grant the client uses:

```sh
CLI_ID=$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$CLI_ID" -r inventory -s directAccessGrantsEnabled=true
```

## Step 3: The user is disabled

Request the tokens again:

```sh
request_tokens | jq '{error, error_description}'
```

The error has changed. The `error` is now `invalid_grant`, and the `error_description` says the account is disabled. The client is fixed; Keycloak now gets as far as the user. Read the user's state:

```sh
ALICE_ID=$(kcadm get users -r inventory -q username=alice -q exact=true --fields id --format csv --noquotes | tr -d '\r')
kcadm get "users/$ALICE_ID" -r inventory --fields id,username,enabled,requiredActions
```

`enabled` is `false`, and `requiredActions` holds `UPDATE_PASSWORD`. Fix one thing at a time, so you can see what each change does. Enable the user first:

```sh
kcadm update "users/$ALICE_ID" -r inventory -s enabled=true
```

## Step 4: The user must change the password first

Request the tokens again:

```sh
request_tokens | jq '{error, error_description}'
```

The `error` is still `invalid_grant`, and the `error_description` now says the account is not fully set up. A required action is a step Keycloak makes a user finish at the next sign-in, for example changing a temporary password. The password grant has no login page where the user could do that, so Keycloak refuses the grant until the list is empty. Someone set a temporary password for `alice`, and that added `UPDATE_PASSWORD`.

`alice` must keep her password, so clear the required action instead of setting a new password:

```sh
kcadm update "users/$ALICE_ID" -r inventory -s 'requiredActions=[]'
```

In the Admin Console the same change is on the user's **Details** tab: remove **Update Password** from **Required user actions**, and turn **Enabled** on.

## Step 5: Prove the result with the ID token

Request the tokens once more, and decode the ID token:

```sh
request_tokens | jq -r .id_token \
  | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson | {typ, iss, aud, preferred_username, email}'
```

The payload shows `typ` as `ID`, `iss` as `http://keycloak:8080/realms/inventory`, `aud` as `inventory-cli`, `preferred_username` as `alice` and her email address. The client is still public, and both objects keep their original IDs, because you only updated them.

## Step 6: Submit

Send the capstone for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete `alice` and create her again | The new user has a new ID, so every application that stored her `sub` claim loses her; the grader rejects it |
| Create a new client instead of fixing `inventory-cli` | The tool is configured with `inventory-cli`; the new client ID changes nothing for it, and the grader rejects a recreated client |
| Make `inventory-cli` confidential | A command-line tool on a laptop cannot keep a secret; the grader requires a public client |
| Reset the password to a new value | `alice` loses the password she knows, and the task forbids it |

## Common mistakes

- Changing several settings before requesting a token again, so you never learn which fault was which.
- Reading only the HTTP status. Every fault here returns an error, but the `error_description` names the cause.
- Forgetting `scope=openid`, then wondering why the response has no `id_token`.
- Fixing `enabled` and stopping there. The required action blocks the password grant on its own.

## Practice on your own

- Set a temporary password for `alice` again with `kcadm set-password -r inventory --username alice --new-password alice-password --temporary`, and check which required action appears.
- Disable the client `inventory-cli` with `-s enabled=false` and read the error it produces. Compare it with the error for a disabled user.
- Add `CONFIGURE_TOTP` to `alice`'s required actions and request a token. Remove it again afterwards.
