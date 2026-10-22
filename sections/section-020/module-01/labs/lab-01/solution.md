# Solution: Create An Application Realm With kcadm.sh

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the realm `inventory` is enabled, `inventory-cli` has the right settings, alice gets a token from `inventory` with the right issuer, and `master` holds no application client or user.

## Step 1: Sign kcadm.sh in to the master realm

`kcadm.sh` is Keycloak's administration command-line tool. It calls the Admin REST API, and it must sign in before its first command. Define a helper that runs it inside the Keycloak pod, with its configuration file in `/tmp`, then sign in as `admin`:

```sh
NAMESPACE=realms-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

Administrators always sign in through `master`, even to manage another realm. If a later command answers `401 Unauthorized`, the sign-in has expired; run `config credentials` again.

## Step 2: Create the realm

```sh
kcadm create realms -s realm=inventory -s enabled=true
kcadm get realms --fields realm,enabled
```

The first command reports that it created a realm with the ID `inventory`. The list shows `master` and `inventory`, both with `enabled` set to `true`.

## Step 3: Create the user and set the password

Every user and client command from here on has `-r inventory`. Without it, `kcadm.sh` works on `master`, the realm you signed in to, and the grader rejects anything for the application in `master`.

```sh
kcadm create users -r inventory -s username=alice -s enabled=true \
  -s email=alice@example.com -s emailVerified=true \
  -s firstName=Alice -s lastName=Example
kcadm set-password -r inventory --username alice --new-password alice-password
```

The email, first name and last name are required by the realm's default user profile. Without them, the profile is not complete, and the token request in the last step fails. `set-password` without `--temporary` sets a permanent password, so no required action blocks the token request.

## Step 4: Create the client

```sh
kcadm create clients -r inventory -s clientId=inventory-cli -s enabled=true \
  -s publicClient=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=true
kcadm get clients -r inventory -q clientId=inventory-cli \
  --fields clientId,publicClient,standardFlowEnabled,directAccessGrantsEnabled
```

The `get` shows `publicClient` and `directAccessGrantsEnabled` as `true` and `standardFlowEnabled` as `false`. A public client has no secret, which suits a command-line tool. The password grant is on only so the setup can be tested from a terminal; OAuth 2.1 drops it, and a real application uses the authorization code flow.

## Step 5: Prove the realm works

Request a token for alice from the `tester` pod and decode its payload:

```sh
kubectl -n realms-demo exec deploy/tester -- curl -s \
  -d grant_type=password -d client_id=inventory-cli \
  -d username=alice -d password=alice-password \
  http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
  | jq -r .access_token \
  | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | . + ("=" * ((4 - length % 4) % 4)) | @base64d | fromjson | {iss, azp, preferred_username}'
```

The three claims are `iss` `http://keycloak:8080/realms/inventory`, `azp` `inventory-cli` and `preferred_username` `alice`. If the first `jq` prints `null` instead, the response was an error. Run the `curl` alone to read it: `invalid_client` points at the client, `invalid_grant` at the user name, password or an incomplete account.

## Step 6: Check that master is clean

```sh
kcadm get clients -r master -q clientId=inventory-cli --fields clientId
kcadm get users -r master -q username=alice -q exact=true --fields username
```

Both commands print an empty list. If either one finds an object, you created it in `master` by leaving out `-r inventory`. Delete it with `kcadm delete clients/<id> -r master` or `kcadm delete users/<id> -r master`, using the `id` from `--fields id`.

## Step 7: Submit

Send the lab for grading:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Create the client and user without `-r inventory` | They land in `master`, the token's issuer is `/realms/master`, and the grader rejects it |
| Use the built-in `admin-cli` client of `inventory` | It is not the client the team asked for, and the grader checks `inventory-cli` |
| Leave out the email, first name and last name | The user profile is not complete, and the token request fails with an error that the account is not fully set up |
| Set the password with `--temporary` | The user gets the required action to update the password, and the token request fails |

## Common mistakes

- Forgetting that `kcadm.sh` signs in to `master` and works there by default.
- Using the `clientId` where a resource path needs the generated `id`.
- Reading only the HTTP status of the token request. Read the JSON: the `error` and `error_description` fields name the cause.

## Practice on your own

- Create a second realm with the same three commands and compare the `kid` values at `/realms/<realm>/protocol/openid-connect/certs`.
- Disable the realm with `kcadm update realms/inventory -s enabled=false`, request a token, and read the error. Enable it again.
- Write the commands from this solution into one shell script and run it against a fresh server.
