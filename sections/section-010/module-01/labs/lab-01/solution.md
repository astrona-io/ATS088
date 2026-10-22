# Solution: Give A Service Client Its Own Token

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: `inventory-reporter` is a confidential client with service accounts on, the password grant and the standard flow are still off, and the secret in the Kubernetes Secret `inventory-reporter-credentials` gets an access token whose `azp` claim is `inventory-reporter`.

## Step 1: Reproduce the failure

Send the request from the task and read the whole response:

```sh
kubectl -n protocols-demo exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=client_credentials \
    -d client_id=inventory-reporter | jq
```

The response has no `access_token`. It has an `error` field and an `error_description`. Keycloak, the authorization server, refused the grant for this client before any API was involved, so the fault is in the client's settings.

## Step 2: Read the client's settings

Define the `kcadm` helper and sign in to the `master` realm as the lab-only administrator:

```sh
NAMESPACE=protocols-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get clients -r inventory -q clientId=inventory-reporter \
  --fields id,clientId,publicClient,serviceAccountsEnabled,directAccessGrantsEnabled,standardFlowEnabled
```

`publicClient` is `true` and `serviceAccountsEnabled` is `false`. A public client has no secret, so it cannot prove who it is, and without a service account there is no user in the realm that the token could be about. Both settings must change. `directAccessGrantsEnabled` and `standardFlowEnabled` are already `false` and must stay that way.

## Step 3: Make the client confidential, with a service account

Keep the client's internal ID (the `id` field, a UUID) in a variable, and update only the settings that need to change:

```sh
CLIENT_ID=$(kcadm get clients -r inventory -q clientId=inventory-reporter --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$CLIENT_ID" -r inventory \
  -s publicClient=false -s clientAuthenticatorType=client-secret \
  -s serviceAccountsEnabled=true
```

`clientAuthenticatorType=client-secret` tells Keycloak that the client proves who it is with a client secret. Turning on `serviceAccountsEnabled` makes Keycloak create the service account user `service-account-inventory-reporter` for the client.

In the Admin Console the same change is on the client's **Settings** tab: turn **Client authentication** on and tick **Service accounts roles**, and leave **Standard flow** and **Direct access grants** unticked.

## Step 4: Generate the secret and store it in a Kubernetes Secret

Ask Keycloak to generate a new client secret, then read it back:

```sh
kcadm create "clients/$CLIENT_ID/client-secret" -r inventory
CLIENT_SECRET=$(kcadm get "clients/$CLIENT_ID/client-secret" -r inventory --fields value --format csv --noquotes | tr -d '\r')
```

Now store it where the report job reads it. The command builds the Secret and applies it, so you can run it again after you generate a new secret:

```sh
kubectl -n protocols-demo create secret generic inventory-reporter-credentials \
  --from-literal=client-secret="$CLIENT_SECRET" \
  --dry-run=client -o yaml | kubectl apply -f -
```

If you generate the secret again later, Keycloak forgets the old one at once, so the Secret must be updated in the same step.

## Step 5: Prove the fix with the stored secret

Read the secret back from the Kubernetes Secret, not from your shell variable, so you test exactly what the job will use. Then decode the token's payload:

```sh
STORED_SECRET=$(kubectl -n protocols-demo get secret inventory-reporter-credentials \
  -o jsonpath='{.data.client-secret}' | base64 --decode)
kubectl -n protocols-demo exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=client_credentials \
    -d client_id=inventory-reporter \
    -d client_secret="$STORED_SECRET" \
  | jq -r .access_token \
  | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson | {iss, azp, preferred_username}'
```

The payload shows `azp` as `inventory-reporter`, `preferred_username` as `service-account-inventory-reporter`, and `iss` as `http://keycloak:8080/realms/inventory`. The token is about the client's service account, which is what the client credentials grant gives.

## Step 6: Submit

Send the lab for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Turn on direct access grants and use the password grant | The job would need a user's password, and the client gains a grant it never needs; the grader rejects it |
| Create a new client for the job | The task names `inventory-reporter`; a second client leaves the broken one in place |
| Put the secret in the job's Deployment as a plain environment value | Anyone who can read the Deployment sees the secret; the task asks for a Kubernetes Secret |
| Turn on service accounts but leave the client public | A public client has no secret, so Keycloak still refuses the grant |

## Common mistakes

- Reading only the HTTP status. The `error_description` field says why Keycloak refused the grant.
- Generating a new secret after creating the Kubernetes Secret, so the stored value no longer works.
- Mixing up the client's `id` (a UUID used in Admin REST API paths) with its `clientId` (`inventory-reporter`).
- Testing with the secret from the shell variable instead of the one stored in the Secret.

## Practice on your own

- Regenerate the client secret with `kcadm create "clients/$CLIENT_ID/client-secret" -r inventory` and run the proof again before you update the Kubernetes Secret. Read the error.
- Decode the token and compare its `sub` claim with the ID of the user `service-account-inventory-reporter` from `kcadm get users -r inventory -q username=service-account-inventory-reporter --fields id`.
- Turn on direct access grants for `inventory-reporter`, run `astrona submit`, and read which check fails. Then turn them off again.
