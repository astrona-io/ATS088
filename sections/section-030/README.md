# Section 030: Running Keycloak From The Container Image

Keycloak ships as one container image, `quay.io/keycloak/keycloak`, and the same image runs a laptop test server and a production cluster. What changes between the two is configuration: the start command, the hostname, HTTP or HTTPS, the database and the health checks. A wrong value does not always fail loudly. A server can start, accept logins and lose every realm the next time its pod restarts.

This section teaches you to run the image on purpose. You look inside the image, learn where Keycloak reads its options from and in which order, and see why some options are fixed by a build step while others are read at every start. Then you move Keycloak from development mode to production mode, and from the built-in `dev-file` database to PostgreSQL, and you import a realm from a file when the server starts.

**Topic covered:** Running Keycloak

## What you will learn

- The layout of the Keycloak container image: `kc.sh`, `kcadm.sh`, `conf/keycloak.conf`, `providers/`, `themes/` and `data/`.
- Why the image has no package manager, and how to add tools with a multi-stage build.
- The four configuration sources and their order, and how an option name becomes a `KC_` environment variable.
- Build options against runtime options, and what `kc.sh build` and `start --optimized` do.
- The difference between `start-dev` and `start`, and what production mode needs before it starts: a hostname, and TLS or explicit HTTP.
- The health endpoints on the management port `9000`, and how Kubernetes probes use them.
- Why `dev-file` loses data, and how to point Keycloak at PostgreSQL with the password read from a Kubernetes Secret.
- Importing a realm at start with `--import-realm`, what happens when the realm already exists, and exporting a realm with `kc.sh export`.

## The learning path

Work through the modules in order. Each module has a landing page, a few short parts, a graded lab right after the part it tests, and a summary. Each module also has its own playground, a cluster where you can explore freely, and the landing page of each module starts it for you.

### 1. Run Keycloak From The Container Image In Production Mode

The module starts at its landing page, which also launches the playground. The playground holds the namespace `image-demo` with one Keycloak pod in development mode and a `tester` pod.

1. Inside The Keycloak Container Image
2. Configuration Sources, Build Options And Runtime Options
3. Production Mode, The Hostname And Health Checks, followed by the lab **Start Keycloak In Production Mode**
4. Summary

### 2. Store Keycloak Data In PostgreSQL And Import A Realm

The module starts at its landing page, which also launches the playground. The playground holds the namespace `database-demo` with Keycloak on the `dev-file` database, a PostgreSQL 17 server that Keycloak does not use yet, and a ConfigMap that holds a realm file.

1. From dev-file To PostgreSQL
2. Importing And Exporting A Realm, followed by the lab **Move Keycloak To PostgreSQL With An Imported Realm**
3. Summary

## Section capstone: Run A Production Keycloak On PostgreSQL

The capstone is one graded scenario that combines both modules. The namespace `runcapstone-demo` holds a Keycloak Deployment that someone copied from a laptop test. It runs in development mode, keeps its data in `dev-file`, never becomes ready, and does not load the realm the application needs. Several faults are independent, so fixing one does not reveal the next. Work it after the module labs.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS088.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-088-capstone-030
```
