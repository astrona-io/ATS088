# Separate Administration From Applications With Realms

A new Keycloak server has exactly one realm, `master`, and one user in it, the administrator. You can create a client in `master`, add a user, and get a token in five minutes. It works, and it is the most common setup mistake people make with Keycloak.

A **realm** is a space in Keycloak that holds its own users, clients, roles, groups and settings. Realms do not see each other: a user in one realm cannot sign in to a client in another. A **client** is an application or service that asks Keycloak to sign users in or to issue tokens. The `master` realm is special, because its administrators can manage every realm on the server.

This module is about keeping those two jobs apart. Keep one sentence in mind: **`master` is for the people who run Keycloak, and an application realm is for the application and its users.** You will see why that matters, what a realm holds, and how to build an application realm from the terminal.

The module has three parts. **The Master Realm And The Bootstrap Administrator** explains how `master` and its first user come to exist, and what is wrong with putting an application there. **What A Realm Holds, And Its URLs** goes through the objects inside a realm and the URLs each realm publishes, including the issuer that every token carries. **Managing Realms With kcadm.sh** uses Keycloak's administration command-line tool to create a realm, a user and a client, and ends with a graded lab.

## Learning objectives

After this module you can:

- Explain what the `master` realm is for and why an application's clients and users do not belong in it.
- Describe how the bootstrap administrator is created and why Keycloak marks it as temporary.
- List what a realm holds: users, credentials, clients, roles, groups, realm settings and keys.
- Name the URLs a realm publishes and read the realm from the issuer of a token.
- Sign `kcadm.sh` in to the `master` realm and create a realm, a user with a password, and a client.
- Read, update and delete Keycloak objects with `kcadm.sh get`, `update` and `delete`.
- Prove a realm works with a token whose issuer names that realm.

## Before you start

You need Kubernetes basics: namespaces, Deployments, Services, Secrets, and the commands `kubectl get`, `kubectl exec` and `kubectl port-forward`. You should know that OpenID Connect (OIDC) lets an application get tokens from an identity provider. This module does not teach the protocols; it teaches where the objects that use them live.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`realms-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod behind the Service `keycloak` on port `8080`. Health checks answer on port `9000` |
| `tester` | A client pod with `curl` and `jq`. Every token request in this module is sent from here |

Keycloak holds only the `master` realm and its administrator. The administrator's user name is `admin` and the password is `admin`, set from the Secret `keycloak-admin`. These are lab-only credentials; never use them on a real server. Every command in the parts runs against the playground cluster, and `kubectl` already points at it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
