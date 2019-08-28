# -----------------------------------------------------------------------------
# SCRIPT CONFIGURATION
# -----------------------------------------------------------------------------

# Default Makefile configuration filename
CONFIG_FILE := Makefile.conf


# Explicitly check for the config file, otherwise make -k will proceed anyway.
ifeq ($(wildcard $(CONFIG_FILE)),)
	$(error $(CONFIG_FILE) not found. See $(CONFIG_FILE).example)
endif

include $(CONFIG_FILE)



# -----------------------------------------------------------------------------
# VARIABLES DEFINITION
# -----------------------------------------------------------------------------

# Default background color definition
ccback=\033[49m

# Foreground colors definition
ccred=\033[0;31m$(ccback)
ccgreen=\033[38;5;112m$(ccback)
ccblue=\033[38;5;33m$(ccback)
ccyellow=\033[0;33m$(ccback)
ccorange=\033[38;5;166m$(ccback)
ccwhite=\033[97m$(ccback)
ccpink=\033[35;40m$(ccback)
ccend=\033[0m

# -----------------------------------------------------------------------------
# FUNCTIONS DEFINITION
# -----------------------------------------------------------------------------

# Display help/usage message
define display_help_message
	@echo ""
	@echo "$(ccblue)USAGE:$(ccend)"
	@echo "  make $(ccpink)COMMAND$(ccend) | $(ccpink)COMPONENT$(ccend)"
	@echo ""

	@echo "$(ccblue)Build Commands:$(ccend)"
	@echo "  $(ccpink)setup$(ccend)         - create sandbox container"
	@echo "  $(ccpink)work$(ccend)          - start sandbox container and ssh into its '/workspace'"
	@echo "  $(ccpink)update-repos$(ccend)  - update repositories when updating 'go.mod'"
	@echo ""
	@echo "$(ccblue)Clean Commands:$(ccend)"
	@echo "  $(ccpink)clean$(ccend)         - clean up project's binaries and intermediate files"
	@echo "  $(ccpink)mrproper$(ccend)      - deep project cleansing"
	@echo "  $(ccpink)purge_docker$(ccend)  - purge Docker dangling images"
	@echo ""
endef

# Build containerized development environment (or sandbox)
#
# So that to isolate compiler toolsuite from the developer's host machine, the project
# is built inside an ephemeral Docker container (i.e. the latter survives the compilation
# time and is removed. We call such an ephemeral container a 'sandbox'. It contains all
# development tools, includiong the Golang toolsuite, the Bazel building tool and so.
define setup_development_sandbox
	@docker image build \
		--tag=$(SANDBOX_IMAGE_NAME) \
		--rm=true \
		--target=sandbox \
		--build-arg ARG_SANDBOX_LINUX=$(SANDBOX_LINUX) \
		--build-arg ARG_BAZEL_VERSION=$(BAZEL_VERSION) \
		--build-arg ARG_BAZEL_BUILDS=$(BAZEL_BUILDS) \
		--file=tooling/docker/Dockerfile.sandbox \
		tooling/docker
endef


# Start development sandbox (in interactive mode)
define start_development_sandbox
	@docker container run \
		--name $(SANDBOX_CONTAINER_NAME) \
		--hostname $(SANDBOX_IMAGE_NAME) \
		-it \
		--rm \
		--volume `pwd`/builds/bazel:$(BAZEL_BUILDS) \
		--volume `pwd`:/workspace \
		--entrypoint "/bin/bash" \
		$(SANDBOX_IMAGE_NAME)
endef


# Clean up project's binaries and intermediate files
define clean_project
	@rm -rf bazel-* || true
endef


# Build all project components inside an ephemeral building sandbox
define build_project
	@docker run \
		--name $(SANDBOX_CONTAINER_NAME)-build \
		--hostname $(SANDBOX_IMAGE_NAME)-build \
		--rm \
		--volume `pwd`/builds/bazel:$(BAZEL_BUILDS) \
		--volume `pwd`:/workspace \
		--entrypoint "bazel build //..." \
		$(SANDBOX_IMAGE_NAME)
endef

# Build a given project component in an ephemereal building sandbox
#
# For instance, the command 'make console' builds the 
# console component inside an ephemeral building sandbox.
# Any folder starting with '' prefix is considered as
# a project's component.
define build_component
	@echo "$(ccgreen)[INFO]$(ccend) Building $(ccblue)$(1)$(ccend) component ..."
	@docker run \
		--name $(1) \
		--hostname $(1) \
		--rm \
		--volume `pwd`:/workspace \
		--volume $(BAZEL_OUTPUT_PATH):$(BAZEL_OUTPUT_PATH) \
		$(SANDBOX_IMAGE_NAME) \
		bazel --output_user_root=$(BAZEL_OUTPUT_PATH) build //$(1) --incompatible_disallow_dict_plus=false
endef

# Test a given project component in an ephemereal testing sandbox
#
# For instance, the command 'make test_console' tests the 
# console component inside an ephemeral building sandbox.
# Any folder starting with '' prefix is considered as
# a project's component.
define test_component
	@echo "$(ccgreen)[INFO]$(ccend) Testing $(ccblue)$(1)$(ccend) component ..."
	@docker run \
		--name $(1) \
		--hostname $(1) \
		--rm \
		--volume `pwd`:/workspace \
		--volume $(BAZEL_OUTPUT_PATH):$(BAZEL_OUTPUT_PATH) \
		$(SANDBOX_IMAGE_NAME) \
		bazel --output_user_root=$(BAZEL_OUTPUT_PATH) test --platforms=@io_bazel_rules_go//go/toolchain:darwin_amd64 //$(1)
endef

# Visualize project's dependency graph
define visualize_project_dependency_graph
	@bazel query 'deps(//:main)' --output graph > graph.in
	@dot -Tpng < graph.in > graph.png
endef


# Test all project's components inside an ephemereal testing sandbox
define test_project
	@docker run \
		--name $(SANDBOX_CONTAINER_NAME)-test \
		--hostname $(SANDBOX_IMAGE_NAME)-test \
		--rm \
		--volume `pwd`:/workspace \
		--entrypoint "bazel test //..." \
		$(SANDBOX_IMAGE_NAME)
endef


# Deploy project on cloud stack, using an ephemereal ci/cd sandbox
define deploy_project
	@docker run \
		--name $(SANDBOX_CONTAINER_NAME)-deploy \
		--hostname $(SANDBOX_IMAGE_NAME)-deploy \
		--rm \
		--volume `pwd`:/workspace \
		--entrypoint "bazel deploy //..." \
		$(SANDBOX_IMAGE_NAME)
endef

# Update Golang modules repositories
#
# This command is run each time a new module is added, removed, or modified
# in the require section of the 'go.mod' file.
# In the future, a checksum on 'go.mod' could make the trick and automate
# this process.
define update_golang_repositories
	@bazel run //:gazelle -- update-repos --from_file=go.mod
endef


# Deep project cleansing
define cleanse_project
	$(call _remove_development_sandbox)
endef


# -----------------------------------------------------------------------------
# PRIVATE FUNCTIONS
# -----------------------------------------------------------------------------

# Check if the make command is executed inside the sandbox container.
#
# The Makefile's targets are intended to be called outside the sandbox container.
define _is_inside_sandbox_container
	@test -f /.dockerenv && (echo "$(ccred)[FATAL]$(ccend) Cannot run make command inside the sandbox" && false) || true
endef


# Remove development sandbox container and image
define _remove_sandbox_container_and_image
	@echo "       $(ccred)-$(ccend) stop and remove sandbox container"
	@docker container stop $(SANDBOX_CONTAINER_NAME) > /dev/null 2>&1 || true && docker container rm $(SANDBOX_CONTAINER_NAME) > /dev/null 2>&1 || true
	@echo "       $(ccred)-$(ccend) remove sandbox image"
	@docker image rm --force $(SANDBOX_IMAGE_NAME) > /dev/null 2>&1 || true
endef


# Purge dangling Docker images and containers
#
# When designing a Docker image, it is frequent that this process
# crashes, producing intermediate (hence dangling) file system layers.
# This function helps cleaning such 'junks'.
define _purge_docker_dangling_images
	@docker image prune -a
endef


# -----------------------------------------------------------------------------
# TARGETS DEFINITION
# -----------------------------------------------------------------------------

# NOTE:
# .PHONY directive defines targets that are not associated with files. Generally
# all targets which do not produce an output file with the same name as the target
# name should be .PHONY. This typically includes 'all', 'help', 'build', 'clean',
# and so on.

.PHONY: not_in_sandbox all $(COMPONENTS) help setup work clean check build release deploy doc test purge_docker update-repos

# Set default target if none is specified
.DEFAULT_GOAL := help

all: help

# Build a given component, such as, for instance 'make console'
$(COMPONENTS):
	$(call build_component,$@)

# Check if the make command is executed inside the sandbox (not the intended usage)
not_in_sandbox:
	$(call _is_inside_sandbox_container)

# Show help message
help: not_in_sandbox
	$(call display_help_message)

# Setup development environment
setup: not_in_sandbox
	@echo "$(ccgreen)[INFO]$(ccend) Setting up development sandbox ..."
	$(call setup_development_sandbox)

# Start development sandbox (for daily work)
work: not_in_sandbox
	@echo "$(ccgreen)[INFO]$(ccend) Starting development sandbox (in interactive mode) ..."
	$(call start_development_sandbox)

# Get rid of binaries and intermediate files
clean: not_in_sandbox
	@echo "$(ccgreen)[INFO]$(ccend) Cleaning project ..."
	$(call clean_project)

# Build and containerize all project's components
build:
	@echo "$(ccgreen)[INFO]$(ccend) Building project's components ..."
	$(call build_project)

# Build production library
release: clean
	@echo "$(ccgreen)[INFO]$(ccend) Building production project ..."
	$(call release_project)

# Generate project's documentation
doc:
	@echo "$(ccgreen)[INFO]$(ccend) Generating project's documentation ..."
	$(call generate_documentation)

# Execute various tests (unit, integration, document, ...)
test:
	@echo "$(ccgreen)[INFO]$(ccend) Testing project's components ..."
	$(call test_project)

# Deploy the project on the elastic cloud platform
deploy:
	@echo "$(ccgreen)[INFO]$(ccend) Deploying project on cloud stack ..."
	$(call deploy_project)

# Update Golang repositories (should be run each time 'go.mod' is modified)
update-repos: not_in_sandbox
	@echo "$(ccgreen)[INFO]$(ccend) Update Golang repositories ..."
	$(call update_golang_repositories)

# Deep project cleansing (delete sandbox container and image)
mrproper: not_in_sandbox
	@echo "$(ccred)[WARN]$(ccend) Deep project cleansing ..."
	$(call _remove_sandbox_container_and_image)

purge_docker: not_in_sandbox
	@echo "$(ccred)[WARN]$(ccend) Purge Docker dangling and unused images ..."
	$(call _purge_docker_dangling_images)
