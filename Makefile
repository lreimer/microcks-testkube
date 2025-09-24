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

delete-gcp-cluster:
	@gcloud container clusters delete $(CLUSTER_NAME) --region=$(GCP_REGION) --async --quiet