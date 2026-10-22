---
estimated_duration: 20m
---

# Start Keycloak In Production Mode

- **ID:** LAB
- **Slug:** ats-088-lab-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab
- **Status:** built from the Keycloak 26.8.1 documentation, not yet run with `astrona test`

Graded lab for the namespace `image-demo`. Read `question.md` for the task; `solution.md` is the walkthrough.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-088-lab-030-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-088-lab-030-01`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | Environment preparation run once at startup |
| `manifests/` | Starting state applied by the bootstrap |
| `solution/` | Reference solution used by `astrona test` |
| `testing/` | Helpers `astrona test` runs before the reference solution |
| `validation/` | Grading scripts, one per check |
