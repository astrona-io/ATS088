# Prerequisites

Before starting this lab you should be able to:

- Use `kubectl` to read pods, logs, Secrets and ConfigMaps, and to apply a Deployment from a file.
- Add environment variables from a Secret with `secretKeyRef`, and mount a ConfigMap as a volume.
- Send a test request from one pod to another with `curl`, and read JSON with `jq`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Keycloak 26.8.1** in the namespace **`database-demo`**, prepared as the task describes, behind the Service `keycloak` on ports `8080` and `9000`.
- **PostgreSQL 17** behind the Service `postgres` on port `5432`, with the database `keycloak`.
- A `tester` pod with `curl` and `jq`.
- The Secrets `keycloak-admin` and `keycloak-db`, and the ConfigMap `inventory-realm`. All credentials are lab-only.

Nothing the task asks you to create has been created for you.

## Working rules

- Everything is graded on the **final cluster state**, so check the result at
  the end and leave the fix in place.
- Change one thing at a time and check again. Keycloak takes a minute or two
  to start, so wait for the rollout before you judge a change.
- `kubectl`, `curl`, `jq` and `psql` (in the `postgres` pod) are available. No
  internet access is needed once the environment is up.
