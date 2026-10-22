# Solution: Move An Application Out Of The Master Realm

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks five things: `inventory` is enabled and kept its realm role, `inventory-cli` has the right settings, alice gets a token from `inventory`, `master` is clean and refuses the application, and `admin` still signs in.

## Step 1: Sign in and reproduce the problem

Define the helpers and sign `kcadm.sh` in to `master`. `get_user_token` sends a password grant from the `tester` pod and prints the JSON response:

```sh
NAMESPACE=realmscapstone-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
get_user_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
    -d grant_type=password -d client_id="$2" -d username="$3" -d password="$4" \
    "http://keycloak:8080/realms/$1/protocol/openid-connect/token"
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

Ask both realms for a token for alice:

```sh
get_user_token master inventory-cli alice alice-password | jq 'keys'
get_user_token inventory inventory-cli alice alice-password
```

`master` answers with a token response whose keys include `access_token`. That is the problem the review found: the administration realm issues tokens to the application. `inventory` does not issue a token; it answers with an error instead.

## Step 2: Find what is in the wrong place

List the realms and look for the application in `master`:

```sh
kcadm get realms --fields realm,enabled
kcadm get clients -r master -q clientId=inventory-cli --fields id,clientId
kcadm get users -r master -q username=alice -q exact=true --fields id,username
```

`inventory` shows `"enabled" : false`, which explains its error: a disabled realm issues no tokens. The two other commands each find one object in `master`. Note both `id` values; you need them to delete the objects at the end.

## Step 3: Enable the realm instead of recreating it

```sh
kcadm update realms/inventory -s enabled=true
kcadm get roles -r inventory --fields name
```

The role list includes `inventory-viewer`, which other teams depend on, next to the realm's default roles. Deleting the realm and creating it again would also have made it work, and it would have removed that role, the realm's keys and every setting with it.

## Step 4: Create the client and the user in inventory

Every command here has `-r inventory`:

```sh
kcadm create clients -r inventory -s clientId=inventory-cli -s enabled=true \
  -s publicClient=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=true
kcadm create users -r inventory -s username=alice -s enabled=true \
  -s email=alice@example.com -s emailVerified=true \
  -s firstName=Alice -s lastName=Example
kcadm set-password -r inventory --username alice --new-password alice-password
```

You cannot move a user or a client from one realm to another; you create them again in the new realm. The user gets a new generated ID, and the password is set again, because credentials belong to the user in one realm. The password grant is on only so the setup can be tested from a terminal; OAuth 2.1 drops it, and a real application uses the authorization code flow.

## Step 5: Prove the application realm works

```sh
get_user_token inventory inventory-cli alice alice-password \
  | jq -r .access_token \
  | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | . + ("=" * ((4 - length % 4) % 4)) | @base64d | fromjson | {iss, azp, preferred_username}'
```

The claims are `iss` `http://keycloak:8080/realms/inventory`, `azp` `inventory-cli` and `preferred_username` `alice`. The application now works in its own realm, while the old copy in `master` still exists.

## Step 6: Remove the application from master

Delete both objects by their generated `id`, using the values from step 2:

```sh
kcadm delete clients/<CLIENT_ID> -r master
kcadm delete users/<USER_ID> -r master
```

Replace `<CLIENT_ID>` and `<USER_ID>` with the `id` values. Get them again with the two `get` commands from step 2 if you no longer have them. Be careful to pass `-r master` and the right ID: `admin`, `admin-cli` and the other built-in clients of `master` must stay.

## Step 7: Prove master is clean and the administrator is untouched

```sh
get_user_token master inventory-cli alice alice-password
get_user_token master admin-cli admin admin | jq -r 'has("access_token")'
```

The first request now returns an error instead of a token: `master` no longer knows the client `inventory-cli`. The second prints `true`: the administrator still signs in to `master` through `admin-cli`.

## Step 8: Submit

Send the capstone for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete `inventory` and create it again | The realm works, but the role `inventory-viewer`, its keys and its settings are gone; the grader checks the role |
| Leave the old client and user in `master` "for a while" | The application still has a way into the administration realm; the grader requires `master` to refuse it |
| Delete the user in `master` by user name with a broad search | `-q username=` matches parts of names without `-q exact=true`; always check the `id` before you delete |
| Change the `admin` password while you are there | The grader, and every script that signs in as `admin`, can no longer sign in |

## Common mistakes

- Forgetting `-r inventory`, so the new client and user land in `master` again.
- Expecting a disabled realm to show an error in the Admin Console. It only shows the switch; the token endpoint is where you see the effect.
- Deleting objects by `clientId` or user name. Resource paths take the generated `id`.

## Practice on your own

- Before you delete the user in `master`, request a token for it and compare the `iss` and `sub` claims with the token from `inventory`.
- Assign `inventory-viewer` to alice with `kcadm add-roles -r inventory --uusername alice --rolename inventory-viewer` and find the role in the token's `realm_access` claim.
- Write steps 3 to 6 as one script that a team could run on their other servers.
