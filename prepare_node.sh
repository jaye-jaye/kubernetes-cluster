#!/bin/bash
set -e

# install docker
# yum install -y docker-ce-19.03.15-3.el7 containerd.io-1.3.7-3.1.el7

# stop firewall, SELINUX and swap
systemctl stop firewalld
systemctl disable firewalld
set +e && setenforce 0 && set -e
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
swapoff -a
sed -i 's/.*swap.*/#&/' /etc/fstab

# yum
cat << EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

yum install kubelet-1.23.4 kubeadm-1.23.4 kubectl-1.23.4 -y

# bridged traffic config
cat << EOF > /ets/modules-load.d/k8s.conf
br_netfilter
EOF

cat << EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl --system

# check docker cgroup config
cgroup_type=`docker info | grep 'Cgroup Driver' | awk '{print $3}'`
if [[ $cgroup_type != "systemd" ]]; then
    echo "Cgroup Driver muste be set to systemd!"
    echo "you can set cgroup driver to systemd in /etc/docker/daemon.json and restart dockerd"
    # {
    #     "exec-opts": ["native.cgroupdriver=systemd"]
    # }
    exit -1
fi

# prepare images
docker pull registry.aliyuncs.com/google_containers/kube-apiserver:v1.23.4
docker pull registry.aliyuncs.com/google_containers/kube-controller-manager:v1.23.4
docker pull registry.aliyuncs.com/google_containers/kube-scheduler:v1.23.4
docker pull registry.aliyuncs.com/google_containers/kube-proxy:v1.23.4
docker pull registry.aliyuncs.com/google_containers/pause:3.6
docker pull registry.aliyuncs.com/google_containers/etcd:3.5.1-0
docker pull registry.aliyuncs.com/google_containers/coredns:v1.8.6
docker tag registry.aliyuncs.com/google_containers/kube-apiserver:v1.23.4 k8s.gcr.io/kube-apiserver:v1.23.4
docker tag registry.aliyuncs.com/google_containers/kube-controller-manager:v1.23.4 k8s.gcr.io/kube-controller-manager:v1.23.4
docker tag registry.aliyuncs.com/google_containers/kube-scheduler:v1.23.4 k8s.gcr.io/kube-scheduler:v1.23.4
docker tag registry.aliyuncs.com/google_containers/kube-proxy:v1.23.4 k8s.gcr.io/kube-proxy:v1.23.4
docker tag registry.aliyuncs.com/google_containers/pause:3.6 k8s.gcr.io/pause:3.6
docker tag registry.aliyuncs.com/google_containers/etcd:3.5.1-0 k8s.gcr.io/etcd:3.5.1-0
docker tag registry.aliyuncs.com/google_containers/coredns:v1.8.6 k8s.gcr.io/coredns/coredns:v1.8.6