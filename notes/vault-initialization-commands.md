# Ensure you have Vault installed on your development machine
brew install vault 

# In terminal one
# Port forward 8200 traffic to the vault-0 pod
kubectl port-forward vault-0 8200:8200 -n apps

# In terminal two
# Set your local environment to talk with your Vault pod
export VAULT_ADDR=http://127.0.0.1:8200

# Initialize Vault
vault operator init

## Example expected output
```log
Unseal Key 1: evMM7n0H4pEnvdHOS1GaM9G6gHK7YrAWiAZQpnk7eXoe
Unseal Key 2: IIYPXJ184kl0MIPIXf/SGcN4U88qDvAa55KbxCQ3FNvX
Unseal Key 3: 4vcikKg1KpSn1j6m6Lf08pIRgcgtxDpb2OPqdGhzDyex
Unseal Key 4: QKMLee7F3V7U0M8dhjmgodWg3zR07bYFew9uNd32uH2U
Unseal Key 5: VjJOMBR08ZpVAaRhwFTsNT2fc3XGrgY/NiMpcwvCvyTD

Initial Root Token: s.bkk3fOKozTHkmVE0u8TiRBwT
```

# Copy your unseal keys and root key to a safe location

# Check out the locally accessible instance of Vault in your web browser
http://localhost:8200/ui