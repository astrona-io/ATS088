# Store Keycloak Data In PostgreSQL And Import A Realm — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-088-playground-030-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading
- **Status:** built from the Keycloak 26.8.1 documentation, not yet started with `astrona run`

A single sandbox environment that spins up, prepares the namespace `database-demo`,
and stays running so you can explore the module's topic. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-088-playground-030-02
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-088-playground-030-02`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Environment preparation run once at startup |
| `manifests/` | Starting workloads |
| `docs/overview.md` | What the environment contains and ideas to try |
