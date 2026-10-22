# Inside The Keycloak Container Image

When Keycloak misbehaves in a pod, you need to know where things are inside the container. Where is the start script? Where would a configuration file go? Where does the server keep its data when no database is set? This part opens the running image and names each folder, so the rest of the module can talk about them without guessing.

## One image, one folder

Every file Keycloak needs lives under one folder in the image: `/opt/keycloak`. The image's entrypoint is the start script `/opt/keycloak/bin/kc.sh`. The entrypoint is the program a container runs when it starts. Because of that, the `args` of the container in a Deployment are the arguments of `kc.sh`, for example `start-dev`.

Look at the arguments of the playground pod first. They show the command that the entrypoint received:

<!-- astrona:playground:renew -->

```sh
kubectl -n image-demo get deployment keycloak \
  -o jsonpath='{.spec.template.spec.containers[0].args}{"\n"}'
```

The result is a list with one entry, `start-dev`. So the container runs `/opt/keycloak/bin/kc.sh start-dev`, which starts Keycloak in development mode.

Now list the folder itself:

```sh
kubectl -n image-demo exec deploy/keycloak -- ls /opt/keycloak
```

The list holds the folders `bin`, `conf`, `data`, `lib`, `providers` and `themes`, plus a few license and version files. Each folder has one job:

| Folder | What it holds |
| --- | --- |
| `bin/` | `kc.sh`, the server command (`start`, `start-dev`, `build`, `export`, `import`), and `kcadm.sh`, the administration command-line tool |
| `conf/` | `keycloak.conf`, the configuration file, and other configuration files you add |
| `data/` | Files the server writes while it runs: the `dev-file` database, logs written to a file, and `import/`, the folder read by `--import-realm` |
| `lib/` | The server itself: Java libraries built on the Quarkus framework. You never change this folder |
| `providers/` | Extra Java archive (JAR) files that extend Keycloak, for example a custom authenticator |
| `themes/` | Extra themes that change the look of the login pages and consoles |

## The two tools in `bin/`

The `bin/` folder holds two tools that are easy to mix up. `kc.sh` runs the **server** process. You give it a command such as `start` and options such as `--hostname`, and it starts or builds Keycloak. `kcadm.sh` is a **client**. It sends requests to the Admin REST API of a server that is already running, to create realms, users and clients.

List the folder to see both tools:

```sh
kubectl -n image-demo exec deploy/keycloak -- ls /opt/keycloak/bin
```

You see `kc.sh` and `kcadm.sh`, and Windows versions of both ending in `.bat`. You may also see a `client` folder that `kcadm.sh` uses. The rule to keep is simple: `kc.sh` decides how the server runs, and `kcadm.sh` changes what is stored inside the running server.

## A small image with no package manager

The image holds little more than Keycloak, a Java runtime and the `bash` shell. It has no package manager: no `microdnf`, no `dnf` and no `rpm`. The Keycloak project removed them on purpose. Fewer programs in the image mean fewer programs an attacker can use, and fewer packages that need security updates.

You can check this yourself:

```sh
kubectl -n image-demo exec deploy/keycloak -- sh -c 'command -v microdnf dnf rpm || echo "no package manager"'
```

The command prints `no package manager`, because none of the three programs exists. If an extension needs an extra system package, you install it in a separate build stage, for example one based on `registry.access.redhat.com/ubi9`, and copy only the files you need into the Keycloak image. That is a multi-stage build: a container build with more than one `FROM` line, where a later stage copies files out of an earlier one.

The container also does not run as the root user. Check which user runs the server:

```sh
kubectl -n image-demo exec deploy/keycloak -- id
```

The user is not `root` (user ID `0`). Keycloak runs as an ordinary user that owns `/opt/keycloak`. This matters when you mount files into the container. A file that only `root` can read is invisible to the server.

You now know where every part of Keycloak lives in the image and which of the two tools does what. You also know that you cannot install tools into a running Keycloak container. The open question is how the server gets its settings, because nothing in the folder list says "production" or "database".

## Common pitfalls

> [!WARNING]
> - **Putting a command in `command` instead of `args`.** The entrypoint is already `kc.sh`. Setting `command: ["start"]` replaces the entrypoint and the container fails to start. Put `start` or `start-dev` in `args`.
> - **Using `kcadm.sh` to change how the server runs.** `kcadm.sh` changes realms, users and clients. The hostname, the database and the mode come from `kc.sh` options.
> - **Trying to install a package in the running container.** There is no package manager. Build a new image with a multi-stage build instead.
> - **Mounting files only `root` can read.** Keycloak does not run as `root`, so it cannot read them.
