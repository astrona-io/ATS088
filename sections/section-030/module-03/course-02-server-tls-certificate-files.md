# Server TLS Certificate Files

When Keycloak serves HTTPS itself, it needs two files: a certificate and the private key that belongs to it. Both must reach the container without being baked into the image or written into a Deployment as text. Kubernetes stores them in a Secret, and the Deployment mounts the Secret as files. This part creates a self-signed certificate, stores it, and points Keycloak at the files.

## Certificate and key

A **certificate** is a signed statement that a public key belongs to a name. The **private key** is the matching secret half, and only the server may hold it. A **Subject Alternative Name (SAN)** lists the host names the certificate is valid for. A client accepts the certificate only if the host name it connects to is in the SAN list and a trusted authority signed the certificate. A **self-signed** certificate is signed by its own key, so no client trusts it by default. That is fine for a lab and wrong for production.

Keycloak reads certificates in PEM format, a text format with lines such as `-----BEGIN CERTIFICATE-----`. The two options are `https-certificate-file` and `https-certificate-key-file`, set with the environment variables `KC_HTTPS_CERTIFICATE_FILE` and `KC_HTTPS_CERTIFICATE_KEY_FILE`.

<!-- astrona:playground:renew -->

Create a certificate for the names the server is reached by. The `openssl` command runs in the tester pod, and the two `cat` commands copy the files to your machine:

```sh
kubectl -n edge-demo exec deploy/tester -- sh -c '
openssl req -x509 -newkey rsa:2048 -nodes -days 30 \
  -keyout /tmp/tls.key -out /tmp/tls.crt -subj "/CN=id.example.test" \
  -addext "subjectAltName=DNS:keycloak,DNS:keycloak.edge-demo.svc,DNS:id.example.test"'
kubectl -n edge-demo exec deploy/tester -- cat /tmp/tls.crt > tls.crt
kubectl -n edge-demo exec deploy/tester -- cat /tmp/tls.key > tls.key
```

The files `tls.crt` and `tls.key` now exist in your current directory. The certificate is valid for 30 days and names three hosts. Store both in a Secret of the type `kubernetes.io/tls`, which requires the keys `tls.crt` and `tls.key`:

```sh
kubectl -n edge-demo create secret tls keycloak-tls --cert=tls.crt --key=tls.key
```

A Secret keeps its values only Base64-encoded, so anyone who can read the Secret in the namespace can read the key. Restrict access to Secrets with Kubernetes roles, and never commit the key to a repository.

## Mount the Secret and open the port

Save this as `patch-keycloak-tls.yaml`. It adds the Secret as a read-only volume, sets the two options, and opens container port `8443`:

```yaml
spec:
  template:
    spec:
      containers:
        - name: keycloak
          env:
            - name: KC_HTTPS_CERTIFICATE_FILE
              value: /opt/keycloak/conf/tls/tls.crt
            - name: KC_HTTPS_CERTIFICATE_KEY_FILE
              value: /opt/keycloak/conf/tls/tls.key
            - name: KC_HTTP_MANAGEMENT_SCHEME
              value: http
          ports:
            - name: https
              containerPort: 8443
          volumeMounts:
            - name: tls
              mountPath: /opt/keycloak/conf/tls
              readOnly: true
      volumes:
        - name: tls
          secret:
            secretName: keycloak-tls
```

Apply it to the Deployment and wait for the new pod:

```sh
kubectl -n edge-demo patch deployment keycloak --patch-file patch-keycloak-tls.yaml
kubectl -n edge-demo rollout status deployment/keycloak --timeout=600s
```

The setting `KC_HTTP_MANAGEMENT_SCHEME=http` keeps the management port `9000` on plain HTTP. When a certificate is configured, the management interface inherits TLS by default, and the HTTP probes of the Deployment would then fail. Save this as `service-keycloak.yaml` to open the port on the Service as well:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: keycloak
  namespace: edge-demo
spec:
  selector:
    app: keycloak
  ports:
    - name: http
      port: 8080
      targetPort: 8080
    - name: https
      port: 8443
      targetPort: 8443
    - name: management
      port: 9000
      targetPort: 9000
```

Apply it and send an HTTPS request:

```sh
kubectl apply -f service-keycloak.yaml
kubectl -n edge-demo exec deploy/tester -- curl -sk -o /dev/null -w '%{http_code}\n' https://keycloak:8443/realms/master
```

Keycloak answers with status `200`. The option `-k` tells `curl` to skip certificate validation, which this self-signed certificate needs. Read what the server presents, with `openssl s_client` in the tester pod:

```sh
kubectl -n edge-demo exec deploy/tester -- sh -c \
  'openssl s_client -connect keycloak:8443 -servername keycloak </dev/null 2>/dev/null | openssl x509 -noout -subject -dates -ext subjectAltName'
```

The output shows the subject `CN=id.example.test`, the validity dates and the three names in the SAN list. This is the certificate in the Secret, read through the running server.

You now know what a certificate and key are, how to store them in a Secret, and how a Deployment mounts them for Keycloak. The open question is how the server behaves when a reverse proxy sits in front of it and sends the client's original address in headers.

## Common pitfalls

> [!WARNING]
> - **Putting the key in an environment variable or in the image.** Mount a Secret.
> - **A certificate whose SAN list lacks the host name.** Clients reject it even if it is otherwise valid.
> - **Forgetting `KC_HTTP_MANAGEMENT_SCHEME=http`.** The probes then speak HTTP to a port that expects HTTPS, and the pod never becomes ready.
> - **Opening `8443` on the container but not on the Service.** Other pods cannot reach it.
> - **Using a self-signed certificate in production.** Clients do not trust it.
