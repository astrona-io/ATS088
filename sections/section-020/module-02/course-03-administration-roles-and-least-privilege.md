# Administration Roles And Least Privilege

A tool that only reads users does not need the power to delete a realm. Yet the quick way to make an API call work is to give the caller a full administrator. Keycloak has fine-grained administration roles so that each caller gets only what it needs. This part shows where the roles live, what the main ones allow, and how to give a service account a single role.

## The realm-management client

Every realm has a client named `realm-management`. Nobody signs in with it. It exists to hold **client roles**: named permissions that belong to a client. The roles of `realm-management` control the Admin REST API for that realm. A caller that holds `view-users` may read users, and a caller that holds `manage-users` may also create, change and delete them.

<!-- astrona:playground:renew -->

List the roles with `kcadm.sh`:

```sh
NAMESPACE=adminapi-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get-roles -r inventory --cclientid realm-management --fields name
```

The roles include these, in pairs of view and manage:

| Role | What it allows |
| --- | --- |
| `view-users` | Read users and groups |
| `manage-users` | Create, change and delete users |
| `view-clients` | Read clients |
| `manage-clients` | Create, change and delete clients |
| `view-realm` | Read the realm settings |
| `manage-realm` | Change the realm settings |
| `view-events` and `manage-events` | Read the events / change the event settings |
| `realm-admin` | Everything in the realm; a composite role that contains all the others |

A **composite role** is a role that contains other roles; whoever holds it holds all of them.

## Why a service account

A script has no person behind it, so it should not use a person's account. A confidential client with **service accounts** on gets a service account user named `service-account-<clientId>`. You assign roles to that user, and the script signs in with the client credentials grant. The steps are the same for every tool: create a confidential client, turn on the service account, assign the smallest set of roles, and store the client secret in a Kubernetes Secret.

## Assign one role and watch the status change

The client `inventory-auditor` already has a service account and no administration roles. First call the API with its token. The helper `call_users` requests a token and prints the status of a call; the second argument is the HTTP method:

```sh
call_users() {
  TOKEN=$(kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=client_credentials -d client_id=inventory-auditor \
      -d client_secret=inventory-auditor-secret | jq -r .access_token)
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s -o /dev/null -w '%{http_code}\n' -X "$1" \
    -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
    ${2:+-d "$2"} http://keycloak:8080/admin/realms/inventory/users
}
call_users GET
```

The status is `403`. The token is valid, so Keycloak knows who calls, but the caller has no role. Now assign `view-users` to the service account and repeat:

```sh
kcadm add-roles -r inventory --uusername service-account-inventory-auditor \
  --cclientid realm-management --rolename view-users
call_users GET
```

The status is now `200`. The helper requested a fresh token, which matters: Keycloak copies the roles into a token when it issues it, so an old token keeps its old roles until it expires. Finally try to change something:

```sh
call_users POST '{"username":"probe-user"}'
```

The status is `403`. `view-users` allows reading only. Check what the service account holds:

```sh
kcadm get-roles -r inventory --uusername service-account-inventory-auditor --cclientid realm-management
```

The list names `view-users`. If you ever see `realm-admin` for a tool that only reads, remove it with `kcadm remove-roles` and assign the smaller role.

## Where the roles appear in a token

Decode the access token of the service account and look at the claim `resource_access`. It has an entry `realm-management` with a list `roles`. The API reads this list on every call, and that is why a changed role needs a new token. The Admin Console shows the same data on the client's **Service accounts roles** tab.

You now know that the `realm-management` roles control the Admin REST API, how to give a service account one role, and how to prove the limit with a `403`. The open question is how an administrator learns what has been done with these powers, which is the audit trail in the next part.

## Common pitfalls

> [!WARNING]
> - **Giving `realm-admin` to make it work.** It allows everything in the realm. Start with the smallest `view-` role.
> - **Testing with an old token.** The roles in a token do not change until a new token is issued.
> - **Reading `403` as a wrong secret.** A wrong client secret fails at the token endpoint. A `403` at the API means a missing role.
> - **Assigning the role to the client.** The role goes to the service account user, `service-account-<clientId>`.
> - **Using a realm role by mistake.** The administration roles are client roles of `realm-management`, so the command needs `--cclientid realm-management`.

## Your mission: Give An Auditor Read-Only Access To Users

You can now read the administration roles of a realm and give a service account exactly one of them. The graded lab gives you an audit client that cannot list users, and asks you to let it list users through the Admin REST API without letting it create them.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-088-playground-020-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS088.git -c sections/section-020/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-088-lab-020-02
astrona start ats-088-playground-020-02
```
