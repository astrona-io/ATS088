# Summary

Keycloak has two web interfaces and one programming interface. The Admin Console, at `/admin/<realm>/console/`, is for administrators. The Account Console, at `/realms/<realm>/account`, is for the users of one realm. Both are public clients of Keycloak and both call HTTP interfaces with an access token.

The Admin REST API, under `/admin/realms`, is the interface that every change goes through, including the changes made by the Admin Console and by `kcadm.sh`. A caller sends a bearer token. A missing or expired token gets status `401`. A valid token without the needed role gets status `403`. Paths that name one object use its `id`, not its name.

The roles of the client `realm-management` control the API. `view-users` reads users, `manage-users` also changes them, and `realm-admin` allows everything in the realm. A script gets its own identity through a confidential client with a service account, and it receives only the roles it needs. Keycloak copies the roles into a token when it issues the token, so a role change needs a new token.

User events and admin events give an audit trail. User events record sign-ins and related actions, and admin events record changes made through the API. Both are off by default, both are read through the API or `kcadm.sh`, and both need the role `view-events`.

Key facts:

- The clients `security-admin-console`, `account-console` and `admin-cli` exist in every realm.
- The `master` administrator can manage every realm.
- Service account users are named `service-account-<clientId>`.
- `eventsEnabled` and `adminEventsEnabled` are realm settings.

<!-- astrona:playground:destroy -->
