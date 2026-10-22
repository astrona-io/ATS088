# Prerequisites

Before starting this lab you should be able to:

- Use `kubectl` to read pods, logs and events, and to apply a Deployment from a file.
- Read the `args` and `env` lists of a container in a Deployment.
- Send a test request from one pod to another with `curl`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Keycloak 26.8.1** (image `quay.io/keycloak/keycloak:26.8.1`) in the namespace **`image-demo`**, prepared as the task describes, behind the Service `keycloak` on ports `8080` and `9000`.
- A `tester` pod with `curl` and `jq`.
- The Secret `keycloak-admin` with the lab-only administrator `admin` / `admin`.

Nothing the task asks you to create has been created for you.

## Working rules

- Everything is graded on the **final cluster state**, so check the result at
  the end and leave the fix in place.
- Change one thing at a time and check again. Keycloak takes a minute or two
  to start, so wait for the rollout before you judge a change.
- `kubectl`, `curl` and `jq` are available. No internet access is needed once
  the environment is up.
