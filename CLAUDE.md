# CLAUDE.md

Personal minikube GitOps lab. Terraform bootstraps a local cluster + Flux; Flux reconciles everything under `clusters/apps` from the `master` branch of this repo.

## Architecture

- `terraform/main.tf` — provisions the minikube cluster (`orbstack`, docker driver, 6 cpu / 16g) and runs `flux_bootstrap_git` against `clusters/apps`, branch `master`, interval `1m`. Providers: minikube, kubernetes, flux, github.
- `clusters/apps/flux-system/` — Flux-generated (`gotk-components.yaml`, `gotk-sync.yaml`). Marked `DO NOT EDIT`; regenerated on bootstrap.
- `clusters/apps/<app>/` — one dir per app (istio-system, elastic-system, redis-system, monitoring, logging, weave). Each holds `namespace.yaml`, its manifests, and a `kustomization.yaml` that sets `namespace:` + lists `resources:`.
- No top-level `clusters/apps/kustomization.yaml` — Flux reconciles the path recursively.

## Deploy model (GitOps — read this before editing manifests)

- Cluster state comes from git, NOT from `kubectl apply`. Push to `master` → Flux syncs (~1m). Do not hand-apply or patch live objects; that is drift and gets pruned (`prune: true`).
- Add an app: new dir under `clusters/apps/`, add `namespace.yaml` + manifests + `kustomization.yaml`, commit.
- Helm-based apps use Flux `HelmRepository` + `HelmRelease` (see `clusters/apps/logging/kafka.yaml`, OCI repo `oci://registry-1.docker.io/bitnamicharts`).

## Commands

```bash
cd terraform && terraform init && terraform apply   # bootstrap cluster + flux
flux get kustomizations -A                          # reconcile status
flux reconcile kustomization flux-system            # force sync after push
kubectl get pods -A                                 # cluster status
```

`github_token` is a sensitive tf variable (PAT, repo scope). NEVER hardcode — pass via `TF_VAR_github_token` env or vault. No secret strings in manifests or tfvars committed.

## Guardrails

- Validate before commit: `terraform fmt -check` and `trivy config .`.
- Destructive ops (`terraform destroy`, `minikube delete`, `kubectl delete namespace`, Flux suspend/prune-all) require explicit confirmation — never run unprompted.
- Manifests are reproducible code. No manual UI/click steps, no live `kubectl patch` as a fix — change the file, commit, let Flux apply.
- Label deployments: `managed_by: caveman` + `environment: lab`. New app dir: copy the `labels:` block (`includeSelectors: false`) into its `kustomization.yaml`; new HelmRelease: add `spec.commonMetadata.labels` (reaches chart-rendered objects).

## Notes

- `readme.md` mentions a Makefile — none exists. Terraform is the real bootstrap path.
- Flux pins `v2.9.5` (`terraform/main.tf`); minikube k8s `v1.35.0`.
