# Overview

Deploy a local Kubernetes datacenter that features low maintenance, high security, and simple scalability.

To achieve these goals, the following methodologies will be utilized:

- [GitOps](https://www.weave.works/technologies/gitops/) with [Flux](https://fluxcd.io/docs/concepts/) & [Terraform Cloud](https://cloud.hashicorp.com/products/terraform)
- Bare metal Kubernetes deployment with [k3os](https://k3os.io/)
- Multi-layer encryption using [SOPs](https://fluxcd.io/docs/guides/mozilla-sops/) & [Cert Manager](https://cert-manager.io/docs/)
- [Zero Trust security](https://www.cloudflare.com/learning/security/glossary/what-is-zero-trust/) with [Cloudflare](https://www.cloudflare.com/what-is-cloudflare/) & [2FA](https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa/configuring-two-factor-authentication)
- Automated system updates with [Renovate](https://www.whitesourcesoftware.com/free-developer-tools/renovate/) & [System Upgrade Controller](https://rancher.com/docs/k3s/latest/en/upgrades/automated/)

# Diagrams

![GitOps Workflow](/img/gitops_workflow.png)

![Namespace Architecture Diagram](/img/namespace_architecture_diagram.png)

![Network Architecture Diagram](/img/network_architecture_diagram.png)

![Storage Architecture Diagram](/img/storage_architecture_diagram.png)

![Repository Structure Diagram](/img/respository_diagram.svg)

# Prerequisites

In order to complete this guide, you will need the following:

- MacOS or Linux
- Visual Studio Code
- [Homebrew](https://brew.sh/)
- A GitHub Account
- A Cloudflare Account with a domain
- A Terraform Cloud Account
- A PC/VM with at least 8GB RAM
- A positive attitude and some patience

# Deployment overview

This guide will walk you through the following steps:

1. Setup
    1. Fork this repo
    1. OS Installation
    1. Connect to your Kubernetes node
    1. Generate a Cloudflare API key
    1. Activate Cloudflare Zero Trust
    1. Generate a Terraform Cloud API token
    1. Generate a GitHub OAuth token for Cloudflare
    1. Generate a GitHub Personal Access Token for Terraform Cloud
    1. Configure secrets encryption
    1. Prepare for deployment
1. Deployment
    1. Configure and Deploy Flux
    1. Deploy your Kubernetes cluster resources
    1. Automate external resource creation
    1. Access your apps from anywhere
1. Security
    1. Extend Zero Trust security
    1. Threat protection and visibility with DNS layer security
1. Additional Automation
    1. Automate your app updates
    1. Automate k3s updates
1. Operations
    1. Add your own apps
    1. Observability, health-checking, and performance
1. Extras 
    1. Visualize your repo

**Note**: In order to stay focused on secure GitOps practices, these practices will not be covered in depth within this guide:

- High availability for networking, storage, and Kubernetes components
- Hosted/Cloud deployments
- Load balancing
- Automated secrets management
- Disaster recovery

## Fork this repo

In addition to this repository containing all the resources you will use throughout this guide, your GitHub repository will be the single source of truth for your Kubernetes & Cloudflare infrastructure definitions. 

When new code is merged into your GitHub repository, Flux (which we will setup in a later step) will ensure your environment reflects the state of your GitHub repository. This is the essense of Infrastructure as code (IaC) - the practice of keeping all your declarative infrastructure configuration stored as code. 

1. [Fork](https://docs.github.com/en/get-started/quickstart/fork-a-repo) this `k3s-gitops` repo into your own GitHub repo.

## OS Installation

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

**Note**: If you receive install errors using the LiveCD option, reboot and proceed with the same options using the "k3OS installer" option instead of the "k3OS LiveCD & Installer" option.

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

## Connect to your Kubernetes node

The majority of interaction with your Kubernetes node will occur from a remote development system - in this case, the Mac where you cloned this repo.

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

## Generate a Cloudflare API key

Cloudflare is used throughout this guide for several reasons: 

- Enables `cert-manager` to utilize the Cloudflare DNS challenge for automating TLS certificate creation in your Kubernetes cluster
- Enables accessibility of your apps from anywhere
- Secures access to your apps with Cloudflare Access
- Provides DNS security, detailed traffic metrics, and logging with Cloudflare Gateway
- Provides you with Zero Trust security capabilities
- Provides you with an single-sign-on (SSO) portal for your apps
- Integrates with Terraform Cloud for automated Cloudflare resource creation

1. Login to your [Cloudflare account](https://dash.cloudflare.com/login).

1. Create an API key by going to [this page](https://dash.cloudflare.com/profile/api-tokens) in your Cloudflare profile.

**Note**: Your API key is a sensitive credential that allows programatic access to your Cloudflare account - ensure you take all precautions to protect this key.

1. Copy the API key to your clipboard.

1. Paste your API key as the value for `CLOUDFLARE_APIKEY` in your `bootstrap.env` file, then save the file. 

You now have a Cloudflare API key that will enable you to programatically create Cloudflare and encryption resources with ease.

## Activate Cloudflare Zero Trust

Cloudflare Zero Trust is a free suite of Zero Trust security tools including Cloudflare Access and Cloudflare Gateway. In order to programatically utilize these features, you must first activate the service on your Cloudflare account and generate a team name attribute.

https://developers.cloudflare.com/cloudflare-one/faq/teams-getting-started-faq

1. Visit the Cloudflare Zero Trust [sign up page](https://dash.cloudflare.com/sign-up/teams).

1. Follow the onboarding steps and choose a team name.

1. Copy your team name to your clipboard, paste your team name as the value for `CLOUDFLARE_TEAM_NAME` in your `bootstrap.env` file, then save the file. 

You now have the foundation for programatically integrating Cloudflare's Zero Trust tools into your environment.

## Generate a Terraform API token

Terraform Cloud is an infrastructure-as-code tool that allows you to easily create external resources for Cloudflare and hundreds of other cloud services. Rather than manage a consistent state in each cloud service UI, Terraform allows you to define and manage these resources in your GitHub repository. This enables you to stay consistent with the philosophy of GitOps and streamline your CI/CD workflow.

1. Login to your [Terraform Cloud account](https://app.terraform.io/).

1. Create an API token by going to [this page](https://app.terraform.io/app/settings/tokens) in your Terraform Cloud profile.

**Note**: Your API token is a sensitive credential that allows programatic access to your Terraform Cloud account - ensure you take all precautions to protect this key.

1. Copy the API token to your clipboard.

1. Paste your API token as the value for `TERRAFORM_CLOUD_TOKEN` in your `bootstrap.env` file, then save the file. 

You now have a Terraform Cloud API token that will enable you to programatically configure your Terraform environment.

## Generate a GitHub OAuth token for Cloudflare

GitHub integrates with Cloudflare to secure your environment using Zero Trust security methodologies for authentication. Cloudflare will utilize your GitHub OAuth token to authorize user access to your applications. This will enable your GitHub identity to use Single Sign On (SSO) for all of your applications.

1. Login to your [GitHub account](https://github.com/login).

1. Go to the [OAuth token creation page](https://github.com/settings/developers), select "OAuth Apps", then click "Register a new application".

**Note**: Your OAuth token is a sensitive credential - ensure you take all precautions to protect this key.

1. Complete the "Register a new OAuth application" form using these values.
    1. Application name: `Cloudflare`
    1. Homepage URL: `https://<your-team-name>.cloudflareaccess.com`
    1. Authorization callback URL: `https://<your-team-name>.cloudflareaccess.com/cdn-cgi/access/callback`

**Note**: Replace `<your-team-name>` in the fields above with the contents of `CLOUDFLARE_TEAM_NAME` in your `bootstrap.env` file.

1. Click the "Register application" button once complete.

1. Copy the OAuth Client ID to your clipboard.

1. Paste your API token as the value for `CLOUDFLARE_OAUTH_CLIENT_ID` in your `bootstrap.env` file, then save the file. 

1. Copy the OAuth Client Secret to your clipboard.

1. Paste your API token as the value for `CLOUDFLARE_OAUTH_CLIENT_SECRET` in your `bootstrap.env` file, then save the file. 

You now have a GitHub OAuth client and secret that will enable you to programatically configure your Cloudflare environment with Zero Trust security methodologies.

## Generate a GitHub Personal Access Token for Terraform Cloud

A GitHub Personal Access Token (PAT) enables the integration between Terraform Cloud and your GitHub repository. This further enables the GitOps model by allowing Terraform Cloud to automatically initiate Terraform runs when changes are committed to your GitHub repository.

1. Follow [this GitHub guide](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) to create a Personal Access Token (PAT) with the following permission scopes:
    - repo:status
    - public_repo
    - read:repo_hook 

1. Copy the GitHub Personal Access token to your clipboard.

1. Paste your API token as the value for `GITHUB_PERSONAL_ACCESS_TOKEN` in your `bootstrap.env` file, then save the file. 

You now have a GitHub Personal Access Token (PAT) that will enable you to programatically integrate your Terraform Cloud and GitHub instances.

## Configure Secrets Encryption

Secrets encryption allows you to safely store secrets in a public or private Git repository. To accomplish this, [Age](https://github.com/FiloSottile/age) is a tool that will encrypt your YAML files and/or secrets using Mozilla SOPs (Secrets Operations) encryption. In a later step, you will configure Flux with this SOPs encryption key - this will allow your Kubernetes cluster to decrypt and utilize those secrets for operations.

1. Begin by installing `age`.

```sh
brew install age
```

1. Create a Age Private / Public Key.

```sh
age-keygen -o age.agekey
```

1. Set up the directory for the Age key and move the Age file to it.

```sh
mkdir -p ~/.config/sops/age
mv age.agekey ~/.config/sops/age/keys.txt
```

1. Fill out the `age` public key in the `bootstrap.env` under `AGE_PUBLIC_KEY`.

**Note**: The public key should start with `age`...

1. For disaster recovery purposes, copy the contents of your age private key to your (hopefully MFA-protected) password manager such as 1Password or LastPass. 

Your environment is now prepared for encrypting all secrets in your cluster.

## Prepare for deployment

To prepare for deployment, it's necessary to bootstrap your development environment with your custom values such as DNS information, API keys, and encryption secrets. You'll then encrypt all your sensitive values before pushing your project to your Github repository. It is important to follow these steps carefully to ensure no sensitive values are pushed to your public repository.

1. Open and edit your `bootstrap.env` file to ensure it includes all your respective unique values, then save the file.

**Note**: Some variables contain the prefix `TF_VAR_` - This prefix enables Terraform to use your local environment variables for Terraform runs.

1. Source the `bootstrap.env` file to set the respective environment variables in your terminal.

```sh
source bootstrap.env
```

1. In the same terminal window where you set your environment variables, run the following commands to create your unique, encrypted deployment files.

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
    1. Example:
        ```yaml
        ...
        stringData:
            SECRET_DOMAIN: ENC[AES256_GCM,data:Bo7jy7IUc+y1q/FJO+6M69I48Fki,iv:y5Hoso7vsi/zEVXLTJjXBpmRWD/EeGWL5a9/nn10qZM=,tag:AsFSV5/bbPTj7Qg2z7mhWA==,type:str]
            SECRET_CLOUDFLARE_EMAIL: ENC[AES256_GCM,data:IgsmYgBrXl5OCm7EwmD6jYvU/GQ=,iv:Hggz5wPBXP7UT42tImV6GMXE77cV4oyqe3fVvVyjBQY=,tag:N7b2l+jrX/pwC5cBFMMC+Q==,type:str]
            SECRET_CLOUDFLARE_APIKEY: ENC[AES256_GCM,data:FQMGIfThD31Scw4gHHYqgxeW8OP8isnl1eGzr+pFOHyOFVtIjg==,iv:aijlt+P5a8w5YhwsMFbRjicMokoUQ=,tag:kJdMQ4I+AfsyS9lcr+NSGg==,type:str]
        ...
        ```

1. If you verified all your secrets are encrypted, you can delete the `tmpl` directory now since these files are only used for this bootstrapping process.

```sh
rm -rf ${PROJECT_DIR}/tmpl/
```

1. Since `bootstrap.env` contains so many sensitive values, be sure it is included in your `.gitignore` so you DO NOT commit it to your public GitHub repository. 

```sh
echo -e "\n#Sensitive Bootstrap Environment Variables\nbootstrap.env" >> .gitignore
```

1. Sync your completed project to your public GitHub repository.

```sh
git add .
git commit -m "add encrypted deployment files"
git push
```

Your local terminal and GitHub repository are now ready to initialize Flux.

## Configure and Deploy Flux

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

1. Add your Age key to your Kubernetes cluster as a secret. This enables Flux to decrypt SOPs secrets.

```sh
cat ~/.config/sops/age/keys.txt |
kubectl -n flux-system create secret generic sops-age \
--from-file=age.agekey=/dev/stdin
# secret/sops-age created
```

Your Kubernetes cluster is now ready to begin sycning with your GitHub repo to deploy apps with Flux.

## Deploy your Kubernetes cluster resources

Now that your infrastructure, security mechanisms, and deployment methodologies are in place - it's time to start deploying resources in your Kubernetes cluster! 

Kubernetes clusters are made up of many unique (and interchangeable) components and applications. These include technologies that facilitate networking segmentation, perform CI/CD operations, automate security operations, gather metrics, load balance services, and run your applications. The Kubernetes universe is [gigantic](https://landscape.cncf.io/) - there's plenty of room for experimentation and growth with this project as your foundation.

These are the components (organized by namespace) that will be deployed with this repo:

1. apps
    1. [home-assistant](https://github.com/home-assistant/core) - Highly extensible home automation platform 
    1. [vs-code](https://github.com/coder/code-server) - Browser-based Visual Studio Code instance for editing home-assistant configuration
    1. [influxdb](https://github.com/influxdata/influxdb) - Persistent time-series database for home-assistant data
    1. [code-server](https://github.com/coder/code-server) - Browser-based Visual Studio Code instance for all your code development
    1. [esphome](https://esphome.io/) - Development and management platform for IoT microcontrollers
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
    1. [loki](https://github.com/grafana/loki) - Logging platform
    1. [promtail](https://grafana.com/docs/loki/latest/clients/promtail/) - Collector agent that ships logs to Loki
    1. [jaeger](https://github.com/jaegertracing/jaeger) - Distributed tracing platform

**Note**: The deployment parameters for each of these Kubernetes applications is controlled through its respective [Helm chart](https://helm.sh/). The Helm chart values that have been set in this repository are to enable essential functionality for the scope of this guide. Feel free to explore each respective Helm chart after completing this guide to expand and customize these applications.

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

## Automate external resource creation

In this section you will bootstrap Terraform Cloud, which will then monitor the resources in the respective `terraform/` subdirectories. True to the GitOps philosophy, when Terraform Cloud detects any changes within these directories, it will automatically trigger a workflow to create and maintain the desired state of your external resources. 

1. Change directory to `terraform/terraform-cloud`

```sh
cd terraform/terraform-cloud
```

1. Install `terraform`. 

```sh
brew install terraform
```

1. Ensure your bootstrapping environment variables are set in your terminal.

```sh
source bootstrap.env
```

1. Initialize Terraform in your `terraform/terraform-cloud` directory.

```sh
terraform init
```

1. Run terraform plan.

```sh
terraform plan
```

1. Review and verify the contents of the plan.

```log
some output
```

1. Apply the plan.
```sh
terraform apply --auto-approve
```

**Note**: You no longer need to run terraform locally after this since Terraform Cloud will now manage all your Terraform automation workflows.

1. Verify Terraform Cloud has been bootstrapped by logging into your [Terraform Cloud UI](https://app.terraform.io/). Click into your organization, then click into your Cloudflare workspace.

**Note**: Due to race conditions with the Terraform Cloud bootstrapping and Cloudflare provider, you will see an error with the initial run. Triggering a manual run from the UI or committing a change to any files in the `terraform/cloudflare/` directory in your repository will allow the Cloudflare workflow (and all future Cloudflare workflows) to continue. 

1. Once you clear the initial race condition, check that the run status is `Applied` for your Cloudflare workspace.

Your Terraform Cloud workspace will now continuously monitor your GitHub repository for changes and automatically create any respective resources in your Cloudflare account.

## Access your apps from anywhere

With your cloud infrastructure and Kubernetes infrastructure in place, the only remaining piece is to connect the two with a port-forwarding rule on your local networking equipment.

1. On your local router, configure port forwarding with the following attributes:
- Source: `0.0.0.0/0`
- Port: `443` 
- Destination: Your Traefik Ingress IP (whatever IP you set for `METALLB_TRAEFIK_ADDR`). 

1. Login to your Cloudflare App Launcher (your SSO portal) with your GitHub identity. https://<your-cloudflare-team-name>.cloudflareaccess.com

1. Click one of your Kubernetes applications (ex: grafana, code-server, etc) to confirm that your application is publicly accessible.

**Note**: Consider the following traffic flow if troubleshooting is necessary in your environment.
Service Request -> Cloudflare -> Your Public IP -> Port Forwarding Rule on your Router - > Traefik Ingress private IP -> Kubernetes Service -> Kubernetes Pod

Cloudflare will now encrypt and route all respective DNS requests to the Traefik Ingress controller in your Kubernetes cluster.

## Extend Zero Trust security

Integrating Zero Trust security principles throughout your infrastructure and application ecosystem ensures you reliability and protects you from breaches. The fundamental difference from traditional security approaches is the shift of access controls from the network perimeter to individual users. To accomplish this, you will utilize features from Cloudflare, GitHub, and multi-factor authentication (MFA) services.

1. Choose which MFA TOTP app you will use. [Here are the GitHub recommendations](https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa/configuring-two-factor-authentication#configuring-two-factor-authentication-using-a-totp-mobile-app)

1. Follow [this GitHub guide](https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa/configuring-two-factor-authentication) to secure your GitHub account with MFA.

1. Follow [this Cloudflare guide](https://support.cloudflare.com/hc/en-us/articles/200167906-Securing-user-access-with-two-factor-authentication-2FA-) to secure your Cloudflare account with MFA.

1. Follow [this Terraform Cloud guide](https://www.terraform.io/cloud-docs/users-teams-organizations/2fa) to secure your Terraform Cloud account with MFA.  

1. Optional: Follow [this Cloudflare guide](https://developers.cloudflare.com/cloudflare-one/applications/configure-apps/) to add Cloudflare Admin, GitHub, Terraform Cloud, your Kubernetes apps, and other applications to your Cloudflare App Launcher.

Your complete infrastructure ecosystem is now protected with multi-factor authentication.

## Threat protection and visibility with DNS layer security

Cloudflare Gateway uses DNS layer security to enable control and visibility of your distributed environment.

TODO: Build out this section

1. [Configure Cloudflare Gateway](https://www.cloudflare.com/products/zero-trust/gateway/)

1. 

## Automate your app updates

Renovate is a bot that watches the contents of your repository looking for dependency updates and automatically creates pull requests when updates are found. When you merge these PRs, Flux will automatically apply the changes to your cluster. 

Renovate runs via a scheduled Github Action workflow; GitHub Actions are used to automate, customize, and execute your software development workflows directly in your repository, similarly to how Flux does this for your Kubernetes cluster.

TODO: Build out this section

1. TODO: Replace the contents below with these instructions since the previous workflow action has been deprecated:
https://github.com/renovatebot/github-action#configurationfile 

1. Create a GitHub Personal Access Token for Renovate. 

1. Create a GitHub secret called `RENOVATE_TOKEN` and paste in the Personal Access Token you just generated.

1. Navigate to the root of your `k3os-gitops` repository.

1. Copy the file `/extras/github-actions/renovate.yaml` to your `.github/workflows` directory.

```sh
cp /extras/github-actions/renovate.yaml .github/workflows/renovate.yaml
```

1. Replace the GitHub repository URL in the `.github/workflows/renovate.json5` file with your GitHub repository URL.

1. Within each of your `helm-release.yaml` files, ensure you create a respective `renovate:` line within your chart spec similar to the following stanza - this specifies the chart that Renovate will watch for version updates to your respective applications/resources.

```yaml
...
spec:
  interval: 5m
  chart:
    spec:
      # renovate: registryUrl=https://charts.jetstack.io/
      chart: cert-manager
      version: v1.5.3
...
```

1. Push the changes to your GitHub repository. 

```sh
git add .
git commit -m "add github action - renovate bot"
git push
```

You now have an automated bot that will compare your cluster's application versions against the latest versions. Renovate bot will generate a pull request for you to review and merge whenever new versions are found.

## Automate K3S updates

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

## Add your own apps

With this existing infrastructure in place, it's relatively simple to run your containerized apps in your cluster. In this guide, we'll deploy an app that can be easily installed and managed with a Helm chart. This will also highlight each touch point for adding a new application to your cluster including Kubernetes definition components, secret encryption, automated updates, Cloudflare resources, and application observability integration.

1. In your `k3os-gitops` repo, navigate into your `/cluster/apps/` directory.

```sh
cd /cluster/apps/
```

1. Create a new directory called `vault` and navigate into that directory.

```sh
mkdir vault && cd vault
```

1. Since this deployment will be defined and managed by a Helm chart, create the file `helm-release.yaml`.

```sh
touch helm-release.yaml
```

1. Since we use Kustomize as our configuration management tool, create the file `kustomize.yaml`.

```sh
touch kustomization.yaml
```

1. In most stateful application cases, you would create a persistent storage definition file `config-pvc.yaml`, however, in this case the Vault Helm chart creates a custom persistent storage definition itself.

1. Copy and paste each file's respective content from the `/extras/apps/vault` folder to their respective files you just created in `/cluster/apps/vault`, then save your files.


1. For configuration management purposes, edit your `/cluster/apps/kustomization.yaml` file to include your `vault` directory, then save the file.

```log
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - esphome
  - home-assistant
  - influxdb
  - code-server
  - vault
```

1. Since these resources will be managed by a Helm chart, create a new file `hashicorp-charts.yaml` in your Helm chart definition folder `/cluster/base/flux-system/charts/helm`.

1. Paste the following contents in your file
```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: HelmRepository
metadata:
  name: hashicorp-charts
  namespace: flux-system
spec:
  interval: 15m
  url: https://helm.releases.hashicorp.com
  timeout: 3m
```

1. Since this will be a public, externally-accessible resource, add `vault` to your `/terraform/cloudflare/services.auto.tfvars` file.

```log
SERVICE_LIST = [
    "traefik",
    "hass",
    "vscode",
    "influxdb",
    "code-server",
    "esphome",
    "traefik",
    "grafana",
    "prometheus",
    "vault"
]
```

**Note**: The `services.auto.tfvars` file is consumed by the other Cloudflare resource files to automatically create DNS records and Zero Trust resources for any entry within the file.

1. Push the changes to your GitHub repository. 

```sh
git add .
git commit -m "add vault app"
git push
```

1. This change to your GitHub repository will cause the following actions to automatically occur:

- Your Kubernetes cluster will deploy the `vault` app and resources on the next Flux sync. 
- Since `vault` will be a publicly accessible resource, `cert-manager` will generate an SSL certificate and traefik will create an ingress route for the service.
- Terraform Cloud will deploy `vault` DNS and Zero Trust resources to Cloudflare.
- Your `vault` application version will be checked for updates every Renovate sync.
- Your `vault` application logs will be scraped by `promtail` and sent to `loki`. 

TODO: Build out this section.

1. Configure `vault` for Observability.
    - Metrics: Prometheus
    - Logs: Loki and Promtail
    - Distributed Tracing: Jaeger
    - Visualization: Grafana

You have now successfully created a new app in your Kubernetes cluster.

Additional reading regarding container workload types:
- [Stateless vs Stateful apps on Kubernetes](https://www.weka.io/blog/stateless-vs-stateful-kubernetes/)
- [Should I run a database on Kubernetes?](https://cloud.google.com/blog/products/databases/to-run-or-not-to-run-a-database-on-kubernetes-what-to-consider)

## Observability, health-checking, and performance

Being able to easily visualize the various components of your Kubernetes environment allows you to monitor performance, setup alerting parameters, and troubleshoot challenges as they arise. The Grafana/Prometheus/Loki/Jaeger stack empowers you with a total observability (metrics, logs, and distributed traces) platform that scales with your Kubernetes components and your applications.

TODO: Build out this section.

1. Login to your Grafana instance at `https://grafana.<your-domain>`

1. 

## Visualize your repo

GitHub's repo visualizer provides you with the shape of your codebase, giving you a different perspective on your reposistory. It can be used as a baseline to detect large changes in structure, understand how your environment is structured, or as a visual tool to explain features to others.

TODO: Build out this section

1. Navigate to the `/extras/github-actions` directory.

1. 

- Reference: [Repo Visualizer](https://github.com/githubocto/repo-visualizer)
- Reference: [Repo Visualizer Blog](https://next.github.com/projects/repo-visualization)

# One place to rule them all

Cheat sheet for managing important cluster and global resources.

1. Kubernetes application secrets: `/cluster/base/cluster-secrets.sops.yaml`
1. Helm charts: `/cluster/base/flux-system/charts/helm`
1. Local Environment variables: `bootstrap.env`
1. Cloudflare service list: `/terraform/cloudflare/services.auto.tfvars`
1. RenovateBot configuration file: `.github/renovate.json5`

# Gratitude

I have major appreciation for the people and organizations of the open-source community. This project was a result of the inspiration provided by these wonderful folks:

- [Awesome Home Kubernetes Collection](https://github.com/k8s-at-home/awesome-home-kubernetes)
- [Flux](https://github.com/fluxcd/flux2)
- [RenovateBot](https://github.com/renovatebot/github-action)
- [Template-cluster-k3s](https://github.com/k8s-at-home/template-cluster-k3s)
- [HomeOps](https://github.com/onedr0p/home-ops)