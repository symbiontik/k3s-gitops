## Overview

Deploy a local Kubernetes datacenter that features low maintenance, high security, and simple scalability.

To achieve these goals, the following methodologies will be utilized:

- [GitOps](https://www.weave.works/technologies/gitops/) with [Flux](https://fluxcd.io/docs/concepts/) & [Terraform Cloud](https://cloud.hashicorp.com/products/terraform)
- Bare metal Kubernetes deployment with [k3os](https://k3os.io/)
- Multi-layer encryption using [SOPs](https://fluxcd.io/docs/guides/mozilla-sops/) & [Cert Manager](https://cert-manager.io/docs/)
- [Zero Trust security](https://www.cloudflare.com/learning/security/glossary/what-is-zero-trust/) with [Cloudflare](https://www.cloudflare.com/what-is-cloudflare/) & [2FA](https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa/configuring-two-factor-authentication)
- Automated system updates with [Renovate](https://www.whitesourcesoftware.com/free-developer-tools/renovate/) & [System Upgrade Controller](https://rancher.com/docs/k3s/latest/en/upgrades/automated/)

## Diagrams

![GitOps Workflow](/img/gitops_workflow.png)

![Architecture Diagram](/img/architecture_diagram.png)

![Repository Structure Diagram](/img/respository_diagram.svg)

## Prerequisites

In order to complete this guide, you will need the following:

- MacOS or Linux
- Visual Studio Code
- [Homebrew](https://brew.sh/)
- A GitHub Account
- A Cloudflare Account with a domain
- A Terraform Cloud Account
- A PC/VM with at least 4GB RAM

## Deployment overview

This guide will walk you through the following steps:

1. Fork this repo
1. OS Installation
1. Connect to your Kubernetes cluster
1. Generate a Cloudflare API key
1. Configure secrets encryption
1. Prepare for deployment
1. Configure Flux
1. Deploy some apps
1. Add your own apps
1. Automate k3s updates
1. Automate your app updates
1. Automate external resource creation
1. Access your apps from anywhere
1. Integrate Zero Trust security
1. Add SSO to your apps
1. Visualize your repo

**Note**: In order to stay focused on secure GitOps practices, these practices will not be covered within this guide:

- High availability for networking, storage, and Kubernetes components
- Hosted/Cloud deployments
- Load balancing
- Automated secrets management
- Disaster recovery

### Fork this repo

In addition to this repository containing all the resources you will use throughout this guide, your GitHub repository will be the single source of truth for your Kubernetes & Cloudflare infrastructure definitions. 

When new code is merged into your GitHub repository, Flux (which we will setup in a later step) will ensure your environment reflects the state of your GitHub repository. This is the essense of Infrastructure as code (IaC) - the practice of keeping all your infrastructure configuration stored as code. 

1. [Fork](https://docs.github.com/en/get-started/quickstart/fork-a-repo) this `k3s-gitops` repo into your own GitHub repo.

### OS Installation

k3OS is a stripped-down, streamlined, easy-to-maintain operating system for running Kubernetes nodes.

1. Download the respective ISO (within the latest release assets) in the [k3OS repo](https://github.com/rancher/k3os/releases).
1. For dedicated PC users:
    1. Create a bootable USB stick from the ISO with [balenaEtcher](https://www.balena.io/etcher/).
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

1. By default, k3OS allows SSH connections only using certificates. This is a much safer method than using passwords, however, for the sake of simplicity in this guide, set `PasswordAuthentication` to yes. Feel free to come back later and lock this down.

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

    1. Edit the k3OS hostname file.

    ```sh
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

Cloudflare is used throughout this guide for several reasons: 

- Enables `cert-manager` to utilize the Cloudflare DNS challenge for automating TLS certificate creation in your Kubernetes cluster
- Enables accessibility of your apps from anywhere
- Secures access to your apps with Cloudflare Access 
- Provides DNS security, detailed traffic metrics, and logging with Cloudflare Gateway
- Provides you with Zero Trust security capabilities
- Provides you with an single-sign-on (SSO) portal for your apps

1. Login to your [Cloudflare account](https://dash.cloudflare.com/login).

1. Create an API key by going to [this page](https://dash.cloudflare.com/profile/api-tokens) in your Cloudflare profile.

1. Copy the API key to your clipboard.

1. Paste your API key as the value for `BOOTSTRAP_CLOUDFLARE_APIKEY` in your `.config.sample.env` file, then save the file. 

- Reference: [Generate Cloudflare API Key](https://github.com/k8s-at-home/template-cluster-k3s#cloud-global-cloudflare-api-key)

You now have a Cloudflare API key that will enable you to programatically create Cloudflare and encryption resources with ease.

### Configure Secrets Encryption

Secrets encryption allows you to safely store secrets in a public or private Git repository. To accomplish this, [Age](https://github.com/FiloSottile/age) is a tool that will encrypt your YAML files and/or secrets using Mozilla SOPs (Secrets Operations) encryption. In a later step, you will configure Flux with this SOPs encryption key - this will allow your Kubernetes cluster to decrypt and utilize those secrets for operations.

1. Begin by installing `age`.

```sh
brew install age
```

1. Create a Age Private / Public Key.

```sh
age-keygen -o age.agekey
```

1. TODO: Create another Age Private / Public Key (for Disaster Recovery purposes) OR just create another Public Key?
    1. Reference: https://github.com/FiloSottile/age#multiple-recipients
    1. Reference: https://github.com/mozilla/sops#5encryption-protocol 

1. Set up the directory for the Age key and move the Age file to it.

```sh
mkdir -p ~/.config/sops/age
mv age.agekey ~/.config/sops/age/keys.txt
```

1. Fill out the `age` public key in the `.config.sample.env` under `BOOTSTRAP_AGE_PUBLIC_KEY`.

**Note:** The public key should start with `age`...

1. 

1. TODO: To provide HA for key management and secret rotation, investigate using:
    1. Environment variables in Terraform Cloud (SOPS provider with env variable)
    1. Hashicorp Vault pod with `sops --hc-vault-transit`
    1. `sops --keyservice`

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

1. Create your unique, encrypted deployment files:

```sh
        # create sops configuration file
        envsubst < "${PROJECT_DIR}/tmpl/.sops.yaml" \
            > "${PROJECT_DIR}/.sops.yaml"
        # create unique cluster resources
        envsubst < "${PROJECT_DIR}/tmpl/cluster/cluster-settings.yaml" \
            > "${PROJECT_DIR}/cluster/base/cluster-settings.yaml"
        envsubst < "${PROJECT_DIR}/tmpl/cluster/gotk-sync.yaml" \
            > "${PROJECT_DIR}/cluster/base/flux-system/gotk-sync.yaml"
        envsubst < "${PROJECT_DIR}/tmpl/cluster/cluster-secrets.sops.yaml" \
            > "${PROJECT_DIR}/cluster/base/cluster-secrets.sops.yaml"
        envsubst < "${PROJECT_DIR}/tmpl/cluster/cert-manager-secret.sops.yaml" \
            > "${PROJECT_DIR}/cluster/core/cert-manager/secret.sops.yaml"
        # encrypt sensitive files
        sops --encrypt --in-place "${PROJECT_DIR}/cluster/base/cluster-secrets.sops.yaml"
        sops --encrypt --in-place "${PROJECT_DIR}/cluster/core/cert-manager/secret.sops.yaml"
```

**Note**: Variables defined in `./cluster/base/cluster-secrets.sops.yaml` and `./cluster/base/cluster-settings.yaml` will be usable anywhere in your YAML manifests under `./cluster`. This gives you a central location to define and encrypt variables for your applications/infrastructure.

1. Verify the `./cluster/base/cluster-secrets.sops.yaml` and `./cluster/core/cert-manager/secret.sops.yaml` files are encrypted with SOPs.

1. If you verified all the secrets are encrypted, you can delete the `tmpl` directory now.

1. Since `.config.sample.env` contains so many sensitive values, be sure to either add this to your `.gitignore` or delete the file so you DO NOT commit it to your public GitHub repository.

1. Sync your completed project to your public GitHub repository.

```sh
git add .
git commit -m "add encrypted deployment files"
git push
```

Your local terminal and GitHub repository are now ready to initialize Flux.

### Configure Flux

Flux is the essential GitOps enablement component that keeps your Kubernetes cluster in sync with your GitHub repository. Once your Flux instance is bootstrapped, it will begin driving the state of your Kubernetes cluster. In order to update or make changes to your cluster, it is recommended to create merge requests for your GitHub repository - this grants you a simple rollback method, change logging, and single point of change for your environment.

1. Begin by installing Flux on your Mac.

```sh
brew install fluxcd/tap/flux
```

1. Verify Flux can be installed on your cluster.

```sh
flux check --pre
#► checking prerequisites
#✔ kubectl 1.21.3 >=1.18.0-0
#✔ Kubernetes 1.22.2+k3s2 >=1.16.0-0
#✔ prerequisites checks passed
```

1. Pre-create the `flux-system` namespace.

```sh
kubectl create namespace flux-system --dry-run=client -o yaml | kubectl apply -f -
# namespace/flux-system created
```

1. Add the Age key in order for Flux to decrypt SOPs secrets.

```sh
cat ~/.config/sops/age/keys.txt |
kubectl -n flux-system create secret generic sops-age \
--from-file=age.agekey=/dev/stdin
# secret/sops-age created
```

Your Kubernetes cluster is now ready to begin sycning with your GitHub repo to deploy apps with Flux.

### Deploy some apps

Now that your infrastructure, security mechanisms, and deployment methodologies are in place - it's time to start deploying resources in your Kubernetes cluster! 

Kubernetes clusters are made up of many unique (and interchangeable) components and applications. These include technologies that facilitate networking segmentation, perform CI/CD operations, automate security operations, gather metrics, load balance services, and run your applications. The Kubernetes universe is [gigantic](https://landscape.cncf.io/).

These are the components (organized by namespace) that will be deployed with this repo:

1. apps
    1. [home-assistant](https://github.com/home-assistant/core) - Highly extensible home automation platform 
    1. [vs-code](https://github.com/coder/code-server) - Browser-based Visual Studio Code instance for editing home-assistant configuration
    1. [influxdb](https://github.com/influxdata/influxdb) - Persistent time-series database for home-assistant data
1. core
    1. [cert-manager](https://github.com/jetstack/cert-manager) - Automatically provisions and manages TLS certificates in Kubernetes
    1. [metrics-server](https://github.com/kubernetes-sigs/metrics-server) - Exports container resource metrics
    1. [system-upgrade-controller](https://github.com/rancher/system-upgrade-controller) - Automated Kubernetes node upgrader
1. flux-system
    1. [flux](https://github.com/fluxcd/flux2) - GitOps toolkit for deploying manifests from the `cluster` directory
1. networking
    1. [metallb](https://github.com/metallb/metallb) - Bare metal network load balancer
    1. [traefik](https://github.com/traefik/traefik) - Network ingress controller
1. observability
    1. [prometheus](https://github.com/prometheus/prometheus) - System and service metric collector
    1. [grafana](https://github.com/grafana/grafana) - Metric and data visualization platform
    1. [node-exporter](https://github.com/prometheus/node_exporter) - Exports node metrics

1. Initialize Flux on your Kubernetes cluster.

**Note**: Due to race conditions with the Flux CRDs you will have to run the below command twice. There should be no errors after your second run.

```sh
kubectl apply --kustomize=./cluster/base/flux-system
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

1. Verify Flux components are running in the cluster.

```sh
kubectl get pods -n flux-system
# NAME                                       READY   STATUS    RESTARTS   AGE
# helm-controller-5bbd94c75-89sb4            1/1     Running   0          1h
# kustomize-controller-7b67b6b77d-nqc67      1/1     Running   0          1h
# notification-controller-7c46575844-k4bvr   1/1     Running   0          1h
# source-controller-7d6875bcb4-zqw9f         1/1     Running   0          1h
```

1. Verify Flux is successfully syncing with your GitHub repository.

```sh
flux get sources git
#NAME                  READY   MESSAGE                        REVISION          SUSPENDED 
#traefik-crd-source    True    Fetched rev: v10.3.4/d9abd..   v10.3.4/d9abd9f.. False    
#flux-system           True    Fetched rev: main/d452..       main/d4521a..     False 
```

1. Verify status of your Kustomization deployments.

```sh
kubectl get kustomization -A
#NAMESPACE     NAME            READY   STATUS                                                               AGE
#flux-system   traefik-crds    True    Applied revision: v10.9.1/5d97a2e30076302950c31fc9a98f267bdd624fe8   12m
#flux-system   observability   True    Applied revision: main/ada165d6beee093726613a7818c950e0c31f5e21      39m
#flux-system   networking      True    Applied revision: main/ada165d6beee093726613a7818c950e0c31f5e21      39m
#...
```

1. Verify status of your Helm Chart deployments.

```sh
flux get helmrelease -A
#NAMESPACE       NAME                    READY   MESSAGE                                 REVISION        SUSPENDED 
#cert-manager    cert-manager            True    Release reconciliation succeeded        v1.5.3          False    
#metallb  metallb                 True    Release reconciliation succeeded        0.10.2          False       
#apps            home-assistant          True    Release reconciliation succeeded        11.0.3          False    
#...
```

**Note**: Flux will check your GitHub repository for changes every 60 seconds. You can change this value in your `/base/flux-system/gotk-sync.yaml` file if desired.

Your Kubernetes cluster is now being managed by Flux - your Git repository is driving the state of your cluster!

### Automate K3S updates

System Upgrade Controller automates the upgrade process for your Kubernetes nodes. This is a Kubernetes-native approach to cluster upgrades. It leverages a custom resource definition (CRD), a plan, and a controller that schedules upgrades based on your configured plans.

1. Navigate to the `/cluster/core/system-upgrade-controller` directory.

1. Inspect the `server-plan.yaml` file.

1. Notice these lines:

```log
  version: v1.23.1+k3s2
  #channel: https://update.k3s.io/v1-release/channels/stable
```

1. You have the choice of either manually defining the desired k3s version OR continuously monitoring the stable release channel. Choose what makes the most sense for your desired upgrade plan.

You now have an automated upgrade process for k3s that will begin as soon as the controller detects that a plan was created. Updating your plan will cause the controller to re-evaluate the plan and determine if another upgrade is needed.

### Automate your app updates

Renovate is a bot that watches the contents of your repository looking for dependency updates and automatically creates pull requests when updates are found. When you merge these PRs, Flux will automatically apply the changes to your cluster. 

Renovate runs via a scheduled Github Action workflow; GitHub Actions are used to automate, customize, and execute your software development workflows directly in your repository, similarly to how Flux does this for your Kubernetes cluster.

1. Navigate to the root of your `k3os-gitops` repository.

1. Copy the file `/extras/github-actions/renovate.yaml` to your `.github/workflows` directory.

```sh
cp /extras/github-actions/renovate.yaml .github/workflows/renovate.yaml
```

1. Push the changes to your GitHub repository. 

```sh
git add .
git commit -m "add github action - renovate bot"
git push
```

You now have an automated bot that will compare your cluster's application versions against the latest versions every 12 hours. Renovate bot will generate a pull request for you to review and merge whenever new versions are found.

### Automate external resource creation

Terraform Cloud is an infrastructure-as-code tool that allows you to easily create external resources for Cloudflare and hundreds of other cloud services. Rather than manage a consistent state in each cloud service UI, Terraform allows you to define and manage these resources in your GitHub repository. This enables you to stay consistent with the philosophy of GitOps and streamline your CI/CD workflow.

1. Login to Terraform Cloud.

1. Create a new Workspace.
    1. Choose `Version control workflow`.
    1. Connect your GitHub account.
    1. Choose your `k3s-gitops` repository.
    1. Set your workspace name as `Cloudflare`.
    1. Finish creating the workspace.

1. Within your workspace, go to Settings > General.

1. Change your Terraform Working Directory to `terraform/cloudflare/`

1. With your workspace, create these Variables with their respective values:
    1. Key:`BOOTSTRAP_CLOUDFLARE_EMAIL`
    1. Value: `your_cloudflare_email`
    1. Category: `terraform`
    1. Sensitive: `Yes`
    1. Key: `BOOTSTRAP_CLOUDFLARE_APIKEY`
    1. Value: `your_cloudflare_api_key`
    1. Category: `terraform`
    1. Sensitive: `Yes`
    1. Key: `BOOTSTRAP_CLOUDFLARE_DOMAIN`
    1. Value: `your_cloudflare_domain`
    1. Category: `terraform`
    1. Sensitive: `Yes`
    1. Key: `PUBLIC_IP_ADDRESS`
    1. Value: `your_public_ip_address`
    1. Category: `terraform`
    1. Sensitive: `Yes`

1. TODO: Test the `SOPS_AGE_KEY` pattern here, then add if it works correctly 
    1. Reference: https://registry.terraform.io/providers/carlpett/sops/latest/docs/data-sources/external
    1. Github issue and PR: https://www.giters.com/carlpett/terraform-provider-sops/issues/80 

1. TODO: Add environment variable `YOUR_PUBLIC_IP_ADDRESS` to TF Cloud.

1. Run initial plan.

1. Review and verify the contents of the plan.

```log
some output
```

1. Click "Apply" to run Terraform.

1. 

1. Choose to automatically run and apply Terraform when your GitHub repo changes. 

1. 

Your Terraform Cloud workspace will now continuously monitor your GitHub repository for changes and automatically create any respective resources in your Cloudflare account.

### Access your apps from anywhere

A public DNS service grants you the ability to access your apps from anywhere in the world. Cloudflare provides this service as well as many advanced security related features that come at no additional cost.

Rather than utilize the Cloudflare web UI, a much more manageable and scalable pattern is to leverage [Terraform](https://www.terraform.io/) (an infrastructure-as-code tool) for Cloudflare resource management. Once this is initialized, you should use Terraform as the authoritative management platform for your Cloudflare resources so they do not fall out of sync.

1. Begin by importing your current Cloudflare state into Terraform files.

    1. Navigate to the `/extras/terraform/cloudflare-import` directory.

    1. Install the necessary packages.

    ```sh
    brew install terraform
    brew tap cloudflare/cloudflare
    brew install --cask cloudflare/cloudflare/cf-terraforming
    ```

    1. Set your environmental variables.

    ```sh
    export CLOUDFLARE_EMAIL='user@example.com'
    export CLOUDFLARE_API_KEY='1150bed3f45247b99f7db9696fffa17cbx9'
    export CLOUDFLARE_ZONE_ID='4c8964bacd8821df5315e5c0bf4eee50'
    ```

    1. Generate Terraform files from your Cloudflare DNS records.

    ```sh
    cf-terraforming generate \
    --resource-type "cloudflare_record" \
    --email $CLOUDFLARE_EMAIL \
    --key $CLOUDFLARE_API_KEY \
    --zone $CLOUDFLARE_ZONE_ID \
    > records.tf
    ```

1. Copy the `records.tf` file to your `/extras/terraform/cloudflare-dns` directory.

1. 

1. Navigate to the `/extras/terraform/cloudflare-dns` directory.

1. 

1. TODO: See if there's a `traefik` or Kubernetes service Terraform provider that could dynamically add values to the Terraform files, rather than hard-cording service `name`. Another idea is to grep for the first part of these entries throughout the repo:

```yaml
tls:
          - hosts:
              - hass.${SECRET_DOMAIN}
```
```log
resource "cloudflare_record" "traefik" {
  name    = "traefik"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = "ipv4.${var.BOOTSTRAP_CLOUDFLARE_EMAIL}"
  proxied = true
  type    = "CNAME"
  ttl     = 1
}
```

1. 

1. On your local router, configure port forwarding for port `443` to your Traefik Ingress IP (whatever IP you set for `BOOTSTRAP_METALLB_TRAEFIK_ADDR`).

1. 


- Reference: [Cloudflare DNS](https://www.cloudflare.com/dns/)
- Reference: [cf-terraforming repo](https://github.com/cloudflare/cf-terraforming)
- Reference: [Import Cloudflare resources to Terraform](https://developers.cloudflare.com/terraform/advanced-topics/import-cloudflare-resources)
- Reference: [Terraform provider for Cloudflare DNS Records](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/record)


### Integrate Zero Trust security

Integrating Zero Trust security principles throughout your infrastructure and application ecosystem ensures you reliability and protects you from breaches. The fundamental difference from traditional security approaches is the shift of access controls from the network perimeter to individual users. To accomplish this, you will utilize features from Cloudflare, GitHub, and two-factor authentication (2FA) services.

1. Choose which 2FA TOTP app you will use.

1. [Configure your GitHub account with 2FA](https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa/configuring-two-factor-authentication)

1. 

1. [Configure your Cloudflare account with 2FA](https://support.cloudflare.com/hc/en-us/articles/200167906-Securing-user-access-with-two-factor-authentication-2FA-)

1. 

1. [Configure your Terraform Cloud account with 2FA](https://www.terraform.io/cloud-docs/users-teams-organizations/2fa)

1. Configure Cloudflare Access policies with Terraform.

1. 


- Reference: [Multifactor Authentication](https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa/configuring-two-factor-authentication)
- Reference: [Terraform provider for Cloudflare Access Rules](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/access_rule)
- Reference: [Cloudflare Access Policies]()
- Reference: [Cloudflare Gateway]()

### Add SSO to your apps

Single-Sign-On (SSO) provides a simplified, one-time login experience for all your apps as well as fine-grained access control into which users have access to which apps. To create a SSO portal, you will utilize Cloudflare's App Launcher with GitHub as the Identity Provider (IdP).

1. Login to your Cloudflare account.

1. Do this: https://developers.cloudflare.com/cloudflare-one/identity/idp-integration/github

1. 

1. Add Cloudflare, GitHub, Terraform Cloud, and your Kubernetes apps to the Cloudflare App Launcher with Terraform.

1. 

- Reference: [Cloudflare App Launcher](https://developers.cloudflare.com/cloudflare-one/applications/app-launcher)
- Reference: [Cloudflare IdP Integration](https://developers.cloudflare.com/cloudflare-one/identity/idp-integration)

### Visualize your repo

GitHub's repo visualizer provides you with the shape of your codebase, giving you a different perspective on your reposistory. It can be used as a baseline to detect large changes in structure, understand how your environment is structured, or as a visual tool to explain features to others.

1. Navigate to the `/extras/github-actions` directory.
1. 

- Reference: [Repo Visualizer](https://github.com/githubocto/repo-visualizer)
- Reference: [Repo Visualizer Blog](https://next.github.com/projects/repo-visualization)

### Add your own apps

With this existing infrastructure in place, it's relatively simple to run your containerized apps in your cluster. In this guide, we'll deploy an app that can be easily installed and managed with a Helm chart.

1. In your `k3os-gitops` repo, navigate into your `/cluster/apps/` directory.

```sh
cd /cluster/apps/
```

1. Create a new directory called `esphome` and navigate into that directory.

```sh
mkdir esphome && cd esphome
```

1. Since this will be a stateful app, create a persistent storage definition file `config-pvc.yaml`.

```sh
touch config-pvc.yaml
```

1. Since this deployment will be defined and managed by a Helm chart, create the file `helm-release.yaml`.

```sh
touch helm-release.yaml
```

1. Since we use Kustomize as our configuration management tool, create the file `kustomize.yaml`.

```sh
touch kustomization.yaml
```

1. Copy and paste each file's respective content from the `/extras/apps/esphome` folder to their respective files you just created in `/cluster/apps/esphome`, then save your files.

1. Edit your `/cluster/apps/kustomization.yaml` file to include your `esphome` directory, then save the file.

```log
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - esphome
  - home-assistant
  - influxdb
```

1. Push the changes to your GitHub repository. 

```sh
git add .
git commit -m "add esphome app"
git push
```

1. Your cluster will begin deploying the `esphome` app and resources on your next Flux sync.

1. TODO: Add Terraform Cloudflare resource stanzas

1. 

You have now successfully created a new app in your Kubernetes cluster.

Additional reading regarding container workload types:
- [Stateless vs Stateful apps on Kubernetes](https://www.weka.io/blog/stateless-vs-stateful-kubernetes/)
- [Should I run a database on Kubernetes?](https://cloud.google.com/blog/products/databases/to-run-or-not-to-run-a-database-on-kubernetes-what-to-consider)

### One place to rule them all

Cheat sheet for global resources.

1. Kubernetes application secrets: `/cluster/base/cluster-secrets.sops.yaml`
1. Encryption secrets: `this_place.yaml`
1. Environment variables: `Within Terraform Cloud`
1. Cloudflare resources: `/terraform/cloudflare/files.tf`
1. 

## Gratitude

I have major appreciation for the people and organizations of the open-source community. This project was a result of the inspiration provided by these wonderful folks:

- [Awesome Home Kubernetes Collection](https://github.com/k8s-at-home/awesome-home-kubernetes)
- [Flux](https://github.com/fluxcd/flux2)
- [RenovateBot](https://github.com/renovatebot/github-action)
- [Template-cluster-k3s](https://github.com/k8s-at-home/template-cluster-k3s)
- [HomeOps](https://github.com/onedr0p/home-ops)