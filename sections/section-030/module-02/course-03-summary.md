# Summary

A Keycloak server keeps realms, users and clients in a database, and the choice of database decides whether that data outlives a pod. This module moved Keycloak to PostgreSQL and showed how a realm gets into a new server from a file.

## What you learned

By default Keycloak uses `dev-file`, an embedded database stored as a file under `/opt/keycloak/data` inside the container. It needs no server, but a new pod starts with an empty file, so every realm created at runtime is lost when the pod is replaced. `dev-file` is for development only, and production mode warns that relying on it is deprecated.

Keycloak connects to PostgreSQL with `KC_DB=postgres`, `KC_DB_URL_HOST`, `KC_DB_URL_DATABASE`, `KC_DB_USERNAME` and `KC_DB_PASSWORD`, and builds the JDBC URL from the host and database. `db` is a build option and belongs in the image build of an optimized image; the host, user name and password are read at every start. The user name and password come from a Kubernetes Secret through `secretKeyRef`, so they never appear in the Deployment. On its first start against an empty database, Keycloak creates its tables, and the table `realm` in PostgreSQL then lists every realm the server holds.

`--import-realm` reads every regular `.json` file in `/opt/keycloak/data/import` at start, usually named `<realm name>-realm.json`, and a ConfigMap mounted at that folder is a simple way to deliver one. A startup import creates a realm that is missing and skips a realm that already exists, so a restart never undoes changes made since, and an edited file never reaches an existing realm. `kc.sh import` overrides existing realms by default and runs only while every server is stopped. `kc.sh export` writes realms to files with `--dir` or `--file`, `--realm` and `--users`, and must not run beside a running server. The key facts to remember are these:

- A realm that must survive a pod replacement needs an external database such as PostgreSQL.
- Read database credentials from a Secret with `secretKeyRef`, never as plain values.
- A startup import is a one-time creation, not a sync.
- The Admin Console's partial export masks secrets and leaves out users, so it is not a backup.

<!-- astrona:playground:destroy -->
