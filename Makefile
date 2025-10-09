GCP_PROJECT ?= cloud-native-experience-lab
GCP_REGION ?= europe-west4
GCP_ZONE ?= europe-west4-b

GITHUB_USER ?= lreimer
CLUSTER_NAME ?= microcks-testkube

prepare-gcp:
	@gcloud config set project $(GCP_PROJECT)
	@gcloud config set compute/zone $(GCP_ZONE)
	@gcloud config set container/use_client_certificate False

create-gcp-cluster:
	@gcloud container clusters create $(CLUSTER_NAME)  \
	  	--release-channel=regular \
		--cluster-version=1.33 \
  		--region=$(GCP_REGION) \
		--enable-ip-alias \
		--addons HttpLoadBalancing,HorizontalPodAutoscaling \
		--workload-pool=$(GCP_PROJECT).svc.id.goog \
		--enable-autoscaling \
		--num-nodes=1 \
		--min-nodes=1 --max-nodes=3 \
		--machine-type=e2-standard-8 \
		--gateway-api=standard \
		--verbosity=info \
		--logging=SYSTEM \
    	--monitoring=SYSTEM
	@kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$$(gcloud config get-value core/account)
	@kubectl cluster-info

bootstrap-gcp-flux2:
	@flux bootstrap github \
		--owner=$(GITHUB_USER) \
        --repository=microcks-testkube \
        --branch=main \
        --path=./clusters/$(CLUSTER_NAME) \
		--components-extra=image-reflector-controller,image-automation-controller \
		--read-write-key

create-microcks-cert:
	@openssl genrsa -out microcks/microcks.key 2048
	@openssl req -new -key microcks/microcks.key -out microcks/microcks.csr -config microcks/microcks.cnf
	@openssl x509 -req -signkey microcks/microcks.key -in microcks/microcks.csr -out microcks/microcks.crt -days 365 -extensions extension_requirements -extfile microcks/microcks.cnf
	@kubectl create secret tls microcks-tls --cert=microcks/microcks.crt --key=microcks/microcks.key -n microcks

update-microcks-cert:
	@rm -f microcks/microcks.csr microcks/microcks.crt
	@openssl req -new -key microcks/microcks.key -out microcks/microcks.csr -config microcks/microcks.cnf
	@openssl x509 -req -signkey microcks/microcks.key -in microcks/microcks.csr -out microcks/microcks.crt -days 365 -extensions extension_requirements -extfile microcks/microcks.cnf
	@kubectl delete secret microcks-tls -n microcks --ignore-not-found=true
	@kubectl create secret tls microcks-tls --cert=microcks/microcks.crt --key=microcks/microcks.key -n microcks

create-keycloak-cert:
	@openssl genrsa -out microcks/keycloak.key 2048
	@openssl req -new -key microcks/keycloak.key -out microcks/keycloak.csr -config microcks/keycloak.cnf
	@openssl x509 -req -signkey microcks/keycloak.key -in microcks/keycloak.csr -out microcks/keycloak.crt -days 365 -extensions extension_requirements -extfile microcks/keycloak.cnf
	@kubectl create secret tls keycloak-tls --cert=microcks/keycloak.crt --key=microcks/keycloak.key -n microcks

update-keycloak-cert:
	@rm -f microcks/keycloak.csr microcks/keycloak.crt
	@openssl req -new -key microcks/keycloak.key -out microcks/keycloak.csr -config microcks/keycloak.cnf
	@openssl x509 -req -signkey microcks/keycloak.key -in microcks/keycloak.csr -out microcks/keycloak.crt -days 365 -extensions extension_requirements -extfile microcks/keycloak.cnf
	@kubectl delete secret keycloak-tls -n microcks --ignore-not-found=true
	@kubectl create secret tls keycloak-tls --cert=microcks/keycloak.crt --key=microcks/keycloak.key -n microcks

delete-gcp-cluster:
	@gcloud container clusters delete $(CLUSTER_NAME) --region=$(GCP_REGION) --async --quiet