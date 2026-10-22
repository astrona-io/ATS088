# Get Tokens From Keycloak With OAuth 2.0 And OpenID Connect — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-088-playground-010-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single sandbox environment that spins up, deploys Keycloak 26.8.1 in the
namespace `protocols-demo`, creates the realm `inventory`, and stays running
so you can explore the module's topic. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-088-playground-010-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-088-playground-010-01`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Deploys Keycloak and creates the realm, user and clients |
| `manifests/lab-start.yaml` | Namespace, Keycloak, Service and tester pod |
| `docs/overview.md` | What the environment contains and ideas to try |
