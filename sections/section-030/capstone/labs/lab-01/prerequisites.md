# Prerequisites

Before starting this capstone you should be able to:

- Read pods, logs, events and probe failures with `kubectl get`, `kubectl logs` and `kubectl describe`.
- Write a Deployment with environment variables from a Secret and a ConfigMap mounted as a volume.
- Request a token from a Keycloak realm with `curl` and decode its claims with `jq`.

## What the environment gives you

The capstone environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Keycloak 26.8.1** in the namespace **`runcapstone-demo`**, prepared as the task describes, behind the Service `keycloak` on ports `8080` and `9000`.
- **PostgreSQL 17** behind the Service `postgres` on port `5432`, with the database `keycloak`.
- A `tester` pod with `curl` and `jq`.
- The Secrets `keycloak-admin` (`admin` / `admin`) and `keycloak-db`, and the ConfigMap `inventory-realm`. All credentials are lab-only.

Nothing the task asks you to create has been created for you.

## Working rules

- Everything is graded on the **final cluster state**, so check the result at
  the end and leave the fix in place.
- The faults are independent. Fixing one does not reveal the next, so check
  every item of the task, not only the first error you see.
- `kubectl`, `curl`, `jq` and `psql` (in the `postgres` pod) are available. No
  internet access is needed once the environment is up.
