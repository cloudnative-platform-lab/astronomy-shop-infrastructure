#!/usr/bin/env bash
set -euo pipefail

LAYER="${1:-bootstrap}"
ENVIRONMENT="${2:-dev}"
terraform -chdir="${LAYER}/${ENVIRONMENT}" validate
