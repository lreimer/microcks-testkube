# Continuous API mocking and testing with Microcks and Testkube

Demo repository for my conference talk on continuous API testing with Microcks and Testkube.

## Bootstrapping

```bash
# create infrastructure and bootstrap Flux
make create-gcp-cluster
make bootstrap-gcp-flux2

# next we will register the cluster with Testkube
brew install testkube
testkube login api.testkube.io
testkube install ...
testkube init agent ...

# for now we install the Microcks operator manually
kubectl apply -f https://raw.githubusercontent.com/microcks/microcks-operator/refs/tags/0.0.5/deploy/crd/microckses.microcks.io-v1.yml
kubectl apply -f https://raw.githubusercontent.com/microcks/microcks-operator/refs/tags/0.0.5/deploy/crd/apisources.microcks.io-v1.yml
kubectl apply -f https://raw.githubusercontent.com/microcks/microcks-operator/refs/tags/0.0.5/deploy/crd/secretsources.microcks.io-v1.yml

kubectl create namespace microcks
kubectl apply -f https://raw.githubusercontent.com/microcks/microcks-operator/refs/tags/0.0.5/deploy/operator-jvm.yaml -n microcks
kubectl apply -f microcks/microcks-local.yaml -n microcks
```

## Testkube Demo

```bash
# make sure you are in the correct K8s context
kubectl apply -f testkube/gradle-demo/
kubectl apply -f testkube/k6-demo/

open https://app.testkube.io/
```

## Microcks Demo

```bash
# install the Pastry demo API from the Microcks Hub

# making calls against the mock
http --verify=no get https://microcks.127.0.0.1.sslip.io/rest/API+Pastry+-+2.0/2.0.0/pastry/Millefeuille

# deploy the real service implementation
kubectl create deployment quarkus-api-pastry --image=quay.io/microcks/quarkus-api-pastry:latest
kubectl expose deployment quarkus-api-pastry --name quarkus-api-pastry-svc --port=8282 --load-balancer-ip=''
kubectl apply -f microcks/pastry-ingress.yaml
pastry.127.0.0.1.sslip.io/pastry
```

## Maintainer

M.-Leander Reimer (@lreimer), <mario-leander.reimer@qaware.de>

## License

This software is provided under the MIT open source license, read
the `LICENSE` file for details.
