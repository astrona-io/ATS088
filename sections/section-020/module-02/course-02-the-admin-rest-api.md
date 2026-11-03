# The Admin REST API

A script must create ten realms, or an audit tool must list users every night. Nobody clicks in the Admin Console for that. The Admin REST API takes the same actions over HTTP, so any program that can send a request and read JSON can manage Keycloak. This part gets a token for the API, calls it with `curl`, and shows how `kcadm.sh` wraps the same calls.

## The shape of the API

The base address of the API is `/admin/realms`. The realm in the path is the realm being managed, not the realm of the caller. The main resources are a short list:

| Path | What it holds |
| --- | --- |
| `/admin/realms` | The list of realms |
| `/admin/realms/<realm>/users` | The users of a realm |
| `/admin/realms/<realm>/clients` | The clients of a realm |
| `/admin/realms/<realm>/roles` | The realm roles |
| `/admin/realms/<realm>/events` | The user events |

The API uses the normal HTTP methods: `GET` reads, `POST` creates, `PUT` changes and `DELETE` removes. Every request needs an access token in the `Authorization: Bearer` header. Without a valid token, Keycloak answers `401`. With a valid token that lacks the needed role, it answers `403`.

## Get an administrator token

The client `admin-cli` of the `master` realm allows the password grant, so a script can sign in as an administrator with a user name and password. This is a test shortcut; production automation uses a service account instead, which the next part shows.

<!-- astrona:playground:renew -->

```sh
NAMESPACE=adminapi-demo
get_admin_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s http://keycloak:8080/realms/master/protocol/openid-connect/token \
      -d grant_type=password -d client_id=admin-cli \
      -d username=admin -d password=admin | jq -r .access_token
}
ADMIN_TOKEN=$(get_admin_token)
echo "${#ADMIN_TOKEN} characters"
```

The command prints the length of a long string; the token itself stays in the variable. An administrator token expires after the access token lifespan of the `master` realm, 60 seconds by default, so request a new one when a call returns `401`.

## Call the API

List the realms, then the users of `inventory`. The `jq` filter keeps the output short:

```sh
kubectl -n adminapi-demo exec deploy/tester -- \
  curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
  http://keycloak:8080/admin/realms/inventory/users | jq '.[] | {id, username, enabled}'
```

The answer is a JSON list with an entry for each user, with the user `alice` among them. The `id` is a UUID. Paths that name one object use this `id`, not the user name. To find `alice` by name, add the query parameter `username=alice&exact=true`:

```sh
kubectl -n adminapi-demo exec deploy/tester -- \
  curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
  'http://keycloak:8080/admin/realms/inventory/users?username=alice&exact=true' | jq '.[0].id'
```

Create a user with a `POST` and a JSON body. The API answers `201` with an empty body and puts the address of the new user in the `Location` header:

```sh
kubectl -n adminapi-demo exec deploy/tester -- \
  curl -s -o /dev/null -w '%{http_code}\n' -X POST \
  -H "Authorization: Bearer $ADMIN_TOKEN" -H 'Content-Type: application/json' \
  -d '{"username":"bob","enabled":true}' http://keycloak:8080/admin/realms/inventory/users
```

The status is `201`. Sending the same request again returns `409`, because the user name already exists.

## kcadm.sh is the same API

`kcadm.sh` signs in once and keeps the token in its configuration file. Each of its commands maps to one call. `kcadm get users -r inventory` is `GET /admin/realms/inventory/users`, and `kcadm create users -r inventory -s username=bob` is the `POST` above. The option `-q` adds query parameters, `--fields` limits the output and `--format csv` prints values for use in scripts. When a `kcadm.sh` command fails, add `--verbose`, or repeat the call with `curl` to see the status code and body.

You now know the shape of the Admin REST API, how to get a token for it, and how `kcadm.sh` relates to it. The password grant of a full administrator is still a poor identity for a script. The open question is how to give automation a smaller identity.

## Common pitfalls

> [!WARNING]
> - **Using an old token.** A `401` after a minute means the token expired. Request a new one.
> - **Using the user name in a path.** Paths take the object `id`, a UUID. Look it up with a query first.
> - **Confusing the realm in the path with the realm of the token.** The path names the realm being managed. The token's realm decides who the caller is.
> - **Using the password grant for automation.** It stores a person's password in a script. Use a service account with a small role.
> - **Printing the token into logs.** The token is a bearer credential. Anyone who reads it can use it until it expires.
