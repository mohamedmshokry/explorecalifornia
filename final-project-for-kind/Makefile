#!/usr/bin/env make

.PHONY: clean_containers run_website stop_website install_kind install_kubectl create_kind_cluster \
		create_docker_registry connect_registry_to_kind_network  connect_registry_to_kind \
		create_kind_cluster_with_registry delete_kind_cluster delete_docker_registry \
		install_helm_ubuntu install_app_helm

clean_containers:
	docker rm -f $$(docker ps -a -q)

run_website: clean_containers
	docker build -t explorecalifornia-img . && \
		docker run -p 5000:80 -d --name explorecalifornia --rm explorecalifornia-img

stop_website:
	docker stop explorecalifornia

install_kind:
	curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64; \
	chmod +x ./kind && \
		sudo mv ./kind /usr/local/bin/kind

install_kubectl:
	sudo snap install kubectl --classic
	
create_docker_registry:
	if ! docker ps | grep -q 'local-registry'; \
    then docker run -d -p 5000:5000 --name local-registry --restart=always registry:2; \
    else echo "---> local-registry is already running. There's nothing to do here."; \
    fi

create_kind_cluster: install_kind install_kubectl create_docker_registry
	kind create cluster --image=kindest/node:v1.21.12 --name explorecalifornia.com --config ./kind_config.yaml || true
	kubectl get nodes

connect_registry_to_kind_network:
	docker network connect kind local-registry || true;

connect_registry_to_kind: connect_registry_to_kind_network
	kubectl apply -f ./kind_configmap.yaml;

create_kind_cluster_with_registry:
	$(MAKE) create_kind_cluster && $(MAKE) connect_registry_to_kind

delete_kind_cluster: delete_docker_registry
	kind delete cluster --name explorecalifornia.com

delete_docker_registry:
	docker stop local-registry && docker rm local-registry

install_helm_ubuntu:
	sudo apt install -y snapd && \
		sudo snap install helm --classic

install_app_helm: install_helm_ubuntu
	    helm upgrade --atomic --install explore-california-website ./chart