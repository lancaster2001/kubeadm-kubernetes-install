note: This Repo is a copy from https://github.com/sculley/kubeadm-kubernetes-install#
      This is for personal use to prevent my own projects from failing in the event the original repo disappears.
# kubeadm-kubernetes-install

This repository contains a set of scripts to install a Kubernetes cluster using `kubeadm` on Ubuntu/Debian systems.

## Prerequisites

- A set of machines with Ubuntu or Debian installed on them.
- A user with `sudo` privileges on all machines.
- A network with a subnet that is routable from all machines.

## Usage

Clone this repository on all machines.

```bash
git clone https://github.com/lancaster2001/kubeadm-kubernetes-install.git
```

On the machine that will be the control-plane node run the following command:

```bash
./kubeadm-kubernetes-install/controlplane-install.sh <hostname> 1.24.0-00 192.168.0.0/16
```

Where `<hostname>` is the hostname of the machine, `1.24.0-00` is the version of Kubernetes to install and `192.168.0.0/16` is the subnet CIDR for the pod network. You only need to specify the Kubernetes version and pod network CIDR if you want to use a different Kubernetes version or CIDR than the default.

Print the join command on the controlplane node to be used with the `node-install.sh` script on the worker nodes

```bash
kubeadm token create --print-join-command
```

On the machines that will be worker nodes run the following command:

```bash
./kubeadm-kubernetes-install/node-install.sh <hostname> <controlplane_node_ip_port> <token> <root_ca_hash>
```

Where `<hostname>` is the hostname of the machine, `<controlplane_node_ip_port>` is the IP address and port of the control-plane node, `<token>` is the token generated in step 3, and `<root_ca_hash>` is the root CA hash generated in step 3.

Verify that the cluster is working by running the following command on the control-plane node:

```bash
sudo kubectl get nodes
```

NOTE: The `.kube/config` file is only available on the contro-plane node for the `root` user.

## License

Apache License 2.0, see [LICENSE](LICENSE).

## Author Information

This repository and scripts were created in 2023 by [Sam Culley](https:://github.com/sculley)
