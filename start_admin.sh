kubeadm init --kubernetes-version 'v1.23.4' --pod-network-cidr=10.244.0.0/16
# setup network, refs: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network
# https://github.com/flannel-io/flannel#deploying-flannel-manually
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml