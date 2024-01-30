# devops-demo

This is a demo deployment that showcases the following

1. terraform deploy required resources to azure
2. docker build and push a demo app (a simple game written with gdscript in godot) pushes to azure container registry deployed on step 1
3. deploy manifest via argocd instance in cluster
4. collect logs and metrics using loki, prometheus and grapana

## Links

|**Link**|**username**|**password**|
|---|---|---|
|[game](https://game.devops-demo.reinier.co.za/)|||
|[argocd](https://argocd.devops-demo.reinier.co.za/)|admin|***|
|[grafana](https://grafana.devops-demo.reinier.co.za/login)|admin|***|

> note that argocd and grafana uses its generated credentials this will be a short lived deploy for demonstration purposes.

# Structure

```bash
/
|-> iac
|   |-> azure # main terraform code to manage the infrastructure
|
|-> manifests
|   |-> argocd-project.yaml # argocd repo setup
|   |-> folder/application.yaml # argocd application
|   |-> folder/base # kubernetes manifests to be deployed via argocd
|
|-> src/folder # source code and docker files
|
|-> ci.sh # bash script that contains all the ci instructions, this can also be ran locally
```

## Ci-Cd

Ci is handled by a single bash script called ci.sh in the root of the repo

this scripts executes the following in this order

1. checks that dependencies is installed
2. log into azure
3. check terraform code for issues
4. deploy infrastructure via terraform
5. docker build and push apps in this case the game
6. setup argocd repo using kubectl
7. deploy argocd apps using kubectl

Cd is handled by Argocd, it checks the manifests directory for changes on the main branch and deploys to same cluster its hosted in

## application (game)

simple ultimate knots and crosses game built using the Godot frame work and exported to web (wasm)

see for details about the rules https://en.wikipedia.org/wiki/Ultimate_tic-tac-toe 

## Future Improvements

### Argocd

SSO to Azure AD
Create helm charts for apps so that Argocd can template them

Install basic tempting tool like gomplate on argocd to replace values in manifests based on env vars or 

### Kubernetes

Install external secrets (can pull in secrets from a keyvault) (skipped to save some costs)

Enable Workload identities (allows pods and other k8s resources to access azure resources based on role assistants)

### Grafana

Add Alets and triggers based on log and metrics events

> Potentials swap out Loki-stack for pure azure container insights and azure log analytics

### Github Actions

Split single file into workflow with dependant steps

Add Static code analysts, unit tests before build

Add web test after deploy to verify services are running correctly 

