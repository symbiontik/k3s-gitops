#!/bin/bash

printf "Processing all certificate requests...\n"
printf "#######################################################\n\n"

#iterate over all namespaces listed by kubectl
for ns in $(kubectl get certificaterequest -A  --no-headers | awk '{print $1}'); do
    printf "Iterate over namespace $ns...\n"

    #iterate over all certificate requests listed by kubectl and cert-manager
    for csr in $(kubectl get certificaterequest -n $ns  --no-headers | awk '{print $1}'); do
        printf "\tProcessing $csr...\n"

        #approve the csr
        kubectl cert-manager approve $csr -n $ns
    done
done

printf "Done\n"
printf "#######################################################\n\n"
