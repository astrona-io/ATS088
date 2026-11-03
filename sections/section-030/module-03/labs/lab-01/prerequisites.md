# Prerequisites

Before starting this lab you should be able to:

- Edit a Deployment: add environment variables, a Secret volume and a container port.
- Create and use a Kubernetes Secret of type `kubernetes.io/tls`.
- Read the discovery document of a realm with `curl` and `jq`.
- Explain what TLS termination at a reverse proxy means.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Keycloak 26.8.1** in the namespace **`edge-demo`**, started with `start` (production mode), HTTP on and the hostname `https://id.example.test`. It sits behind the Service `keycloak` on port `8080` and `9000`.
- The TLS Secret `keycloak-tls`, with the keys `tls.crt` and `tls.key`. The self-signed certificate names `keycloak`, `keycloak.edge-demo.svc` and `id.example.test`.
- A `tester` pod with `curl`, `jq` and `openssl`.
- The administrator of the `master` realm is `admin` with the password `admin` (lab-only credentials).

## Working rules

- Everything is graded on the **final state** of the Deployment, the Service and the running server, so wait until the new pod is ready and test again.
- Keycloak takes a few minutes to start. Read `kubectl -n edge-demo logs deploy/keycloak` when the pod does not become ready.
- Keep `KC_HTTP_MANAGEMENT_SCHEME` as it is, so the health probes keep working.
