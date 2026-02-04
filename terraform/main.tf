terraform {
  required_providers {
    flux = {
      source  = "fluxcd/flux"
      version = ">= 1.2.2"
    }
    minikube = {
      source  = "scott-the-programmer/minikube"
      version = "~> 0.3" # Check latest on registry.terraform.io
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}
provider "minikube" {
  kubernetes_version = "v1.35"
}

# resource "minikube_cluster" "docker" {
#   driver       = "docker"
#   cluster_name = "terraform-provider-minikube-acc-docker"
#   addons = [
#     "default-storageclass",
#     "storage-provisioner"
#   ]
# }

resource "minikube_cluster" "orb" {
  vm           = true
  driver       = "docker"
  cluster_name = "orb-minikube"
  nodes        = 1
  cni          = "bridge" # Allows pods to communicate with each other via DNS
  addons = [
    "default-storageclass",
    "storage-provisioner"
  ]
}

provider "kubernetes" {
  # host                   = minikube_cluster.orb.host
  # client_certificate     = minikube_cluster.orb.client_certificate
  # client_key             = minikube_cluster.orb.client_key
  # cluster_ca_certificate = minikube_cluster.orb.cluster_ca_certificate
  config_path    = pathexpand("~/.kube/config")
  config_context = minikube_cluster.orb.cluster_name
}

provider "github" {}
provider "flux" {
  kubernetes = { # ← Add this block to satisfy the validation
    config_path    = pathexpand("~/.kube/config")
    config_context = minikube_cluster.orb.cluster_name
  }
  git = {
    url    = "https://github.com/Chanasit/minikube.git"
    branch = "master"
    # https auth
    http = {
      username = "git"            # can be anything when using token
      password = var.github_token # PAT with repo scope
    }
  }

}

resource "github_repository" "this" {
  name        = "minikube"
  description = "GitOps repo for Flux"
  visibility  = "public" # or public
  auto_init   = true
}

resource "flux_bootstrap_git" "this" {
  path     = "clusters/apps" # folder in repo where Flux will look
  interval = "1m"
  version  = "v2.4.0" # optional: pin Flux version
  # components_extra = ["image-reflector-controller", "image-automation-controller"] # if needed
}

# Optional: secure PAT via variable (recommended)
variable "github_token" {
  type      = string
  sensitive = true
}
