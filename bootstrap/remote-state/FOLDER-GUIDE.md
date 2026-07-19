# Remote State Folder Guide

Folder path

bootstrap/remote-state

Main purpose

This folder creates the shared Terraform backend.

Terraform needs a safe place to store state. State is the record of what Terraform created in AWS. Without remote state, Terraform state stays local on your machine, which is risky. If the local file is lost, Terraform may no longer know what it owns.

This folder creates two important resources.

1. S3 bucket
   Stores Terraform state files.

2. DynamoDB table
   Locks Terraform state so two Terraform commands do not change the same state at the same time.

Why this folder must run first

Every environment needs remote state.

Dev bootstrap needs state.
Staging bootstrap needs state.
Prod bootstrap needs state.
Platform dev needs state.
Platform staging needs state.
Platform prod needs state.

So remote-state must exist before you run dev, staging, or prod.

Files in this folder

main.tf

This is the main resource file. It creates the S3 bucket, public access block, versioning, encryption, ownership controls, and DynamoDB lock table.

variables.tf

This declares the values this folder needs, such as AWS region, state bucket name, lock table name, force destroy behavior, and tags.

outputs.tf

This prints the created bucket name and lock table name so you can use them in backend configuration.

versions.tf

This says which Terraform version and AWS provider version this root expects.

README.md

This is a human note file for the remote-state folder.

What you should understand

The state bucket is not application storage.
It is for Terraform state only.

The DynamoDB table is not application data.
It is only for Terraform locking.

The state bucket should not be public.
The state bucket should have versioning.
The state bucket should have encryption.
The lock table should exist before other Terraform roots use it.

Important values for your project

State bucket name: astronomy-shop-241766333730-tfstate
Lock table name: terraform-locks
Region: ap-south-1

Common errors you already saw

BucketAlreadyOwnedByYou means the bucket already exists in your account. That is not always bad. It means Terraform may need import or state alignment.

ResourceNotFoundException for DynamoDB means Terraform backend is trying to lock state using a table that does not exist.

NoSuchBucket means the backend is pointing to a bucket that does not exist or still has a placeholder name.

What to change here

Usually only change:

- state_bucket_name value when applying this root.
- lock_table_name if you intentionally choose a different lock table.
- tags if project ownership changes.

What not to change casually

Do not casually enable force_destroy_state_bucket.
That can allow deletion of a bucket even when state objects exist.

Do not remove versioning.
Versioning helps recover older state.

Do not remove encryption.
State can contain sensitive infrastructure data.

How to explain this in an interview

I created a dedicated remote-state bootstrap layer before creating environments. It creates an encrypted, versioned S3 bucket for Terraform state and a DynamoDB table for state locking. This prevents local-only state, reduces corruption risk, and separates backend foundation from environment infrastructure.
