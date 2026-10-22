# Run Keycloak From The Container Image In Production Mode

A Keycloak pod that runs `start-dev` works well on the first day. It answers on plain HTTP, accepts any hostname a request uses, and needs no database server. Change the start command to `start` without anything else, and the same pod no longer starts at all. Nothing in the image changed. Only the mode changed.

Keycloak is an identity and access management server: it signs users in and issues tokens to applications. Its container image holds the server, two command-line tools and a few folders. The **mode** you start it in decides which defaults apply. Development mode (`start-dev`) turns safety checks off so you can try things quickly. Production mode (`start`) turns them on, and refuses to start until you give it the settings a real server needs.

This module is about those settings and where they come from. Keep one sentence in mind: **the image is the same in every environment, and the configuration decides how it behaves.** You learn where the configuration can come from, which settings are fixed by a build step, and what production mode checks before it starts.

The module has three parts. **Inside The Keycloak Container Image** opens the image and names each folder and tool. **Configuration Sources, Build Options And Runtime Options** shows the four places Keycloak reads options from, their order, and why some options belong in an image build. **Production Mode, The Hostname And Health Checks** switches the playground server to `start`, reads why it fails, and gives it a hostname, HTTP and health checks. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Name the folders of the Keycloak image under `/opt/keycloak` and say what each one holds.
- Explain why the image has no package manager, and how a multi-stage build adds files to it.
- List the four configuration sources in order of priority.
- Turn an option such as `db-url-host` into its environment variable `KC_DB_URL_HOST`.
- Tell a build option from a runtime option, and say what `kc.sh build` and `start --optimized` do.
- Compare `start-dev` and `start`, and list what production mode needs before it starts.
- Set the hostname as a full URL, turn on HTTP, and explain what `hostname-strict` protects.
- Turn on the health endpoints and point Kubernetes probes at the management port `9000`.

## Before you start

You need Kubernetes basics: namespaces, Deployments, Services, environment variables in a pod, and the commands `kubectl get`, `kubectl apply`, `kubectl logs` and `kubectl exec`. You also need to know that Keycloak is an identity server that issues tokens. This module does not teach realms or tokens; it teaches how to run the server.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1**, image `quay.io/keycloak/keycloak:26.8.1`. The namespace **`image-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod, started with `start-dev`, behind the Service `keycloak` on port `8080` (HTTP) and `9000` (management) |
| `tester` | A client pod with `curl` and `jq`. Every test request in this module is sent from here |

The first administrator in the `master` realm is the user `admin` with the password `admin`. These are lab-only credentials. Every command in the parts runs against the playground cluster, and `kubectl` already points at it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
