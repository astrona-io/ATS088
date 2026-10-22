# Separate Administration From Applications With Realms — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-088-playground-020-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single sandbox environment with Keycloak 26.8.1 in development mode in the
namespace `realms-demo`. Only the `master` realm exists; the reader creates the
application realm, its user and its client while reading the module.

Not yet run: this playground was written from the Keycloak documentation and
has not been started on a cluster.

## Run it

```sh
astrona run -c .
astrona destroy ats-088-playground-020-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-088-playground-020-01`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Environment preparation run once at startup |
| `manifests/lab-start.yaml` | Keycloak, its admin Secret, and the tester pod |
| `docs/overview.md` | What the environment contains and ideas to try |
