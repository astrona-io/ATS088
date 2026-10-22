# Summary

The same Keycloak container image runs a test server and a production server. This module showed what is inside the image, where the server reads its settings, and what production mode needs before it starts.

## What you learned

Everything Keycloak needs lives under `/opt/keycloak`. The entrypoint is `bin/kc.sh`, so the `args` of the container are the arguments of `kc.sh`, such as `start` or `start-dev`. `bin/kcadm.sh` is a separate client that changes realms, users and clients through the Admin REST API; it does not change how the server runs. The folders `conf/`, `data/`, `providers/` and `themes/` hold the configuration file, runtime data, extensions and themes. The image has no package manager and does not run as `root`, so extra tools come in through a multi-stage build, and mounted files must be readable by an ordinary user.

Keycloak reads each option from four sources. A command-line option wins over an environment variable, which wins over `conf/keycloak.conf`, which wins over a KeyStore. An option such as `db-url-host` is `--db-url-host` on the command line and `KC_DB_URL_HOST` in the environment, and `KCRAW_` keeps a value with a `$` sign exactly as written. Build options such as `db` and `health-enabled` are fixed by `kc.sh build`; runtime options such as `hostname` are read at every start. An optimized image runs `kc.sh build` in a build stage and starts with `start --optimized`, and keeps every secret out of the build.

Production mode (`start`) is secure by default. It turns HTTP off, requires TLS or an explicit `http-enabled=true`, and requires a hostname or `hostname-strict=false`. Without them, the process exits during startup and the reason is in `kubectl logs`, not in the probes. A hostname given as a full URL fixes the issuer of every token. With `hostname-strict` at `true`, a request's `Host` header cannot change that issuer, which is what stops a client from putting its own hostname into tokens and links. The key facts to remember are these:

- `start-dev` is for development only; never fix a production start by going back to it.
- `KC_HOSTNAME=http://keycloak:8080` and `KC_HTTP_ENABLED=true` make the playground's production server start without TLS.
- The health endpoints `/health/started`, `/health/live` and `/health/ready` live on the management port `9000`, and only when `health-enabled` is `true`.
- With health and metrics off, port `9000` is closed and every probe fails.

<!-- astrona:playground:destroy -->
