# Velero Module

Installs Velero for Kubernetes backup and restore.

This module creates:

- an S3 backup bucket
- bucket encryption, versioning, public access block, and lifecycle expiration
- an IRSA role and policy for Velero
- the Velero Helm release
- an optional daily backup schedule

Velero complements AWS Backup. AWS Backup protects cloud resources such as RDS and EBS; Velero protects Kubernetes cluster state such as namespaces, deployments, services, ingress, and CRDs.
