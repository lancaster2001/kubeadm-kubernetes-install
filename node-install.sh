#! /bin/env bash

# This script is used to install kubeadm, kubelet & kubectl on a worker node.
# The container runtime used is containerd. This script is based on the official
# documentation at https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
# You need to run this script as root, and pass the hostname as the first argument.
# You also need to pass the control plane IP address as the second argument, and the
# token as the third argument the last argument needs to be the token ca hash.
# You can get these values from the output of the kubeadm init command on the control
#
# Example usage: ./node-install.sh node1 172.31.123.141:6443 la9llk.e3aevaq58tsqyhpf sha256:b01c5723f2d7217c4089f2876570f86cbd364cf6c3a438d503772b47d03225ee

HOSTNAME=$1
CONTROL_PLANE_IP_PORT=$2
TOKEN=$3
TOKEN_CA_HASH=$4

if [ -z "$HOSTNAME" ]; then
    echo "Usage: $0 <hostname> <control-plane-ip> <token> <token-ca-hash>"
    exit 1
fi

if [ -z $CONTROL_PLANE_IP ]; then
    echo "Usage: $0 <hostname> <control-plane-ip> <token> <token-ca-hash>"
    exit 1
fi

if [ -z $TOKEN ]; then
    echo "Usage: $0 <hostname> <control-plane-ip> <token> <token-ca-hash>"
    exit 1
fi

if [ -z $TOKEN_CA_HASH ]; then
    echo "Usage: $0 <hostname> <control-plane-ip> <token> <token-ca-hash>"
    exit 1
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

# Join the node to the cluster
kubeadm join $CONTROL_PLANE_IP_PORT --token $TOKEN --discovery-token-ca-cert-hash $TOKEN_CA_HASH