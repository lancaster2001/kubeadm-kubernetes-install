#! /bin/env bash

# This script is used to install kubeadm, kubelet & kubectl on a control plane node.
# The container runtime used is containerd and the pod network used is Calico.
# This script is based on the official documentation at https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
# You need to run this script as root, and pass the hostname as the first argument.
# Optionally, you can pass the kubernetes version as the second argument. The default
# version is 1.24.0-00. You can also pass the pod network CIDR as the third argument.
# The default pod network CIDR is 192.168.0.0/16.

HOSTNAME=$1
KUBERNETES_VERSION=$2
POD_NETWORK_CIDR=$3

if [ -z "$HOSTNAME" ]; then
    echo "Usage: $0 <hostname> [kubernetes-version]"
    exit 1
fi

if [ -z "$KUBERNETES_VERSION" ]; then
    KUBERNETES_VERSION="1.24.0-00"
fi

if [ -z "$POD_NETWORK_CIDR" ]; then
    POD_NETWORK_CIDR="192.168.0.0/16"
fi

# Set hostname
hostnamectl set-hostname $HOSTNAME

# Add containerd modules
cat <<EOF > /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

# Load modules
modprobe overlay
modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF > /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sysctl --system

# Install containerd & configure
apt-get update && apt-get install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's|SystemdCgroup = false|SystemdCgroup = true|' /etc/containerd/config.toml
systemctl restart containerd

# Disable swap
swapoff -a

# Remove swap from fstab
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Install kubeadm, kubelet & kubectl
apt-get update && apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update
apt-get install -y kubelet=$KUBERNETES_VERSION kubeadm=$KUBERNETES_VERSION kubectl=$KUBERNETES_VERSION
apt-mark hold kubelet kubeadm kubectl

# Enable & start kubelet
systemctl enable kubelet
systemctl start kubelet

# Initialize kubeadm
kubeadm init --pod-network-cidr=$POD_NETWORK_CIDR --ignore-preflight-errors=all

# Setup kubectl for current user
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
