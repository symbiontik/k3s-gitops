## Overview

Deploy a local Kubernetes datacenter that features low maintenance, high security, and simple scalability.

To achieve these goals, the following methodologies will be utilized:

- [GitOps](https://www.weave.works/technologies/gitops/) with [Flux](https://fluxcd.io/docs/concepts/)
- Multi-node deployment with a light-weight OS, [k3os](https://k3os.io/)
- Multi-point encryption using [Mozilla SOPS](https://fluxcd.io/docs/guides/mozilla-sops/) & [Cert Manager](https://cert-manager.io/docs/)

## Architecture

![Architecture Diagram](/img/architecture_diagram.png)

## Prerequisites

In order to complete this guide, you will need the following:

- MacOS
- Visual Studio Code
- [Homebrew](https://brew.sh/)
- A GitHub Account
- A Cloudflare Account with a domain
- At least 2 PCs/VMs with at least 6GB RAM

## Deployment overview

This guide will walk you through the following steps:

1. Fork this repo
1. OS Installation
1. Connect to your Kubernetes cluster
1. Generate a Cloudflare API key
1. Configure SOPS
1. Configure Flux
1. Deploy some apps
1. (advanced) Add your own apps
1. (advanced) Automate K3OS updates
1. (advanced) Automate your app updates
1. (advanced) Visualize your repo
1. (advanced) Access your apps from anywhere
1. (advanced) Add SSO to your apps
1. (advanced) Integrate zero-trust security

### Fork this repo

In addition to this repository containing all the resources you will use throughout this guide, your GitHub repository will be the single source of truth for your Kubernetes infrastructure definitions. 

When new code is merged into your GitHub repository, Flux (which we will setup in a later step) will ensure your environment reflects the state of your GitHub repository. This is the essense of Infrastructure as code (IaC) - the practice of keeping all your infrastructure configuration stored as code. 

1. [Fork](https://docs.github.com/en/get-started/quickstart/fork-a-repo) the `k3s-gitops` repo into your own GitHub repo.

### OS Installation

k3OS is a stripped-down, streamlined, easy-to-maintain operating system for running Kubernetes nodes.

1. Download the respective ISO (within the latest release assets) in the [k3os repo](https://github.com/rancher/k3os/releases).
1. For dedicated PC users:
    1. Create a bootable USB stick from the ISO (search Google for options here).
1. For VM users:
    1. Mount the ISO to your VM.
1. Boot to the ISO on your respective device.
1. Select the "k3os Installer" option on the boot menu.
1. 
1. 
1. In your `k3os-gitops` repo, open the `/k3os/server-init.yaml` file.
1. 
1. 
1. Copy the contents of `kubeconfig.yaml` to your clipboard.
1. Create a file on your Mac with the same name `kubeconfig.yaml`, paste in the contents, then save the file.
1. 
1. On your router, add a static DHCP entry with your node's IP and MAC address (search Google with your unique router if you need help here).
1. Configure DNS on your nodes to use an upstream provider (e.g. `1.1.1.1`, `9.9.9.9`), or your router's IP if you have DNS configured there and it's not pointing to a local Ad-blocker DNS. Ad-blockers should only be used on devices with a web browser.
1. Set a static IP on the nodes OS itself and **NOT** by using DHCP. Using DHCP to assign IPs injects a search domain into your nodes `/etc/resolv.conf` and this could potentially break DNS in containers.
1. 
1. 
 
You now have 2 active Kubernetes nodes on your network that are ready for operation.

### Connect to your Kubernetes cluster

The majority of interaction with your Kubernetes cluster will occur from a remote development system - in this case, the same system where you cloned this repo.

1. Open the `kubeconfig.yaml` file you saved on your Mac in the previous section.
1. Replace _localhost_ in the line with `server: https://localhost:6443` with the IP address of your Kubernetes node (for example, `server: https://192.168.1.150:6443`) 
1. Copy the complete contents of `kubeconfig.yaml` to your clipboard.
1. On your Mac, open (or create) the file `/Users/YOURUSERNAME/.kube/config`
1. Paste the contents of `kubeconfig.yaml` into `/Users/YOURUSERNAME/.kube/config` and save the file.
1. Install `kubectl`
```sh
brew install kubectl
```
1. List your available Kubernetes nodes
```sh
kubectl get nodes
#NAME        STATUS     ROLES                  AGE    VERSION
#k3s-node2   NotReady   <none>                 109d   v1.21.1+k3s1
#k3s-node1   Ready      control-plane,master   115d   v1.21.1+k3s1
```

You are now able to securely access your Kubernetes cluster from your remote development system.

### Generate a Cloudflare API key

Cloudflare is used for several reasons: 
- Enables `cert-manager` to utilize the Cloudflare DNS challenge for automating TLS certificate creation in your Kubernetes cluster
- Enables accessibility of your apps from anywhere
- Secures access to your apps with Cloudflare Access 
- Provide DNS security, detailed traffic metrics, and logging with Cloudflare Gateway
- (optional) Provide you with an SSO portal for your apps
- (optional) Provide you with zero-trust security capabilities

1. Login to your Cloudflare account.
1. Create an API key by going to [this page](https://dash.cloudflare.com/profile/api-tokens) in your Cloudflare profile.
1. Copy the API key to your clipboard.
1. Paste your API key as the value for `BOOTSTRAP_CLOUDFLARE_APIKEY` in your `.config.sample.env` file, then save the file. 
1. [Generate Cloudflare API Key](https://github.com/k8s-at-home/template-cluster-k3s#cloud-global-cloudflare-api-key)

### Configure SOPS

Description

1. [Age and SOPS](https://github.com/k8s-at-home/template-cluster-k3s#closed_lock_with_key-setting-up-age)

### Configure Flux

Description

1. [GitOps with Flux](https://github.com/k8s-at-home/template-cluster-k3s#small_blue_diamond-gitops-with-flux)
1. [Flux initialization](https://fluxcd.io/docs/get-started/)
1. 
1. 
1. 

### Deploy some apps

Now that your infrastructure, security mechanisms, and deployment methodologies are in place - it's time to start deploying resources in your Kubernetes cluster! 

Kubernetes clusters are made up of many unique (and interchangeable) components and applications. These include technologies that facilitate networking segmentation, perform CI/CD operations, automate security operations, gather metrics, load balance services, and run your applications. The Kubernetes universe is [gigantic](https://landscape.cncf.io/).

These are the (well-known and robust) foundational apps that will be deployed with this repo:

- [flannel](https://github.com/flannel-io/flannel) - default CNI provided by k3s
- [local-path-provisioner](https://github.com/rancher/local-path-provisioner) - default storage class provided by k3s
- [flux](https://toolkit.fluxcd.io/) - GitOps tool for deploying manifests from the `cluster` directory
- [metallb](https://metallb.universe.tf/) - bare metal load balancer
- [cert-manager](https://cert-manager.io/) - SSL certificates - with Cloudflare DNS challenge
- [traefik](https://traefik.io) - ingress controller
- [system-upgrade-controller](https://github.com/rancher/system-upgrade-controller) - upgrade k3s
- [reloader](https://github.com/stakater/Reloader) - restart pod when configmap or secret changes
- [prometheus]()

Here are the front-end apps we will deploy that utilize these enabling technologies:

- [home-assistant]()
- [vs-code]()
- [grafana]()

1. Install Flux onto your Kubernetes cluster (you'll need to run this command twice due to Kubernetes race conditions):
```sh
kubectl --kubeconfig=./provision/kubeconfig apply --kustomize=./cluster/base/flux-system
# namespace/flux-system configured
# customresourcedefinition.apiextensions.k8s.io/alerts.notification.toolkit.fluxcd.io created
# ...
# unable to recognize "./cluster/base/flux-system": no matches for kind "Kustomization" in version "kustomize.toolkit.fluxcd.io/v1beta1"
# unable to recognize "./cluster/base/flux-system": no matches for kind "GitRepository" in version "source.toolkit.fluxcd.io/v1beta1"
# unable to recognize "./cluster/base/flux-system": no matches for kind "HelmRepository" in version "source.toolkit.fluxcd.io/v1beta1"
# unable to recognize "./cluster/base/flux-system": no matches for kind "HelmRepository" in version "source.toolkit.fluxcd.io/v1beta1"
# unable to recognize "./cluster/base/flux-system": no matches for kind "HelmRepository" in version "source.toolkit.fluxcd.io/v1beta1"
# unable to recognize "./cluster/base/flux-system": no matches for kind "HelmRepository" in version "source.toolkit.fluxcd.io/v1beta1"
```
1. Verify Flux components are running in the cluster

```sh
kubectl --kubeconfig=./provision/kubeconfig get pods -n flux-system
# NAME                                       READY   STATUS    RESTARTS   AGE
# helm-controller-5bbd94c75-89sb4            1/1     Running   0          1h
# kustomize-controller-7b67b6b77d-nqc67      1/1     Running   0          1h
# notification-controller-7c46575844-k4bvr   1/1     Running   0          1h
# source-controller-7d6875bcb4-zqw9f         1/1     Running   0          1h
```

Your Kubernetes cluster is now being managed by Flux; your Git repository is driving the state of your cluster!

### (advanced) Add your own apps

With this existing infrastructure in place, it's relatively simple to run your containerized apps in this cluster. In this guide, we'll deploy an app that can be easily installed and managed with a Helm chart.

1. In your `k3os-gitops` repo, navigate into your `/cluster/apps/home` directory:
```sh
cd /cluster/apps/home/
```
1. Create a new directory called `esphome` and navigate into that directory
```sh
mkdir esphome && cd esphome
```
1. Since this will be a stateful app, create a file `config-pvc.yaml`
```sh
touch config-pvc.yaml
```
1. 
1. 
1. 



Additional reading regarding container workload types:
- [Stateless vs Stateful apps on Kubernetes](https://www.weka.io/blog/stateless-vs-stateful-kubernetes/)
- [Should I run a database on Kubernetes?](https://cloud.google.com/blog/products/databases/to-run-or-not-to-run-a-database-on-kubernetes-what-to-consider)

### (advanced) Automate K3OS updates

Description

1. [Automatic Upgrades](https://rancher.com/docs/k3s/latest/en/upgrades/automated/)

### (advanced) Automate your app updates

Description

1. [RenovateBot](https://github.com/renovatebot/github-action)

### (advanced) Visualize your repo

Description

1. [Repo Visualizer](https://github.com/githubocto/repo-visualizer)
1. [Repo Visualizer Blog](https://next.github.com/projects/repo-visualization)

### (advanced) Access your apps from anywhere

Description

1. [Cloudflare DNS]()

### (advanced) Add SSO to your apps

Single-Sign-On (SSO) provides a simplified, one-time login experience for your users as well as fine-grained access control into which users have access to which apps.

1. [Cloudflare Access]()
1. [Cloudflare App Launcher]()

### (advanced) Integrate zero-trust security

Integrating zero-trust security principles gives you the best of both worlds: simplified, one-time login access for your users and fine-tuned security  

1. [Multifactor Authentication]()
1. [Cloudflare Access Policies]()
1. [Cloudflare Gateway]()

## Gratitude

I have major appreciation for the people and organizations of the open-source community. This project was a result of the inspiration provided by these wonderful folks:

- [Awesome Home Kubernetes Collection](https://github.com/k8s-at-home/awesome-home-kubernetes)
- [Flux](https://github.com/fluxcd/flux2)
- [RenovateBot](https://github.com/renovatebot/github-action)
- [Template-cluster-k3s](https://github.com/k8s-at-home/template-cluster-k3s)
- [HomeOps](https://github.com/onedr0p/home-ops)
