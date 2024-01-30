#!/bin/bash
# shellcheck source=/dev/null

set -e

curl https://ifconfig.io

cat <<EOF

##################################################
# Validate Tooling
##################################################

EOF

function install_tfsec() {
    curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
}

# check if required softare in installed
dependencies=("jq" "git" "terraform" "kustomize" "kubectl" "docker" "tfsec" "curl")

for dependency in "${dependencies[@]}"; do
    if ! which "$dependency" >> /dev/null; then
        
        case "$dependency" in
            tfsec)
                install_tfsec
            ;;
            *)
                echo "error $dependency not installed, and no install function available please install before continuing"
                exit 1
            ;;
        esac
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
    curl -LO https://github.com/Azure/kubelogin/releases/download/v0.1.0/kubelogin-darwin-amd64.zip
    unzip kubelogin-linux-arm64.zip
    sudo mv bin/linux_arm64/kubelogin /usr/local/bin
    chmod +x /usr/local/bin/kubelogin
else
    echo "info not runnign in ci using local az session"
fi

# set and source env data from az_cli
TF_VAR_branch_name=$(git rev-parse --abbrev-ref HEAD)
TF_VAR_tenant_id=$(az account list --query "[?isDefault].tenantId" --output tsv) # I only have one account can change isDefault to [?name=='name of subscription'].tenantId
TF_VAR_subscription_id=$(az account list --query "[?isDefault].id" --output tsv) # I only have one account can change isDefault to [?name=='name of subscription'].id
TF_VAR_ci_runner_public_ip="$(curl https://ifconfig.io)/32"

export TF_VAR_branch_name
export TF_VAR_tenant_id
export TF_VAR_subscription_id
export TF_VAR_ci_runner_public_ip

branch_slug=$(basename "$TF_VAR_branch_name")
echo  "$branch_slug-devops-demo"
if az aks update --resource-group "$branch_slug-devops-demo" --name "$branch_slug-devops-demo" --subscription "$TF_VAR_subscription_id" --api-server-authorized-ip-ranges  "165.255.240.143/32, $TF_VAR_ci_runner_public_ip"; then
    echo "info added runners IP address to aks authorised ip range"
else
    echo "warn cluster may note exist yet or not found"
fi

cat <<EOF

##################################################
# Tests and Analyze Code
##################################################

EOF

# TF sec for security issues and terraform code issues
tfsec iac/azure


cat <<EOF

##################################################
# Terraform Apply
##################################################

EOF

export TF_CLI_ARGS_plan="-compact-warnings"
export TF_CLI_ARGS_apply="-compact-warnings"

terraform -chdir=iac/azure init
terraform -chdir=iac/azure apply --auto-approve;

source iac/azure/env.sh # file contains dyamic data for use with below

cat <<EOF

##################################################
# Docker Build and Push
##################################################

EOF

# Build and push Game
docker build --platform=linux/amd64 src/game -t "$CONTAINER_REGISTRY_URL/game:$TF_VAR_branch_name"
TOKEN=$(az acr login --name "$CONTAINER_REGISTRY_NAME" --expose-token --output tsv --query accessToken)
docker login "$CONTAINER_REGISTRY_URL" --username 00000000-0000-0000-0000-000000000000 --password-stdin <<< "$TOKEN"
docker push "$CONTAINER_REGISTRY_URL/game:$TF_VAR_branch_name"

cat <<EOF

##################################################
# Deploy
##################################################

EOF

echo "info setting up cluster config"
az aks get-credentials --overwrite-existing --name "$AZ_AKS_CLUSTER_NAME" --resource-group "$AZ_AKS_CLUSTER_RESOURCE_GROUP_NAME" #--format azure

if [ -n "$RUN_IN_CI" ]; then
    kubelogin convert-kubeconfig
fi

echo "info setting up repo"
cat manifests/argocd-project.yaml | sed 's/__ARGOCD_PAT__/'"$ARGOCD_PAT"'/g' | kubectl apply -f -

echo "info deploying game"
kubectl apply -f manifests/game/application.yaml

echo "info deploying grafana ingress"
kubectl apply -f manifests/grafana-ingress/application.yaml

echo "info deploying argocd ingress"
kubectl apply -f manifests/argocd-ingress/application.yaml
