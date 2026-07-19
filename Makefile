ENV ?= dev
LAYER ?= bootstrap
TF_DIR := $(LAYER)/$(ENV)
BACKEND_CONFIG ?= backend.hcl

.PHONY: remote-state-init remote-state-plan remote-state-apply init fmt validate plan apply destroy lint security drift

remote-state-init:
	terraform -chdir=bootstrap/remote-state init

remote-state-plan:
	terraform -chdir=bootstrap/remote-state plan

remote-state-apply:
	terraform -chdir=bootstrap/remote-state apply

init:
	terraform -chdir=$(TF_DIR) init -backend-config=$(BACKEND_CONFIG)

fmt:
	terraform fmt -recursive

validate:
	terraform -chdir=$(TF_DIR) validate

plan:
	terraform -chdir=$(TF_DIR) plan -out=plan.out

apply:
	terraform -chdir=$(TF_DIR) apply plan.out

destroy:
	terraform -chdir=$(TF_DIR) destroy

lint:
	tflint --recursive

security:
	tfsec .
	checkov -d .

drift:
	terraform -chdir=$(TF_DIR) plan -detailed-exitcode
