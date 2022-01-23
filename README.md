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
- At least 1 PCs/VMs with at least 6GB RAM

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

1. Download the respective ISO (within the latest release assets) in the [k3OS repo](https://github.com/rancher/k3os/releases).
1. For dedicated PC users:
    1. Create a bootable USB stick from the ISO (search Google for options here).
1. For VM users:
    1. Mount the ISO to your VM.
1. Boot to the ISO on your respective device.
1. Select the "k3OS LiveCD and Installer" option on the boot menu.
1. Login with `rancher/rancher`
1. Run `lsblk` to identify your desired destination drive for k3OS.
```sh
lsblk
#NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
#loop1    7:1    0  47.1M  1 loop /usr
#loop2    7:2    0 302.2M  0 loop /usr/src
#sda      8:0    0 238.5G  0 disk 
#├─sda1   8:1    0    47M  0 part 
#└─sda2   8:2    0 238.4G  0 part /var/lib/kubelet/pods/2d4b1a97-6659-436d-abb1-
#sdb      8:16    0   7.6G  0 disk 
#├─sdb1   8:17    0   190K  0 part 
#└─sdb2   8:18    0   2.8M  0 part 
#├─sdb3   8:19    0 513.5M  0 part /k3os/system
#└─sdb4   8:20    0   300K  0 part
```
1. Begin the installation process.
```sh
sudo k3os install
```
1. Choose to install to disk.
```log
Running k3OS configuration
Choose operation
1. Install to disk
2. Configure server or agent
Select Number [1]:
```
1. Choose the desired destination drive you identified earlier.
```log
Installation target. Device will be formatted
1. sda
2. sdb
Select Number [0]: 1
```
1. Choose NOT to configure the system with `cloud-init`.
```log
Config system with cloud-init file? [y/N]: N
```
1. Choose NOT to authorize GitHub users for SSH.
```log
Authorize GitHub users to SSH [y/N]: N
```
1. Choose to keep the default password for the `rancher` account (feel free to change it later).
```log
Please enter password for [rancher]:
Confirm password for [rancher]:
```
1. Choose NOT to configure WiFi (WiFi does not support manual static IP assignment, which is necessary for a later step).
```log
Configure WiFi? [y/N]: N
```
1. Choose to run your node as a server.
```log
Run as a server or agent?
1. server
2. agent
Select Number [1]:
```
1. Set your cluster secret/token as `cluster-secret` (this can be changed later as desired).
```log
Token or cluster secret (optional): cluster-secret
```
1. Confirm your configuration details and enter `y` to continue.
```log
Configuration
_____________
device: /dev/sda
Your disk will be formatted and k3OS will be installed with the above configuration.
Continue? [y/N]: y
```
**Note:** If you receive install errors using the LiveCD option, reboot and proceed with the same options using the "k3OS installer" option instead of the "k3OS LiveCD & Installer" option.
1. After the system completes the installation and reboots, select the `k3OS Current` bootloader option (or just wait a few moments and it will boot it by default).
1. Login to your new K3OS installation as `rancher` with the password `rancher`
1. Set a static IP on the nodes OS itself and NOT by using DHCP. Using DHCP to assign IPs injects a search domain into your nodes `/etc/resolv.conf` and this could potentially break DNS in containers. (If you already have a DHCP address assigned, remove any `search domain.com` lines from `/etc/resolv.conf` and save the file).
    1. First, identify the `connman` service bound to `eth0`
    ```sh
    sudo connmanctl services
    # *AO Wired                ethernet_84470907c635_cable
    ```
    1. View the details of your connection.
    ```sh
    sudo connmanctl services ethernet_84470907c635_cable
    ```
    1. Set a static IP address and DNS nameserver for your connection.
    ```sh
    sudo connmanctl config ethernet_84470907c635_cable --ipv4 manual 192.168.1.151 255.255.255.0 192.168.1.1 --nameservers 192.168.1.1
    ```
1. By default, k3OS allows SSH connections only using certificates. This is a much safer method than using passwords, however, for the sake of simplicity in this guide, we will set `PasswordAuthentication` to yes. Feel free to come back later and lock this down.
    1. Open the SSHD configuration file
    ```sh
    sudo vim /etc/ssh/sshd_config
    ```
    1. Change the value of `PasswordAuthentication` from `no` to `yes` and save this file.
    1. Restart the `sshd` service.
    ```sh
    sudo service sshd restart
    ```
1. Log out of the console and grab your Mac.
```sh
exit
```

You now have a k3OS server node ready for remote configuration.

### Connect to your Kubernetes cluster

The majority of interaction with your Kubernetes cluster will occur from a remote development system - in this case, the Mac where you cloned this repo.

1. Connect to your new k3os node via SSH.
```log
ssh rancher@192.168.1.183
The authenticity of host '192.168.1.183 (192.168.1.183)' can't be established.
ECDSA key fingerprint is SHA256:/KPEdx6D56R9/ByhJr/4gGSP7DJdtkFun+fFgCtdl/Q.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.1.183' (ECDSA) to the list of known hosts.
rancher@192.168.1.183's password: rancher

Welcome to k3OS!
...
```
1. In your `k3os-gitops` repo, copy the contents of `/k3os/node-config.yaml` to your clipboard.
1. On your k3os node, create a new file called `config.yaml` in the `/var/lib/rancher/k3os/` directory.
```sh
sudo vim /var/lib/rancher/k3os/config.yaml
```
1. Paste your clipboard contents in and save the file.
1. In k3OS, the `/etc` automatically reverts any changes after reboot. Therefore, to persistently change Hostname of k3OS machine, we have to change it in k3OS configuration files. 
    1. ```sh
       sudo vim /var/lib/rancher/k3os/hostname
       ```
    1. Replace the current contents with your desired hostname and save the file.
1. Reboot your system for the system modules and hostname changes to take effect.
```sh
sudo reboot
```
1. On your Mac terminal, retrieve the kube config file from your k3OS node.
```sh
scp rancher@192.168.1.151:/etc/rancher/k3s/k3s.yaml .
#rancher@192.168.1.151's password: 
```
1. Open the `k3s.yaml` file you downloaded on your Mac.
1. Replace _127.0.0.1_ in the line with `server: https://127.0.0.1:6443` with the IP address of your Kubernetes node (for example, `server: https://192.168.1.151:6443`) 
1. Copy the complete contents of `k3s.yaml` to your clipboard.
1. On your Mac, open (or create) the file `/Users/YOURUSERNAME/.kube/config`
1. Paste the contents of `k3s.yaml` into `/Users/YOURUSERNAME/.kube/config` and save the file.
1. Install `kubectl`.
```sh
brew install kubectl
```
1. Use `kubectl` to list your available Kubernetes nodes
```sh
kubectl get nodes
#NAME        STATUS   ROLES                  AGE   VERSION
#k3s-node2   Ready    control-plane,master   23h   v1.22.2+k3s2
```

You are now able to securely access your active Kubernetes node from your remote development system.

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

- Reference: [Generate Cloudflare API Key](https://github.com/k8s-at-home/template-cluster-k3s#cloud-global-cloudflare-api-key)

### Configure Secrets Encryption

Secrets encryption allows you to safely store secrets in a public or private Git repository. To accomplish this, Age is a tool that will encrypt your YAML files and/or secrets using Mozilla SOPS (Secrets Operations) encryption. In a later step, you will configure Flux with this SOPs encryption key - this will allow your Kubernetes cluster to decrypt and utilize those secrets for operations.

1. Begin by installing `age`
```sh
brew install age
```
1. Create a Age Private / Public Key
```sh
age-keygen -o age.agekey
```
1. Set up the directory for the Age key and move the Age file to it
```sh
mkdir -p ~/.config/sops/age
mv age.agekey ~/.config/sops/age/keys.txt
```
1. Fill out the `age` public key in the `.config.sample.env` under `BOOTSTRAP_AGE_PUBLIC_KEY`.
**Note:** The public key should start with `age`...

Your environment is now prepared for encrypting all secrets in your cluster.

### Prepare for deployment

1. On your terminal, change directory to the root level of your Git repository then set the `PROJECT_DIR` environment variable.
```sh
export PROJECT_DIR=$(git rev-parse --show-toplevel)
```
1. Set the `SOPS_AGE_KEY_FILE` environment variable.
```sh
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
```
1. Edit your `.config.sample.env` file to include all your respective unique values, then save the file.
1. Copy all the completed contents from this file and run it in your terminal to set these environmental variables.
1. Create your unique, encrypted deployment files using 
```sh
        # sops configuration file
        envsubst < "${PROJECT_DIR}/tmpl/.sops.yaml" \
            > "${PROJECT_DIR}/.sops.yaml"
        # cluster
        envsubst < "${PROJECT_DIR}/tmpl/cluster/cluster-settings.yaml" \
            > "${PROJECT_DIR}/cluster/base/cluster-settings.yaml"
        envsubst < "${PROJECT_DIR}/tmpl/cluster/gotk-sync.yaml" \
            > "${PROJECT_DIR}/cluster/base/flux-system/gotk-sync.yaml"
        envsubst < "${PROJECT_DIR}/tmpl/cluster/cluster-secrets.sops.yaml" \
            > "${PROJECT_DIR}/cluster/base/cluster-secrets.sops.yaml"
        envsubst < "${PROJECT_DIR}/tmpl/cluster/cert-manager-secret.sops.yaml" \
            > "${PROJECT_DIR}/cluster/core/cert-manager/secret.sops.yaml"
        sops --encrypt --in-place "${PROJECT_DIR}/cluster/base/cluster-secrets.sops.yaml"
        sops --encrypt --in-place "${PROJECT_DIR}/cluster/core/cert-manager/secret.sops.yaml"
```
1. Since `.config.sample.env` contains so many sensitive values, either add this to your `.gitignore` or delete the file so you do not commit it to your public GitHub repository.
1. Sync your completed project to your public GitHub repository.
```sh
git add .
git commit -m "add encrypted deployment files"
git push
```


### Configure Flux

Flux is the essential GitOps enablement component that keeps your Kubernetes cluster in sync with your GitHub repository. Once your Flux instance is bootstrapped, it will begin driving the state of your Kubernetes cluster. In order to update or make changes to your cluster, it is recommended to create merge requests for your GitHub repository - this grants you a simple rollback method, change logging, and single point of change for your environment.

1. Begin by installing flux.
```sh
brew install fluxcd/tap/flux
```
1. Verify Flux can be installed
```sh
flux --kubeconfig=./provision/kubeconfig check --pre
# ► checking prerequisites
# ✔ kubectl 1.21.5 >=1.18.0-0
# ✔ Kubernetes 1.21.5+k3s1 >=1.16.0-0
# ✔ prerequisites checks passed
```
1. Pre-create the `flux-system` namespace
```sh
kubectl --kubeconfig=./provision/kubeconfig create namespace flux-system --dry-run=client -o yaml | kubectl --kubeconfig=./provision/kubeconfig apply -f -
```
1. Add the Age key in-order for Flux to decrypt SOPS secrets
```sh
cat ~/.config/sops/age/keys.txt |
    kubectl --kubeconfig=./provision/kubeconfig \
    -n flux-system create secret generic sops-age \
    --from-file=age.agekey=/dev/stdin
```
**Note:** Variables defined in `./cluster/base/cluster-secrets.sops.yaml` and `./cluster/base/cluster-settings.yaml` will be usable anywhere in your YAML manifests under `./cluster`
1. Verify the `./cluster/base/cluster-secrets.sops.yaml` and `./cluster/core/cert-manager/secret.sops.yaml` files are encrypted with SOPS
1. If you verified all the secrets are encrypted, you can delete the `tmpl` directory now
1. Push your changes to git
```sh
git add -A
git commit -m "initial commit"
git push
```
1. Install Flux
**Note:** Due to race conditions with the Flux CRDs you will have to run the below command twice. There should be no errors after your second run.
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

- Reference: [GitOps with Flux](https://github.com/k8s-at-home/template-cluster-k3s#small_blue_diamond-gitops-with-flux)
- Reference: [Flux initialization](https://fluxcd.io/docs/get-started/)

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
