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
  kubernetes_version = "v1.35.0"
}

resource "minikube_cluster" "orbstack" {
  vm           = true
  driver       = "docker"
  cluster_name = "orbstack"
  cpus         = "6"
  memory       = "16g"
  nodes        = 1
  cni          = "bridge" # Allows pods to communicate with each other via DNS
  addons = [
    "default-storageclass",
    "storage-provisioner"
  ]
}

provider "kubernetes" {
  config_path    = pathexpand("~/.kube/config")
  config_context = minikube_cluster.orbstack.cluster_name
}

provider "github" {}
provider "flux" {
  kubernetes = { # ← Add this block to satisfy the validation
    config_path    = pathexpand("~/.kube/config")
    config_context = minikube_cluster.orbstack.cluster_name
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
