#!/bin/bash
# shellcheck source=/dev/null

set -e

cat <<EOF

##################################################
# Validate Tooling
##################################################

EOF

# check if required softare in installed
dependencies=("jq" "git" "terraform" "kustomize" "kubectl" "docker")

for dependency in "${dependencies[@]}"; do
    if ! which "$dependency" >> /dev/null; then
        echo "error $dependency not installed, install it before continuing"
        exit 1
    else
        echo "info $dependency installed"
    fi
done

cat <<EOF

##################################################
# Authentication
##################################################

EOF

# only run the sp login if running in CI
if [ -n "$RUN_IN_CI" ]; then
    echo "info running in ci using azure service principal"
    az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$AZ_TENANT_ID"
else
    echo "info not runnign in ci using local az session"
fi

# set and source env data from az_cli
TF_VAR_branch_name=$(git rev-parse --abbrev-ref HEAD)
TF_VAR_tenant_id=$(az account list --query "[?isDefault].tenantId" --output tsv) # I only have one account can change isDefault to [?name=='name of subscription'].tenantId
TF_VAR_subscription_id=$(az account list --query "[?isDefault].id" --output tsv) # I only have one account can change isDefault to [?name=='name of subscription'].id

if [ -n "$ARGOCD_PAT" ]; then
    TF_VAR_github_pat="$ARGOCD_PAT" #"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"
    export TF_VAR_github_pat
fi
export TF_VAR_branch_name
export TF_VAR_tenant_id
export TF_VAR_subscription_id


cat <<EOF

##################################################
# Terraform Apply
##################################################

EOF

terraform -chdir=iac/azure init
terraform -chdir=iac/azure apply --auto-approve;

source iac/azure/env.sh # file contains dyamic data for use with below

cat <<EOF

##################################################
# Docker Build and Push
##################################################

EOF

# Build and push Game
docker build src/game -t "$CONTAINER_REGISTRY_URL/game:$TF_VAR_branch_name"
TOKEN=$(az acr login --name "$CONTAINER_REGISTRY_NAME" --expose-token --output tsv --query accessToken)
docker login "$CONTAINER_REGISTRY_URL" --username 00000000-0000-0000-0000-000000000000 --password-stdin <<< "$TOKEN"
docker push "$CONTAINER_REGISTRY_URL/game:$TF_VAR_branch_name"

cat <<EOF

##################################################
# Deploy
##################################################

EOF

echo "info setting up cluster config"
az aks get-credentials --overwrite-existing --name "$AZ_AKS_CLUSTER_NAME" --resource-group "$AZ_AKS_CLUSTER_RESOURCE_GROUP_NAME"

echo "info setting up repo"
cat manifests/argocd-project.yaml | sed 's/__ARGOCD_PAT__/'"$ARGOCD_PAT"'/g' | kubectl apply -f -

echo "info deploying game"
kubectl apply -f manifests/game/application.yaml