# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Running Keycloak

## Scenario

The team runs Keycloak in the namespace `database-demo` for an inventory application. Twice this week the Keycloak pod was replaced, and both times every realm someone had built by hand was gone. A PostgreSQL server already runs in the namespace, and someone saved the application's realm as a file in a ConfigMap. Neither is used.

## Your task

In the namespace `database-demo`:

1. Make Keycloak store its data in PostgreSQL. Configure it with **environment variables** on the `keycloak` container: the vendor `postgres`, the host `postgres` and the database `keycloak`. Read the user name and the password from the Secret `keycloak-db` (keys `username` and `password`).
2. Make Keycloak create the realm `inventory` from the ConfigMap `inventory-realm` when it starts.
3. Prove the result: PostgreSQL lists the realms `master` and `inventory`, and the user `alice` (password `alice-password`) gets a token from the `inventory` realm through the client `inventory-cli` from the `tester` pod.

## Constraints

- **No password in the Deployment.** `KC_DB_USERNAME` and `KC_DB_PASSWORD` must use `secretKeyRef` to the Secret `keycloak-db`. Do not write the password as a plain `value` or as `--db-password`.
- **Import the realm from the file.** Mount the ConfigMap `inventory-realm` at `/opt/keycloak/data/import` and start Keycloak with `--import-realm`. Do not create the realm with the Admin Console or `kcadm.sh`.
- Do not change the Secrets, the ConfigMap, the `postgres` Deployment or the `tester` pod.
- Keycloak may stay in development mode (`start-dev`) for this task.

## Done when

- `KC_DB` is `postgres`, `KC_DB_URL_HOST` is `postgres`, `KC_DB_URL_DATABASE` is `keycloak`, and the user name and password come from the Secret `keycloak-db`.
- The ConfigMap `inventory-realm` is mounted at `/opt/keycloak/data/import`, and Keycloak starts with `--import-realm`.
- `select name from realm;` in the PostgreSQL database `keycloak` lists `master` and `inventory`.
- A token request for `alice` returns an access token whose issuer is `http://keycloak:8080/realms/inventory` and whose `preferred_username` is `alice`.
