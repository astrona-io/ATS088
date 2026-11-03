# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** Administration

## Scenario

An audit tool must list the users of the realm `inventory` through the Admin REST API, and it must never change them. A colleague created the client `inventory-auditor` for it, with a service account and the client secret `inventory-auditor-secret`. The tool gets a token from the realm `inventory`, but every call to the user list is refused.

## Your task

In the realm `inventory` and the namespace `adminapi-demo`:

1. Request a token for `inventory-auditor` with the client credentials grant and call `GET /admin/realms/inventory/users` from the `tester` pod. Read the status code.
2. Give the service account of `inventory-auditor` the administration role it needs to list users, and nothing more.
3. Prove that the list call now succeeds and that creating a user with `POST /admin/realms/inventory/users` is still refused.

## Constraints

- Use only the client role `view-users` of the client `realm-management`. Do not assign `manage-users`, `realm-admin` or any other management role.
- Do not change the client secret or the other settings of `inventory-auditor`.
- Do not create or delete users.

## Done when

- A token for `inventory-auditor` gets status `200` from `GET /admin/realms/inventory/users`.
- A token for `inventory-auditor` gets status `403` from `POST /admin/realms/inventory/users`.
- The service account holds `view-users` and holds neither `manage-users` nor `realm-admin`.
