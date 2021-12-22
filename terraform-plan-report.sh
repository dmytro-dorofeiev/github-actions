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
TF_VARS_FILE=../tfvars/${WORKSPACE}.tfvars
# TF_BACKEND_FILE=../tfvars/${WORKSPACE}-backend.hcl

# CURR_WORKSPACE=$(terraform workspace show)

# echo "Init backend"
# if [[ "${CURR_WORKSPACE}" != "${WORKSPACE}" ]]; then
#   rm -rf .terraform
#   terraform init -backend-config="${TF_BACKEND_FILE}" -upgrade -input=false
# fi

# echo "Select/Create Terraform Workspace"
# terraform workspace select "${WORKSPACE}"
# IS_WORKSPACE_PRESENT=$?
# if [ "${IS_WORKSPACE_PRESENT}" -ne "0" ]; then
#   terraform workspace new "${WORKSPACE}"
# fi

# # Create plan file
terraform plan -no-color -input=false -var-file="${TF_VARS_FILE}" -out=plan >/dev/null 2>error.log
terraform show -no-color -json plan > plan.json
ls -l

# First way formatting
create_resources=$(jq -rM '[.resource_changes[]? | { resource: .address, action: .change.actions[] } | select (.action == "create") | "* \(.resource) will be \(.action)d"]' plan.json)
delete_resources=$(jq -rM '[.resource_changes[]? | { resource: .address, action: .change.actions[] } | select (.action == "delete") | "* \(.resource) will be \(.action)d"]' plan.json)
update_resources=$(jq -rM '[.resource_changes[]? | { resource: .address, action: .change.actions[] } | select (.action == "update") | "* \(.resource) will be \(.action)d"]' plan.json)
summary=$(jq -rM '[.resource_changes[]? | { resource: .address, action: .change.actions[] } | select (.action != "no-op")] |"Environment has \(length) changes" ' plan.json)

echo "
---------------------------------
Create resources
---------------------------------
${create_resources}

---------------------------------
Update resources
---------------------------------
${update_resources}

---------------------------------
Delete resources
---------------------------------
${delete_resources}

=================================
Summary: ${summary}
" > plan.log

# Second way of formatting
# changes=$(jq -r '[.resource_changes[]? | { resource: .address, action: .change.actions[] } | select (.action != "no-op")]' plan.json)
# summary=$(echo "${changes}" | jq -r '.   | "Environment has \(length) changes"')
# details=$(echo "${changes}" | jq -r '.[] | "* \(.resource) will be \(.action)d"')
# echo "${details}" > plan.log
# echo "Summary: ${summary} " >> plan.log
