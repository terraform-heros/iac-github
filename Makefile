SHELL := /bin/bash

MOUNT_TARGET_DIRECTORY  = /app/src
BUILD_TOOLS_DOCKER_REPO = mineiros/build-tools

# Set default value for environment variable if there aren't set already
ifndef BUILD_TOOLS_VERSION
	BUILD_TOOLS_VERSION := latest
endif

ifndef BUILD_TOOLS_DOCKER_IMAGE
	BUILD_TOOLS_DOCKER_IMAGE := ${BUILD_TOOLS_DOCKER_REPO}:${BUILD_TOOLS_VERSION}
endif

ifndef TERRAFORM_PLANFILE
	TERRAFORM_PLANFILE := out.tfplan
endif

# Mounts the working directory inside a docker container and runs the pre-commit hooks
pre-commit-hooks:
	@echo "${GREEN}Start running the pre-commit hooks inside a docker container${RESET}"
	@docker run --rm \
		-v ${PWD}:${MOUNT_TARGET_DIRECTORY} \
		${BUILD_TOOLS_DOCKER_IMAGE} \
		sh -c "pre-commit run -a"

# Initialize a working directory containing Terraform configuration files
terraform-init:
	@echo "${GREEN}Start running terraform init inside a docker container${RESET}"
	@docker run --rm \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		-e GITHUB_TOKEN \
		-e GITHUB_ORGANIZATION \
		-e TF_IN_AUTOMATION \
		-v `pwd`:/app/src \
		${BUILD_TOOLS_DOCKER_IMAGE} \
		sh -c "terraform init -input=false"

# Mounts the working directory inside a new container and runs terraform plan
terraform-plan:
	@echo "${GREEN}Start running terraform plan inside a docker container${RESET}"
	@docker run --rm \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		-e GITHUB_TOKEN \
		-e GITHUB_ORGANIZATION \
		-e TF_IN_AUTOMATION \
		-v `pwd`:/app/src \
		${BUILD_TOOLS_DOCKER_IMAGE} \
		sh -c "terraform plan -input=false -out=${TERRAFORM_PLANFILE}"

# Mounts the working directory inside a new container and runs terraform apply
terraform-apply:
	@echo "${GREEN}Start running terraform apply inside a docker container${RESET}"
	@docker run --rm \
		-e AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY \
		-e GITHUB_TOKEN \
		-e GITHUB_ORGANIZATION \
		-e TF_IN_AUTOMATION \
		-v `pwd`:/app/src \
		${BUILD_TOOLS_DOCKER_IMAGE} \
		sh -c "terraform apply -input=false -auto-approve ${TERRAFORM_PLANFILE}"

.PHONY: pre-commit-hooks terraform-plan terraform-apply
