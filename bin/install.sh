#!/bin/bash

printf "Loading environment configurations...\n"
printf "#######################################################\n\n"
source bootstrap.env

printf "Creating namespace...\n"
printf "#######################################################\n\n"
kubectl create namespace flux-system --dry-run=client -o yaml | kubectl apply -f -

printf "Creating SOPs secret...\n"
printf "#######################################################\n\n"
cat ~/.config/sops/age/keys.txt |
kubectl -n flux-system create secret generic sops-age \
--from-file=age.agekey=/dev/stdin

printf "Installing FLUX CD in K3s cluster...\n"
printf "#######################################################\n\n"
flux bootstrap github \
  --owner=$GITHUB_USERNAME \
  --repository=$TF_VAR_GITHUB_REPOSITORY_IDENTIFIER \
  --path=./cluster/base \
  --personal

printf "Listing pods from FLUX CD...\n"
printf "#######################################################\n\n"
kubectl get pods -n flux-system