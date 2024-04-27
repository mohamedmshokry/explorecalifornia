#!/usr/bin/env make

.PHONY: run_website install_kind install_kubectl create_kind_cluster \
	create_docker_registry connect_registry_to_kind_network \
	connect_registry_to_kind create_kind_cluster_with_registry delete_kind_cluster delete_docker_registry \
	install_helm_ubuntu delete_project_artifacts install_app_helm

run_website:
	docker build -t explorecalifornia.com . && \
		docker run -p 5000:80 -d --name explorecalifornia.com --rm explorecalifornia.com

install_kubectl:
	curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg; \
    sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg; \
	echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list; \
    sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list; \
	sudo apt update && \
		sudo apt install -y kubectl; \
	sudo cp -v /usr/bin/kubectl /usr/local/bin/kubectl


install_kind:
	curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64; \
	chmod +x ./kind && \
		sudo mv ./kind /usr/local/bin/kind

connect_registry_to_kind_network:
	docker network connect kind local-registry || true;

connect_registry_to_kind: connect_registry_to_kind_network
	kubectl apply -f ./kind_configmap.yaml;

create_docker_registry:
	if ! docker ps | grep -q 'local-registry'; \
	then docker run -d -p 5000:5000 --name local-registry --restart=always registry:2; \
	else echo "---> local-registry is already running. There's nothing to do here."; \
	fi

create_kind_cluster: install_kind install_kubectl create_docker_registry
	kind create cluster --image=kindest/node:v1.21.12 --name explorecalifornia.com --config ./kind_config.yaml || true
	kubectl get nodes

create_kind_cluster_with_registry:
	$(MAKE) create_kind_cluster && $(MAKE) connect_registry_to_kind

delete_kind_cluster: delete_docker_registry
	kind delete cluster --name explorecalifornia.com

delete_docker_registry:
	docker stop local-registry && docker rm local-registry

install_helm_ubuntu:
	sudo snap install helm --classic

delete_project_artifacts: install_kubectl
	kubectl delete all -l app=explorecalifornia.com

install_app_helm:
	helm upgrade --atomic --install explore-california-website ./chart