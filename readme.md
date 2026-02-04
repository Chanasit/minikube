# Personal Minikube Setup

Local Kubernetes playground with GitOps (Flux), service mesh (Istio), observability, databases and stream processing — all bootstrapped via Makefile.

[![Minikube](https://img.shields.io/badge/Minikube-v1.33+-green?logo=minikube)](https://minikube.sigs.k8s.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.28+-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Flux](https://img.shields.io/badge/Flux-v2-blue?logo=flux)](https://fluxcd.io/)

## Purpose

This repository contains my personal configuration and automation scripts to quickly spin up a **local Kubernetes cluster** using **Minikube** with commonly used add-ons and operators:

- Calico CNI
- Istio service mesh
- Flux GitOps
- Elastic stack (Elasticsearch + Kibana)
- Redis
- Logging stack

## Prerequisites

Make sure you have these tools installed:

- [minikube](https://minikube.sigs.k8s.io/docs/start/) ≥ v1.30
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [helm](https://helm.sh/docs/intro/install/) ≥ v3.10
- [flux](https://fluxcd.io/flux/installation/) ≥ v2.0 (flux CLI)
- Decent amount of RAM (≥ 8–12 GB recommended when using Istio + Elastic + Flink)

## Quick Start

1. Start Minikube (choose driver that works best for you)

   ```bash
   minikube start --cpus=6 --memory=12288 --driver=docker   # example
   # or
   minikube start --profile orbstack --cpus=4 --memory=8192
