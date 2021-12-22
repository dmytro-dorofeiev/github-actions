#!/bin/bash

# Usage help
if [ "$#" -lt 1 ]; then
  script_name=$(basename "$0")
  echo "Usage:   ${script_name} <env-name>"
  echo "Example: ${script_name} dev"
  exit 1
fi

# VARS
WORKSPACE="${1}"
TF_BACKEND_FILE=../tfvars/${WORKSPACE}-backend.hcl
TF_VARS_FILE=../tfvars/${WORKSPACE}.tfvars


if [[ ! -f "${TF_BACKEND_FILE}" && ! -f "${TF_VARS_FILE}" ]]; then
  echo "Please check that ${TF_VARS_FILE} and ${TF_BACKEND_FILE} files exist."
  exit 1
fi

CURR_WORKSPACE=$(terraform workspace show)

echo "Init backend"
if [[ "${CURR_WORKSPACE}" != "${WORKSPACE}" ]]; then
  rm -rf .terraform
  terraform init -backend-config="${TF_BACKEND_FILE}" -upgrade -input=false
fi

echo "Select/Create Terraform Workspace"
terraform workspace select "${WORKSPACE}"
IS_WORKSPACE_PRESENT=$?
if [ "${IS_WORKSPACE_PRESENT}" -ne "0" ]; then
  terraform workspace new "${WORKSPACE}"
fi

echo "Run terraform apply"
terraform apply -var-file="${TF_VARS_FILE}"
