#!/usr/bin/env bash
set -euo pipefail

LAYER="${1:-platform}"
ENVIRONMENT="${2:-dev}"
terraform -chdir="${LAYER}/${ENVIRONMENT}" destroy
