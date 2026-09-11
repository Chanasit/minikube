# GEMINI.md

Personal minikube GitOps lab. Terraform provisions a local cluster and bootstraps Flux; Flux reconciles all manifests under `clusters/apps` directly from the `master` branch of this repository.

## Architecture

- **`terraform/main.tf`**: Provisions the minikube cluster (`orbstack`, docker driver, 6 cpus / 16g RAM) and runs `flux_bootstrap_git` against `clusters/apps`, tracking branch `master` at a `1m` sync interval.
  - Providers: `minikube`, `kubernetes`, `flux`, `github`.
- **`clusters/apps/flux-system/`**: Flux internal components (`gotk-components.yaml`, `gotk-sync.yaml`). Auto-generated on bootstrap — **DO NOT MANUALLY EDIT**.
- **`clusters/apps/<app>/`**: One folder per application stack (`calico-system`, `istio-system`, `elastic-system`, `redis-system`, `monitoring`, `logging`, `weave`).
  - Each contains: `namespace.yaml`, resource manifests, and a `kustomization.yaml` defining `namespace:` and `resources:`.
  - Flux reconciles `clusters/apps` recursively without needing a root `kustomization.yaml`.

## Deploy Model (GitOps)

- **Source of Truth**: Cluster state strictly reflects the git repository. Flux prunes (`prune: true`) drift and ad-hoc manual changes. Never use `kubectl apply` or live `kubectl patch` to fix cluster state — update the YAML, commit, and let Flux reconcile.
- **Adding an App**: Create a new subdirectory under `clusters/apps/`, include `namespace.yaml`, manifests, and `kustomization.yaml`, and push to `master`.
- **Helm Releases**: Use Flux `HelmRepository` + `HelmRelease` definitions (e.g. `clusters/apps/logging/kafka.yaml` with OCI registry).

## Essential Commands

```bash
# Terraform bootstrap & planning
cd terraform && terraform init
terraform plan
terraform apply

# Flux reconciliation & cluster status
flux get kustomizations -A
flux reconcile kustomization flux-system --with-source
kubectl get pods -A
```

## Secrets & Credentials

- `github_token` is a sensitive Terraform variable requiring a GitHub PAT with `repo` scope for Flux git sync.
- **NEVER hardcode tokens** in version-controlled files.
- Local token management:
  - **Native auto-load**: Stored in `terraform/secret.auto.tfvars` (gitignored). See `terraform/secret.auto.tfvars.example`.
  - **Environment variables**: `export TF_VAR_github_token="..."` or `export GITHUB_TOKEN="..."`.

## Guardrails

- **Pre-commit checks**: Run `terraform fmt -check` and `trivy config .`.
- **Destructive operations**: Any destructive command (`terraform destroy`, `minikube delete`, `kubectl delete namespace`, suspending/pruning Flux resources) requires explicit confirmation — never execute autonomously.
- **Labels**: Label deployments with `managed_by: caveman` and appropriate environment identifiers.
- **Pinned Versions**: Flux CLI / bootstrap `v2.9.5`; Minikube Kubernetes `v1.35.0`.
