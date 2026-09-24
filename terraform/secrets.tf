# App credentials generated per cluster at apply time — nothing secret lives in git.
# Values stay in the local terraform.tfstate (gitignored). Rotate: terraform apply -replace=random_password.<name>
# Manifests reference these Secrets by name (secretKeyRef / existingSecret).

locals {
  kafka_client_users = ["app1", "logstash", "metrics"] # order must match sasl.client.users in clusters/apps/logging/kafka.yaml
  secret_labels = {
    managed_by  = "caveman"
    environment = "lab"
  }
}

# alphanumeric only: values are embedded in JAAS strings, fluent-bit config and a comma list
resource "random_password" "kafka_client" {
  for_each = toset(local.kafka_client_users)
  length   = 32
  special  = false
}

resource "random_password" "kafka_inter_broker" {
  length  = 32
  special = false
}

resource "random_password" "kafka_controller" {
  length  = 32
  special = false
}

# alphanumeric only: rendered unquoted into the Loki s3 storage config
resource "random_password" "loki_minio" {
  length  = 32
  special = false
}

resource "random_password" "redis" {
  length  = 32
  special = false
}

resource "random_password" "weave_admin" {
  length  = 24
  special = false
}

# logging/, redis-system/ and weave/ namespaces are owned by Flux (namespace.yaml). Wait for Flux to create them
# instead of creating them here, so there is a single owner.
resource "terraform_data" "wait_app_namespaces" {
  triggers_replace = [flux_bootstrap_git.this.id]

  provisioner "local-exec" {
    command = <<-EOT
      kubectl --context ${minikube_cluster.orbstack.cluster_name} wait --for=create namespace/logging namespace/redis-system namespace/weave --timeout=10m
    EOT
  }
}

resource "kubernetes_secret" "kafka_sasl" {
  metadata {
    name      = "kafka-sasl"
    namespace = "logging"
    labels    = local.secret_labels
  }
  data = merge(
    {
      "client-passwords"      = join(",", [for u in local.kafka_client_users : random_password.kafka_client[u].result])
      "inter-broker-password" = random_password.kafka_inter_broker.result
      "controller-password"   = random_password.kafka_controller.result
      # provisioning Job authenticates as the first client user (chart: templates/secrets.yaml)
      "system-user-password" = random_password.kafka_client[local.kafka_client_users[0]].result
    },
    { for u in local.kafka_client_users : "${u}-password" => random_password.kafka_client[u].result },
  )
  depends_on = [terraform_data.wait_app_namespaces]
}

# Loki MinIO root credentials; injected into the loki HelmRelease via spec.valuesFrom
# (clusters/apps/logging/loki.yaml). Name must not be loki-minio: the minio subchart owns that Secret.
resource "kubernetes_secret" "loki_minio" {
  metadata {
    name      = "loki-minio-root"
    namespace = "logging"
    labels    = local.secret_labels
  }
  data = {
    rootUser     = "loki"
    rootPassword = random_password.loki_minio.result
  }
  depends_on = [terraform_data.wait_app_namespaces]
}

# Redis auth; referenced by auth.existingSecret in clusters/apps/redis-system/redis.yaml
resource "kubernetes_secret" "redis_auth" {
  metadata {
    name      = "redis-auth"
    namespace = "redis-system"
    labels    = local.secret_labels
  }
  data = {
    "redis-password" = random_password.redis.result
  }
  depends_on = [terraform_data.wait_app_namespaces]
}

resource "kubernetes_secret" "weave_admin" {
  metadata {
    name      = "cluster-user-auth"
    namespace = "weave"
    labels    = local.secret_labels
  }
  data = {
    username = "admin"
    password = random_password.weave_admin.bcrypt_hash # stable: generated once with the password
  }
  depends_on = [terraform_data.wait_app_namespaces]
}

output "weave_admin_password" {
  description = "Weave GitOps UI login for user admin (terraform output -raw weave_admin_password)"
  value       = random_password.weave_admin.result
  sensitive   = true
}
