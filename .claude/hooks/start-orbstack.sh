#!/usr/bin/env bash
# SessionStart hook: ensure OrbStack is running and the docker daemon answers
# before any terraform/minikube/kubectl work in this repo.
set -u

emit() { printf '{"systemMessage":"%s","suppressOutput":true}\n' "$1"; }

if docker info >/dev/null 2>&1; then
  exit 0
fi

open -a OrbStack >/dev/null 2>&1 || { emit "OrbStack not found (open -a OrbStack failed)"; exit 0; }

for _ in $(seq 1 40); do
  if docker info >/dev/null 2>&1; then
    emit "OrbStack started; docker daemon ready"
    exit 0
  fi
  sleep 1
done

emit "OrbStack launched but docker daemon not ready after 40s"
