# Store Keycloak Data In PostgreSQL And Import A Realm

Create a realm in a Keycloak pod that runs with its default settings, delete the pod, and the realm is gone. Keycloak did nothing wrong. By default it keeps every realm, user and client in `dev-file`, a small database stored as a file inside the container, and a new pod starts with an empty container.

A real Keycloak keeps its data in an external database server, so the data outlives every pod. A database server is a separate program that stores data on its own disk and answers queries over the network. This module moves Keycloak from `dev-file` to PostgreSQL, a widely used open-source database server, and reads the database password from a Kubernetes Secret instead of writing it into the Deployment.

The second half of the module is about getting a realm into a new server. Keep one sentence in mind: **`--import-realm` creates a realm from a file once, and never updates it afterwards.** You import the `inventory` realm from a ConfigMap when the server starts, and you export a realm back to a file.

The module has two parts. **From dev-file To PostgreSQL** shows the data loss, explains the database options and their environment variables, and proves that the data now lives in PostgreSQL. **Importing And Exporting A Realm** mounts a realm file into the import folder, shows what happens when the realm already exists, and exports a realm with `kc.sh export`. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Explain why `dev-file` loses data when its pod is replaced, and why it is for development only.
- Set `KC_DB`, `KC_DB_URL_HOST`, `KC_DB_URL_DATABASE`, `KC_DB_USERNAME` and `KC_DB_PASSWORD` for PostgreSQL.
- Read the database user name and password from a Kubernetes Secret with `secretKeyRef`.
- Prove from PostgreSQL itself that Keycloak stores its realms there.
- Import a realm at start from a ConfigMap mounted at `/opt/keycloak/data/import` with `--import-realm`.
- Explain why a startup import skips a realm that already exists.
- Export a realm with `kc.sh export`, and say why the server must not run at the same time.

## Before you start

You need Kubernetes basics: Deployments, Services, Secrets, ConfigMaps, volumes, and the commands `kubectl apply`, `kubectl exec`, `kubectl logs` and `kubectl scale`. You also need to know that Keycloak stores realms, users and clients, and that a client can ask a realm for a token.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1**. The namespace **`database-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod in development mode (`start-dev`), on the `dev-file` database. Service ports `8080` (HTTP) and `9000` (management) |
| `postgres` | PostgreSQL 17 with an empty database `keycloak`, on port `5432`. Keycloak does not use it yet |
| `tester` | A client pod with `curl` and `jq`. Every test request in this module is sent from here |

The Secret `keycloak-admin` holds the first administrator (`admin` / `admin`), and the Secret `keycloak-db` holds the database user `keycloak` and its password under the keys `username` and `password`. The ConfigMap `inventory-realm` holds a realm file for the realm `inventory`, with the user `alice` and the client `inventory-cli`. All of these are lab-only credentials. PostgreSQL keeps its data in an `emptyDir` volume, so it survives Keycloak restarts but not the deletion of the `postgres` pod.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
