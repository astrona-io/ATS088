# Welcome To The Course

This course trains you for the **Fundamentals & Getting Started** part of the Astrona **Keycloak** training path. That part is 10% of the path. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes: namespaces, Deployments, Services, Secrets, ConfigMaps, `kubectl logs` and `kubectl exec`. You have used `curl` to call an HTTP API and you can read JSON. You do not need to know Keycloak or identity protocols yet. Each new idea is explained the first time it appears.

## What you can do at the end

Keycloak is a server you run and talk to, so this course does not ask you to remember words. It asks you to start Keycloak, send it real requests, read the tokens it returns, and fix it when it does not do what you expect. The course has three topics, and each one turns into a set of skills you will practise.

The first topic is **identity protocols**: the standards Keycloak uses to tell applications who a user is. You will learn to:

- Explain what an identity provider does and where Keycloak sits among the identity projects of the Cloud Native Computing Foundation (CNCF).
- Request an access token with the OAuth 2.0 client credentials grant, and tell a public client from a confidential client.
- Read an ID token and a realm's OpenID Connect (OIDC) discovery document.
- Say when SAML 2.0 is the right protocol and when OpenID Connect is.

Every token comes from a realm, so the second topic is **realms**. You will learn to:

- Explain why the `master` realm is only for administration.
- Create an application realm, a user and a client from the terminal with `kcadm.sh`.
- Move an application that was set up in `master` into its own realm.

The third topic is **running Keycloak**. You will learn to:

- Find your way around the Keycloak container image.
- Configure Keycloak with command-line options and environment variables, and tell build options from runtime options.
- Start Keycloak in production mode with a hostname and health checks.
- Store Keycloak's data in PostgreSQL and import a realm when the server starts.

Everything is written for **Keycloak 26.8.1**.

## The words this course uses

The pages use Keycloak's, OAuth's, OpenID Connect's and Kubernetes' own terms, because those are the words you meet in the product, the logs and the documentation. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

An **identity provider** is a service that checks who a user is and tells applications the result. Keycloak is an identity provider. A **realm** is a space in Keycloak that holds its own users, clients, roles and settings. A **client** is an application or service that asks Keycloak to sign users in or to issue tokens. A **token** is a signed piece of data that Keycloak gives to a client, and most tokens in this course are **JSON Web Tokens (JWT)**: three Base64URL parts separated by dots.

Keycloak issues three kinds of token, and you will read all of them:

| Token | What it is for |
| --- | --- |
| Access token | The client sends it to an API to show it may call that API |
| ID token | Tells the client who the signed-in user is (OpenID Connect only) |
| Refresh token | Lets the client get new tokens without asking the user again |

## The example setup in your playground

Every playground and lab runs the same small setup. One Keycloak pod, behind the Service `keycloak`, answers on port `8080` for normal traffic and on port `9000` for health checks. You send your test requests from the `tester` pod, a client with `curl` and `jq`. In the last section, a PostgreSQL pod stores Keycloak's data.

Inside Keycloak, the pages use the same names everywhere. The application realm is `inventory`. The user `alice` signs in to it. Two clients belong to it: `inventory-cli`, a command-line application, and `inventory-reporter`, a background service that has no user.

Each module puts this setup in its own namespace, for example `protocols-demo` or `database-demo`, so the pages always tell you the namespace to use. Many labs start with something broken on purpose. That is the material, not a fault in the course.

## How the course is laid out

The course has three sections. It starts with what Keycloak gives an application, then where those things live, and ends with how to run the server.

| Section | What it covers |
| --- | --- |
| 010 | OAuth 2.0, OpenID Connect And SAML In Keycloak |
| 020 | The Master Realm And Application Realms |
| 030 | Running Keycloak From The Container Image |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.
