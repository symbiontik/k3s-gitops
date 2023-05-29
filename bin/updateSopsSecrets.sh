#!/bin/bash

source bootstrap.env

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
envsubst < "${PROJECT_DIR}/tmpl/cluster/cloudflare-originca-sops.env" \
    > "${PROJECT_DIR}/cluster/core/rancher/cloudflare-originca-sops.env"
envsubst < "${PROJECT_DIR}/tmpl/cluster/rancher-bootstrap-sops.env" \
    > "${PROJECT_DIR}/cluster/core/rancher/rancher-bootstrap-sops.env"

# encrypt sensitive files
sops --encrypt --in-place "${PROJECT_DIR}/cluster/base/cluster-secrets.sops.yaml"
sops --encrypt --in-place "${PROJECT_DIR}/cluster/core/cert-manager/secret.sops.yaml"
sops --encrypt --in-place "${PROJECT_DIR}/cluster/core/rancher/cloudflare-originca-sops.env"
sops --encrypt --in-place "${PROJECT_DIR}/cluster/core/rancher/rancher-bootstrap-sops.env"

git add cluster/base/cluster-secrets.sops.yaml
git add cluster/core/cert-manager/secret.sops.yaml
git add cluster/core/rancher/cloudflare-originca-sops.env
git add cluster/core/rancher/rancher-bootstrap-sops.env

git commit -m "Updating Sops secrets"