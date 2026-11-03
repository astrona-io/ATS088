# Administer Keycloak With The Consoles And The Admin REST API

A Keycloak server has two web interfaces and one programming interface, and mixing them up leads to wrong sign-ins and to administration tools with far too much power. An administrator uses the Admin Console, a user manages their own account in the Account Console, and automation uses the Admin REST API. Every one of them is served by the same server, and each needs its own kind of permission.

Keycloak is an identity and access management server that signs users in and issues tokens. The Admin Console is its web interface for administrators. The Account Console is the web interface where a user manages their own profile, password and sessions. The Admin REST API is the HTTP interface that both consoles and the `kcadm.sh` tool call. A realm is a space in Keycloak that holds its own users, clients, roles and settings.

Keep one sentence in mind: **the Admin REST API is the only way to change Keycloak, and a caller may do only what the administration roles in its token allow.** This module shows the three interfaces, calls the API with `curl`, gives a service account exactly one role, and reads the events Keycloak records about what happened.

The module has four parts. **The Admin Console And The Account Console** names the addresses and the client behind each one. **The Admin REST API** gets an administrator token and calls the API. **Administration Roles And Least Privilege** explains the `realm-management` roles and gives a service account one of them; a graded lab follows it. **User Events And Admin Events** turns on the audit trail and reads it.

## Learning objectives

After this module you can:

- Give the addresses of the Admin Console and the Account Console of a realm.
- Name the clients `security-admin-console`, `admin-cli` and `account-console`.
- Get an access token for the Admin REST API and call it with `curl`.
- Explain the difference between HTTP `401` and HTTP `403` from the API.
- List the `realm-management` roles and say what `view-users`, `manage-users` and `realm-admin` allow.
- Assign a client role to a service account with `kcadm.sh add-roles`.
- Turn on user events and admin events and read them through the API.

## Before you start

You need Kubernetes basics: namespaces, Deployments, Services and the commands `kubectl get` and `kubectl exec`. You need to know what an HTTP method and a status code are. You do not need to know the Admin REST API; this module teaches it.

Your playground is a single-node `kind` cluster. The namespace **`adminapi-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak 26.8.1 pod in development mode, behind the Service `keycloak` on port `8080` |
| `tester` | A client pod with `curl` and `jq`. Every test request in this module is sent from here |

Inside Keycloak, the realm **`inventory`** holds the user `alice` (password `alice-password`), the confidential client `inventory-auditor` with a service account and the client secret `inventory-auditor-secret`, and the public client `inventory-cli`. The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials; never use them on a real server.

Every command in the parts runs against the playground cluster, and `kubectl` already points at it. Keycloak takes a few minutes to start the first time, so start the playground now.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
