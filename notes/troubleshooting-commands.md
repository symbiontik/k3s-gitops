# Manually sync flux
flux reconcile source git flux-system

# Show the health of you kustomizations
kubectl get kustomization -A

# Show the health of Flux repo
flux get sources git

# Show the health of your HelmReleases
flux get helmrelease -A

# Show the health of your HelmRepositorys
flux get sources helm -A

# Troubleshooting
kubectl -n flux-system get kustomization flux-system -oyaml

kubectl -n flux-system get gitrepository flux-system -oyaml

fluxctl identity --k8s-fwd-ns flux-system

# Flux Helm Chart troubleshooting

flux suspend hr <release_name> -n <namespace>
flux resume hr <release_name> -n <namespace>

