# Continuous API mocking and testing with Microcks and Testkube

Demo repository for my conference talk on continuous API testing with Microcks and Testkube.

## Bootstrapping

```bash
# next we will register the cluster with Testkube
brew install testkube
testkube login api.testkube.io
testkube install ...
testkube init agent ...

# for now we install the Microcks operator manually
kubectl apply -f https://raw.githubusercontent.com/microcks/microcks-operator/refs/tags/0.0.5/deploy/crd/microckses.microcks.io-v1.yml
kubectl apply -f https://raw.githubusercontent.com/microcks/microcks-operator/refs/tags/0.0.5/deploy/crd/apisources.microcks.io-v1.yml
kubectl apply -f https://raw.githubusercontent.com/microcks/microcks-operator/refs/tags/0.0.5/deploy/crd/secretsources.microcks.io-v1.yml
kubectl apply -f https://raw.githubusercontent.com/microcks/microcks-operator/refs/tags/0.0.5/deploy/crd/tests.microcks.io-v1.yml

kubectl create namespace microcks
kubectl apply -f https://raw.githubusercontent.com/microcks/microcks-operator/refs/tags/0.0.5/deploy/operator.yaml -n microcks

kubectl apply -f microcks/microcks-local.yaml -n microcks

# the default user/password is admin/microcks123
open https://keycloak.127.0.0.1.sslip.io
open https://microcks.127.0.0.1.sslip.io
```

## Microcks Demo

```bash
# install the Pastry demo API from the Microcks Hub
# or create the artifacts via YAML descriptor using GitOps
kubectl apply -f microcks/pastry-artifacts.yaml -n microcks

microcks-cli import microcks/APIPastry-openapi.yaml:true \
    --microcksURL=https://microcks.127.0.0.1.sslip.io/api/ \
    --keycloakClientId=microcks-serviceaccount \
    --keycloakClientSecret="ab54d329-e435-41ae-a900-ec6b3fe15c54" \
    --insecure --waitFor=6sec

# making calls against the mock
http --verify=no get https://microcks.127.0.0.1.sslip.io/rest/API+Pastry+-+2.0/2.0.0/pastry
http --verify=no get https://microcks.127.0.0.1.sslip.io/rest/API+Pastry+-+2.0/2.0.0/pastry/Millefeuille

# deploy the real service implementation
# either manually
kubectl create deployment quarkus-api-pastry --image=quay.io/microcks/quarkus-api-pastry:latest
kubectl expose deployment quarkus-api-pastry --name quarkus-api-pastry-svc --port=8282 --load-balancer-ip=''

# or via YAML descriptors
kubectl apply -f microcks/pastry-deployment.yaml
kubectl apply -f microcks/pastry-service.yaml
kubectl apply -f microcks/pastry-ingress.yaml

# access the Pastry demo service API
http get pastry.127.0.0.1.sslip.io/pastry

# run compatibility tests
kubectl apply -f microcks/pastry-test.yaml -n microcks

microcks-cli test 'API Pastry - 2.0:2.0.0' http://quarkus-api-pastry-svc.default.svc.cluster.local:8282 OPEN_API_SCHEMA \
    --microcksURL=https://microcks.127.0.0.1.sslip.io/api/ \
    --keycloakClientId=microcks-serviceaccount \
    --keycloakClientSecret="ab54d329-e435-41ae-a900-ec6b3fe15c54" \
    --insecure --waitFor=30sec
```

## Testkube Demo

```bash
# make sure you are in the correct K8s context
open https://app.testkube.io/

# this will deploy the K6 load test for Nginx with trigger
kubectl apply -f testkube/k6-demo/
kubectl scale deployment nginx-deployment --replicas 2

# this will deploy the Microcks API test with trigger
kubectl apply -f testkube/microcks/
kubectl scale deployment quarkus-api-pastry --replicas 2
```

## Maintainer

M.-Leander Reimer (@lreimer), <mario-leander.reimer@qaware.de>

## License

This software is provided under the MIT open source license, read
the `LICENSE` file for details.
