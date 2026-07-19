#!/usr/bin/env bash
set -euo pipefail

LAYER="${1:-bootstrap}"
ENVIRONMENT="${2:-dev}"
BACKEND_CONFIG="${3:-backend.hcl}"

terraform -chdir="${LAYER}/${ENVIRONMENT}" init -backend-config="${BACKEND_CONFIG}"
