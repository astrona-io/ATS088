# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS088 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Fundamentals & Getting Started** domain of the
  **Keycloak** training path (`ATP018`). It is 10% of the path. There is no
  official Keycloak certification exam; the path's domains and weights are
  Astrona's own, set in `ATP018/path.yaml`.
- **What the domain really tests:** running Keycloak and talking to it, not
  remembering words. The student must *do* things (start Keycloak in the right
  mode, read a discovery document, request a token and decode it, create a
  realm with `kcadm.sh`, point Keycloak at PostgreSQL, import a realm). Every
  explanation should lead to a command they can run, and every fix should be
  proved with a real token request that failed before and succeeds after.
- **The three topics:** identity protocols (OAuth 2.0, OpenID Connect, SAML
  2.0, and where Keycloak sits in the Cloud Native Computing Foundation (CNCF)
  landscape), realms (the `master` realm against application realms), and
  running Keycloak (the container image, configuration, production mode,
  the database and realm import). The README table maps each section to its
  topic.
- **The sections:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | OAuth 2.0, OpenID Connect And SAML In Keycloak | Identity protocols |
  | 020 | The Master Realm And Application Realms | Realms |
  | 030 | Running Keycloak From The Container Image | Running Keycloak |

- **The version:** everything is written for **Keycloak 26.8.1**, image
  `quay.io/keycloak/keycloak:26.8.1`, on a single-node `kind` cluster. Do not
  teach fields, flags or output from other versions without saying so. Pin the
  image tag in every manifest; never use `latest`.
- **The main sources:** the Keycloak guides, <https://www.keycloak.org/guides>,
  the Server Administration Guide,
  <https://www.keycloak.org/docs/latest/server_admin/index.html>, and the
  Securing Applications guides. Check every page against them.

### Status: built, not yet run

The first version of this repository was written from the Keycloak 26.8.1
documentation **without a live run**. No playground or lab has been started,
and no `astrona test` has passed yet. Until a maintainer runs them:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run, and then paste it exactly.
- Treat every lab as unverified. Run `astrona validate` and `astrona test` on
  each one, one cluster at a time, before the course goes past `maturity:
  draft`.
- Remove this subsection when every lab has passed `astrona test`.

### Terms, not metaphors

Explanations use Keycloak's, OAuth's, OpenID Connect's and Kubernetes' own
words. Define each one in plain technical language on first use in a file,
for example:

| Term | First-use definition (example wording) |
| --- | --- |
| Identity provider (IdP) | A service that checks who a user is and tells applications the result, in a signed token or assertion |
| Realm | A space in Keycloak that holds its own users, clients, roles, groups and settings; realms do not see each other |
| `master` realm | The realm Keycloak creates at first start; it holds the administrator accounts and is used only to manage other realms |
| Client | An application or service that asks Keycloak to sign users in or to issue tokens |
| Public client / confidential client | A client that cannot keep a secret (a browser or command-line app) / a client that can, and proves who it is with a client secret |
| OAuth 2.0 | A framework that lets a client get an access token to call an API, without seeing the user's password |
| OpenID Connect (OIDC) | A layer on top of OAuth 2.0 that adds an ID token, which tells the client who the user is |
| SAML 2.0 | An older XML-based standard where the identity provider sends a signed assertion about the user to a service provider |
| Access token / ID token / refresh token | A token a client sends to an API / a token that describes the signed-in user to the client / a token the client uses to get new tokens |
| JSON Web Token (JWT) | A token made of three Base64URL parts (header, payload, signature), separated by dots |
| Grant type | The way a client gets a token, for example `client_credentials` or `authorization_code` |
| Discovery document | The JSON at `/realms/<realm>/.well-known/openid-configuration` that lists a realm's endpoints and features |
| Issuer (`iss`) | The URL of the realm that signed a token; it must match what the client expects |
| `kc.sh` / `kcadm.sh` | Keycloak's server command (`start`, `start-dev`, `build`, `export`, `import`) / the administration command-line tool that calls the Admin REST API |
| Build option / runtime option | A setting fixed into an optimized server with `kc.sh build` (for example `db`) / a setting read at every start (for example `hostname`) |
| Development mode / production mode | `kc.sh start-dev` with HTTP and relaxed hostname checks / `kc.sh start`, which requires a hostname and TLS or explicit HTTP |

Do not invent friendly names for these (no "the gatekeeper", "the passport",
"the key ring"). The product's names are what the student meets in the
console and the logs.

### The example workloads

Every module deploys the same small setup into its own namespace
(`protocols-demo`, `realms-demo`, `image-demo`, `database-demo`; capstones use
`protocolscapstone-demo`, `realmscapstone-demo` and `runcapstone-demo`).

| Kubernetes name | Image | What it is |
| --- | --- | --- |
| `keycloak` (Deployment and Service) | `quay.io/keycloak/keycloak:26.8.1` | One Keycloak pod. Service port `8080` (`http`) and `9000` (`management`, for `/health` and `/metrics`) |
| `keycloak-admin` (Secret) | | Bootstrap administrator: user `admin`, password `admin`. Lab-only credentials; say so when a page uses them |
| `postgres` (Deployment and Service) | `postgres:17-alpine` | PostgreSQL 17 on port `5432`, database `keycloak`; only in section 030 |
| `keycloak-db` (Secret) | | Database user `keycloak`, password `keycloak-db-password`; only in section 030 |
| `tester` | `nicolaka/netshoot:v0.13` | Client pod with `curl` and `jq`. Every test request is sent from here with `kubectl exec deploy/tester -- ...` |

Inside Keycloak, every module uses the same names:

| Keycloak name | What it is |
| --- | --- |
| realm `inventory` | The application realm |
| user `alice` | A user in `inventory`, password `alice-password`, with email, first name and last name set, so the user profile is complete |
| client `inventory-cli` | Public client with **Direct access grants** on, used to request tokens for `alice` with the password grant |
| client `inventory-reporter` | Confidential client with **Service accounts** on, used for the client credentials grant |
| client `inventory-web` | Confidential client with the standard flow (authorization code), used where a browser application is needed |

The password grant (`grant_type=password`, "Direct access grants" in the
console) is used **only** so a grader and the reader can get a token for a
user from a terminal. Say every time it is used that OAuth 2.1 drops it and a
real application uses the authorization code flow.

### Environment facts the text must respect

- **Keycloak runs as plain Kubernetes manifests**, not the Keycloak Operator
  (that is domain 6, `ATS093`). Every playground and lab applies
  `manifests/lab-start.yaml` and waits for `deployment/keycloak`.
- **The administration helper.** Pages and scripts call `kcadm.sh` inside the
  Keycloak pod, with the configuration file in `/tmp` so it never depends on a
  writable home directory:

  ```sh
  kcadm() {
    kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
      /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
  }
  kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
  ```

  The session from `config credentials` expires; run it again when `kcadm`
  answers `401`. A pod restart deletes `/tmp/kcadm.config`.
- **The `tester` pod reaches Keycloak at `http://keycloak:8080`.** In
  development mode the issuer in a token follows the request, so it is
  `http://keycloak:8080/realms/<realm>`. Pages that use a browser reach the
  console with `kubectl -n <namespace> port-forward svc/keycloak 8080:8080`,
  and then the issuer is `http://localhost:8080/realms/<realm>`. Never mix
  the two in one example.
- **Keycloak 26.8.1 facts (from the documentation, not yet seen on a run):**
  - Configuration sources, highest priority first: command-line options,
    environment variables (`KC_` plus the option in upper case with
    underscores, for example `KC_DB_URL_HOST`), `conf/keycloak.conf`, then a
    Java KeyStore. `KCRAW_` keeps a `$` in a value as it is.
  - `start-dev`: HTTP on, `hostname-strict` false, local caches, `db` default
    `dev-file`. `start`: HTTP off, needs `--hostname` (or `--hostname-strict
    false`) and TLS (or `--http-enabled true` behind a TLS-terminating proxy),
    or it does not start.
  - `--hostname` takes a host name or a full URL. `--proxy-headers` takes
    `forwarded` or `xforwarded`.
  - `KC_BOOTSTRAP_ADMIN_USERNAME` and `KC_BOOTSTRAP_ADMIN_PASSWORD` create
    the first administrator in `master`; if one exists, an error is logged and
    the server still starts.
  - `db` values: `dev-file` (default), `dev-mem`, `mariadb`, `mssql`,
    `mysql`, `oracle`, `postgres`, `tidb`. Supported PostgreSQL: 14 to 18.
    `dev-file` is for development only, and its use in production mode is
    deprecated.
  - Health and metrics are off by default (`KC_HEALTH_ENABLED`,
    `KC_METRICS_ENABLED`), and are served on the management port `9000`:
    `/health`, `/health/ready`, `/health/live`, `/metrics`.
  - The image has no package manager (`microdnf`, `dnf`, `rpm`). Extra
    tools come in through a multi-stage build.
  - Optimized image: build stage runs `kc.sh build` with build options, final
    stage copies `/opt/keycloak/`, and the container runs `start --optimized`.
  - `--import-realm` imports every regular `.json` file in
    `/opt/keycloak/data/import` at start, named `<realm>-realm.json`. **A realm
    that already exists is skipped**, not updated. `kc.sh import` overrides by
    default (`--override true`).
  - The Admin Console's partial export masks secrets with `*` and leaves out
    users; it is not a backup.
- **Many environments start broken on purpose.** A lab seeds the fault after
  Keycloak is up (a client with the wrong settings, a user that cannot sign
  in, a Deployment in the wrong mode). The fault is the material. Never "fix"
  it in the bootstrap.
- **Keycloak is slow to start.** Allow up to five minutes for the first
  rollout (image pull plus start). Probes use `/health/ready` and
  `/health/live` on port `9000`, so `KC_HEALTH_ENABLED=true` is set in every
  manifest unless a lab breaks it on purpose.
- **The proof is a token request from `tester`.** A fix is proven with
  `kubectl exec deploy/tester -- curl ... /protocol/openid-connect/token`
  returning a token, decoded with `jq`, plus the matching check (the right
  `iss`, `azp` or `preferred_username`, a realm row in PostgreSQL, a pod that
  is `Ready`).

### Where things are in this repo

| What | Where |
| --- | --- |
| Course outline the platform reads: every reading page and lab, in order. Never list `solution.md` here | `astrona.yaml` |
| Overview, sections and modules tables, how to run things | `README.md` |
| Introduction (see "Every course starts with an Introduction") | `sections/intro/` |
| Section overview and its modules | `sections/section-0N0/README.md` |
| Module reading: landing page, deep-dive parts, closing page | `sections/section-0N0/module-0M/course.md`, `course-0N-*.md` |
| Graded lab: task, walkthrough, setup, grader | `.../labs/lab-01/` (`question.md`, `solution.md`, `prerequisites.md`, `bootstrap/`, `manifests/`, `solution/`, `testing/`, `validation/`) |
| Ungraded sandbox for a module | `.../playground/` (`config.yaml`, `bootstrap/prepare.sh`, `manifests/`, `docs/overview.md`, which is the only learner page) |
| One graded integration lab per section | `sections/section-0N0/capstone/labs/lab-01/` |

A lab folder holds:

| Path | Purpose |
| --- | --- |
| `config.yaml` | Lab definition; `metadata.docs` points at `question.md` and `solution.md` |
| `README.md` | Short intro for authors with `estimated_duration` front matter and the run, submit and destroy commands |
| `prerequisites.md` | What the learner needs before starting |
| `question.md` | The task. Starts with `# Question` and `Solve this question on: \`terminal\`` |
| `solution.md` | Step-by-step walkthrough |
| `bootstrap/01-deploy-keycloak.sh`, `02-seed-state.sh` | Keycloak deployment and the broken starting state |
| `manifests/` | `lab-start.yaml` (workloads) and any extra faulty objects |
| `solution/apply.sh` | Reference end state, applied only by `astrona test` |
| `testing/wait-for-keycloak.sh` | Waits until Keycloak answers before the reference solution runs |
| `validation/validate-*.sh` | Behavioural grading, one script per check |

### Lab metadata in `astrona.yaml`

`astrona.yaml` has a `training:` block (id `ATS088`, domain
`Fundamentals & Getting Started`, weight `10`) and one entry per section under
`modules:` (`module-010`, `module-020`, `module-030`). Each section's `content`
lists, in order: the section `README.md`, then for each module its landing
page, its parts, and right after the part a lab tests, a `Question` reading
(`labs/lab-01/question.md`) followed by the `type: lab` entry; the module's
closing page comes last. The section capstone closes the section.
Playgrounds are not listed: the landing page's `<!-- astrona:playground -->`
marker shows them.

Every `type: lab` entry carries the same fields, in the same order, as in
ATS016: `title`, `path`, `difficulty`, `estimated_duration`, `topic`,
`task_kind`, `tags`, `learning_goals`, `resources`.

- `difficulty`: `beginner`, `intermediate` or `advanced`.
- `estimated_duration`: realistic time to solve it, for example `15m`, `30m`.
- `topic`: exactly one of `protocols`, `tokens`, `realms`, `administration`,
  `server-configuration`, `database`.
- `task_kind`: exactly one of `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8 ids, only from the tag list below. Add a new tag to the list
  first if nothing fits.
- `learning_goals`: 2 or 3 plain sentences, each starting with a verb.
- `resources`: 1 to 4 pages on `keycloak.org` (or the OAuth and OpenID
  specifications), each with a `name` and a `url` that loads. This is the
  **only** place outside links are allowed.

**Tag list** (lower case, hyphens, never synonyms):

- Protocols: `oauth2`, `oidc`, `saml`, `discovery-document`, `jwt`,
  `access-token`, `id-token`, `token-endpoint`
- Grants and clients: `client-credentials`, `password-grant`,
  `authorization-code`, `public-client`, `confidential-client`,
  `service-account`, `client-secret`
- Realms and administration: `master-realm`, `application-realm`,
  `bootstrap-admin`, `kcadm`, `admin-rest-api`, `users`, `required-actions`
- Server: `container-image`, `start-dev`, `production-mode`, `hostname`,
  `http-enabled`, `health-endpoints`, `build-options`, `env-vars`
- Database and import: `postgresql`, `dev-file`, `db-options`,
  `kubernetes-secret`, `realm-import`, `realm-export`

### Running things

```bash
# Playground (ungraded)
astrona run --git ssh://git@github.com/astrona-io/ATS088.git -c sections/section-010/module-01/playground
astrona destroy ats-088-playground-010-01   # takes metadata.name from config.yaml, not the path

# Lab or capstone (graded against the live cluster)
astrona run --git ssh://git@github.com/astrona-io/ATS088.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-088-lab-010-01

# Authors: run a local, uncommitted copy, and prove a lab passes with its reference solution
astrona run -c sections/section-010/module-01/playground
astrona test -c sections/section-010/module-01/labs/lab-01
```

Names: a playground is `ats-088-playground-<section>-<module>`, a module lab
is `ats-088-lab-<section>-<module>` and a capstone is
`ats-088-capstone-<section>`; keep those names. A second lab in a module
takes `ats-088-lab-<section>-<module>-<lab>`. Lab bootstrap scripts do not pin
a kube context: astrona sets `KUBECONFIG` for the lab. Every lab must pass
`astrona validate` and `astrona test`.

Graders check **behaviour**, not just that an object exists: request a real
token from `tester` and check its claims. Graders also reject the plausible
but wrong fix (turning on the password grant on a client that only needs
client credentials, putting the database password in plain text in the
Deployment, switching back to `start-dev` to make production mode start,
creating the application in `master`). A lab's `question.md` and
`solution.md` must match what its `validation/` scripts actually check.

Test clusters on the maintainer's machine: one at a time. Keycloak needs about
1 GiB of memory per cluster, and section 030 adds PostgreSQL.

### Where to find trusted sources

Check facts here before writing them down. Prefer these over memory.

- **Server:**
  [containers](https://www.keycloak.org/server/containers),
  [configuration](https://www.keycloak.org/server/configuration),
  [hostname](https://www.keycloak.org/server/hostname),
  [database](https://www.keycloak.org/server/db),
  [health](https://www.keycloak.org/observability/health),
  [import and export](https://www.keycloak.org/server/importExport),
  [all configuration options](https://www.keycloak.org/server/all-config)
- **Getting started:**
  [Kubernetes](https://www.keycloak.org/getting-started/getting-started-kube),
  [container](https://www.keycloak.org/getting-started/getting-started-docker)
- **Administration:**
  [Server Administration Guide](https://www.keycloak.org/docs/latest/server_admin/index.html)
  (realms, the `master` realm, users, clients, the Admin CLI)
- **Protocols:**
  [Securing applications: OpenID Connect](https://www.keycloak.org/securing-apps/oidc-layers),
  [SAML](https://www.keycloak.org/securing-apps/saml-galleon-layers),
  [RFC 6749 OAuth 2.0](https://datatracker.ietf.org/doc/html/rfc6749),
  [OpenID Connect Core 1.0](https://openid.net/specs/openid-connect-core-1_0.html),
  [RFC 7519 JWT](https://datatracker.ietf.org/doc/html/rfc7519)
- **The landscape:** Keycloak's page on the CNCF site,
  <https://www.cncf.io/projects/keycloak/>.

### Skills to use here

The `astrona-course-*` skills do most authoring jobs in this repository:
planning (`domain-plan`), creating the tree (`domain-scaffold`), building
modules (`domain-build`), deep-dive parts (`deep-dive`), labs and playgrounds
(`lab`), lab docs (`lab-docs`), challenges (`create-challenge`), quizzes
(`generate-assessment`) and fact-checking (`review-accuracy`).
