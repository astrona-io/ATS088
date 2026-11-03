# User Events And Admin Events

Something changed in a realm last night: a client has a new redirect URI, and a user locked out three times. Without a record, nobody can say who did what or when. Keycloak can record two kinds of events, and this part turns both on and reads them back, so you can answer those questions from the API.

## Two kinds of events

**User events** record what happens when users and clients sign in: `LOGIN`, `LOGIN_ERROR`, `LOGOUT`, `REGISTER`, `UPDATE_PASSWORD`, `CODE_TO_TOKEN` and others. Each event has a type, a time, the realm, the client, the user and an IP address. **Admin events** record changes made through the Admin REST API: the operation type (`CREATE`, `UPDATE`, `DELETE`, `ACTION`), the resource type (`USER`, `CLIENT`, `REALM_ROLE_MAPPING` and others), the resource path and the identity that made the change.

Both are off by default in a new realm and need to be turned on per realm. Keycloak keeps them in its database. User events can expire; admin events are kept until you delete them.

<!-- astrona:playground:renew -->

## Turn the events on

Sign in with `kcadm.sh`, and read the current event settings of the realm `inventory`:

```sh
NAMESPACE=adminapi-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get events/config -r inventory
```

The answer is a JSON object with `eventsEnabled` and `adminEventsEnabled` set to `false`, the list `eventsListeners` that holds `jboss-logging`, and the other event settings. Turn both kinds on, keep the details of admin events, and let user events expire after one day:

```sh
kcadm update events/config -r inventory \
  -s eventsEnabled=true -s eventsExpiration=86400 \
  -s adminEventsEnabled=true -s adminEventsDetailsEnabled=true
```

In the Admin Console the settings are on **Realm settings** in the **Events** tab. The option `adminEventsDetailsEnabled` makes Keycloak store the JSON representation of the changed object too, which is useful for audits and may include sensitive values, so turn it on only when you need it.

## Generate events and read them

Create a failed sign-in and a successful one for `alice` with the password grant through `inventory-cli`. The password grant is used here only so a terminal can sign a user in:

```sh
for password in wrong-password alice-password; do
  kubectl -n adminapi-demo exec deploy/tester -- \
    curl -s -o /dev/null -w '%{http_code}\n' \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli \
    -d username=alice -d password="$password"
done
```

The first status is `401`, and the second is `200`. Read the events of type `LOGIN_ERROR`:

```sh
kcadm get events -r inventory -q type=LOGIN_ERROR --fields type,clientId,userId,error
```

The list has an event for the wrong password, with the client `inventory-cli` and the error `invalid_user_credentials`. Change something as the administrator and read the admin events:

```sh
kcadm create users -r inventory -s username=carol -s enabled=true
kcadm get admin-events -r inventory --fields operationType,resourceType,resourcePath
```

One event has the operation type `CREATE` and the resource type `USER`, with the path of the new user. The same data is available at `GET /admin/realms/inventory/events` and `GET /admin/realms/inventory/admin-events`, and a caller needs the role `view-events` for both.

## Events in the server log

The listener `jboss-logging` writes every event as a line to the server log, at the level `debug` for successful events and `warn` for errors. With the default log level, an operator sees the warnings in `kubectl logs`, for example failed sign-ins. A log collector can keep these lines longer than the database does.

You now know what user events and admin events record, how to turn them on, and how to read them. Together with the administration roles, they let an administrator limit what a tool can do and check what it did.

## Common pitfalls

> [!WARNING]
> - **Assuming events are on.** A new realm records nothing until the settings are turned on.
> - **Keeping details of admin events everywhere.** The stored representation can contain secrets. Turn it on only when needed.
> - **Never expiring user events.** The table grows without limit. Set `eventsExpiration`.
> - **Searching by user name.** Events store the user `id`. Look up the id first.
> - **Using events as a security alarm.** Keycloak records events but does not alert. A separate tool must watch the log or the API.
