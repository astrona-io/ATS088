# Managing Realms With kcadm.sh

Clicking through the Admin Console is fine for one realm on one server. It is not fine when the same realm has to exist on a test server, a staging server and a production server, or when a script has to set it up inside a pipeline. For that you need a command-line tool that does what the console does. This part uses `kcadm.sh` to build an application realm with a user and a client, and proves it works with a token.

## What kcadm.sh is and how it signs in

`kcadm.sh` is Keycloak's administration command-line tool. It ships in the Keycloak image at `/opt/keycloak/bin/kcadm.sh`. Every command it runs is a call to the **Admin REST API**, the HTTP API that the Admin Console also uses. So anything you can click in the console, `kcadm.sh` can do too.

Before its first command, `kcadm.sh` must sign in. `kcadm.sh config credentials` asks a realm for a token with a user name and password, and saves the token in a configuration file. Every later command sends that token. The playground runs the tool inside the Keycloak pod, so it reaches the server at `http://localhost:8080` and needs no extra network access.

Paste these helpers into your terminal. `kcadm` runs `kcadm.sh` in the Keycloak pod and keeps its configuration file in `/tmp`, so it never depends on a writable home directory. `get_user_token` asks a realm for a token with the password grant from the `tester` pod and prints the JSON response. `decode_token` prints the payload of a token as JSON:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=realms-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
get_user_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s \
    -d grant_type=password -d client_id="$2" -d username="$3" -d password="$4" \
    "http://keycloak:8080/realms/$1/protocol/openid-connect/token"
}
decode_token() {
  jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | . + ("=" * ((4 - length % 4) % 4)) | @base64d | fromjson'
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

The last line signs in to the `master` realm as `admin`, with lab-only credentials. `kcadm.sh` prints one line that says it is logging in to `http://localhost:8080` as user `admin` of realm `master`. Administrators always sign in through `master`, even when they manage another realm. The sign-in expires after a while; when a command answers `401 Unauthorized`, run `kcadm config credentials` again.

## Creating the realm

Every `kcadm.sh` command has the same shape: a verb (`create`, `get`, `update`, `delete`), a resource path such as `realms` or `users`, and options. `-s name=value` sets one field of the object, and `-r <realm>` says which realm the command works on. Create the application realm and list all realms:

```sh
kcadm create realms -s realm=inventory -s enabled=true
kcadm get realms --fields realm,enabled
```

The first command prints that it created a new realm with the ID `inventory`. The second prints a JSON list with one object per realm, each with only the two fields you asked for. `--fields` keeps the output short; without it, `get realms` prints every setting of every realm. The list holds `master`, `inventory`, and the `demo` realm if you created it in the console.

## Creating a user with a password

A user needs two commands: one creates the account, and one sets its password. `-r inventory` makes sure the user lands in the application realm, not in `master`:

```sh
kcadm create users -r inventory -s username=alice -s enabled=true \
  -s email=alice@example.com -s emailVerified=true \
  -s firstName=Alice -s lastName=Example
kcadm set-password -r inventory --username alice --new-password alice-password
```

`create users` prints the ID of the new user, a long generated identifier. `set-password` prints nothing when it works. Without `--temporary`, the password is permanent, so Keycloak does not ask the user to change it at the first sign-in.

The email, first name and last name are not decoration. Keycloak's **user profile** sets which attributes a user must have, and by default it requires them. A user without them has a profile that is not complete. Keycloak then refuses to issue a token to that user through a direct grant, because it cannot show the page that asks for the missing data.

## Creating a client

Now create the client the application uses. `inventory-cli` is a **public client**, a client that cannot keep a secret, such as a command-line tool. It allows the password grant ("Direct access grants" in the console) so you can test the realm from a terminal. OAuth 2.1 drops the password grant, and a real application uses the authorization code flow instead. That flow is called "Standard flow" in Keycloak, and this client turns it off because it never opens a browser:

```sh
kcadm create clients -r inventory -s clientId=inventory-cli -s enabled=true \
  -s publicClient=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=true
kcadm get clients -r inventory -q clientId=inventory-cli \
  --fields id,clientId,publicClient,standardFlowEnabled,directAccessGrantsEnabled
```

`create clients` prints the generated ID of the client. `-q clientId=inventory-cli` adds a query to the `get`, so you see one client instead of every built-in client in the realm. The output shows the settings you just made. Note the `id`: `kcadm.sh` uses this generated ID, not the `clientId`, in resource paths such as `clients/<id>`.

## Proving the realm works

The realm, the user and the client exist. The proof is a token. Ask the `inventory` realm for a token for alice and decode it:

```sh
get_user_token inventory inventory-cli alice alice-password \
  | jq -r .access_token | decode_token | jq '{iss, azp, preferred_username}'
```

The output has three claims: `iss` is `http://keycloak:8080/realms/inventory`, `azp` is `inventory-cli`, and `preferred_username` is `alice`. The issuer names the application realm, not `master`. Run the same request against `master` (`get_user_token master inventory-cli alice alice-password`), and Keycloak answers with an error instead of a token, because neither the client nor the user exists in `master`.

## Updating and deleting

The last two verbs change and remove objects. `update` takes the same `-s` options as `create`, and `delete` takes the resource path. If you created the realm `demo` in the console, switch it off and then remove it:

```sh
kcadm update realms/demo -s enabled=false
kcadm get realms/demo --fields realm,enabled
kcadm delete realms/demo
```

The `get` in the middle shows `"enabled" : false`. A disabled realm still exists, but its users cannot sign in and it issues no tokens. `delete` removes the realm with everything in it: users, clients, keys and sessions. There is no undo, and `kcadm.sh` does not ask for confirmation.

You can now build a realm, a user and a client from the terminal and prove the result with a token. Every step is a command, so the same setup can run on any server. What this does not answer yet is how to keep a whole realm in a file and load it when the server starts, which is a separate tool.

## Common pitfalls

> [!WARNING]
> - **Forgetting `-r <realm>`.** Without it, `kcadm.sh` works on the realm you signed in to, which is `master`. The user or client then lands in the administration realm.
> - **Using the `clientId` in a resource path.** Paths such as `clients/<id>` need the generated `id`. Find it with `get clients -r <realm> -q clientId=<name> --fields id`.
> - **Creating a user without email, first name and last name.** The default user profile requires them, and a direct grant for that user fails until the profile is complete.
> - **Setting a password with `--temporary` for a test user.** The user then has a required action to change the password, and a direct grant fails.
> - **Deleting instead of disabling.** `delete realms/<realm>` removes every user and client in it at once. Disable first when you are not sure.

## Your mission: Create An Application Realm With kcadm.sh

You can now create a realm, a user and a client with `kcadm.sh` and prove the setup with a token. The graded lab gives you a Keycloak server with only the `master` realm, and asks you to build the `inventory` realm with alice and `inventory-cli`, with nothing for the application left in `master`.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-088-playground-020-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS088.git -c sections/section-020/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-088-lab-020-01
astrona start ats-088-playground-020-01
```
