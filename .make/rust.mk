## DO NOT EDIT!
# This file was provisioned by Terraform
# File origin: https://github.com/Arrow-air/tf-github/tree/main/src/templates/all/.make/rust.mk

RUST_IMAGE_NAME     ?= ghcr.io/arrow-air/tools/arrow-rust
RUST_IMAGE_TAG      ?= latest
CARGO_MANIFEST_PATH ?= Cargo.toml
CARGO_INCREMENTAL   ?= 1
RUSTC_BOOTSTRAP     ?= 0
RELEASE_TARGET      ?= x86_64-unknown-linux-musl
PUBLISH_DRY_RUN     ?= 1

# function with a generic template to run docker with the required values
# Accepts $1 = command to run, $2 = additional command flags (optional)
ifeq ("$(CARGO_MANIFEST_PATH)", "")
cargo_run = echo "$(BOLD)$(YELLOW)No Cargo.toml found in any of the subdirectories, skipping cargo check...$(SGR0)"
else
cargo_run = docker run \
	--name=$(DOCKER_NAME)-$@ \
	--rm \
	--user `id -u`:`id -g` \
	--workdir=/usr/src/app \
	-v "$(SOURCE_PATH)/:/usr/src/app" \
	-v "$(SOURCE_PATH)/.cargo/registry:/usr/local/cargo/registry" \
	-e CARGO_INCREMENTAL=$(CARGO_INCREMENTAL) \
	-e RUSTC_BOOTSTRAP=$(RUSTC_BOOTSTRAP) \
	-t $(RUST_IMAGE_NAME):$(RUST_IMAGE_TAG) \
	cargo $(1) --manifest-path "$(CARGO_MANIFEST_PATH)" $(2)
endif

rust-docker-pull:
	@echo docker pull -q $(RUST_IMAGE_NAME):$(RUST_IMAGE_TAG)

.help-rust:
	@echo ""
	@echo "$(SMUL)$(BOLD)$(GREEN)Rust$(SGR0)"
	@echo "  $(YELLOW)All cargo commands will use '--manifest-path $(CARGO_MANIFEST_PATH)'$(SGR0)"
	@echo "  $(BOLD)rust-build$(SGR0)       -- Run 'cargo build'"
	@echo "  $(BOLD)rust-release$(SGR0)     -- Run 'cargo build --release --target RELEASE_TARGET'"
	@echo "                     (RELEASE_TARGET=$(RELEASE_TARGET))"
	@echo "  $(BOLD)rust-publish$(SGR0)     -- Run 'cargo publish --package $(PACKAGE_NAME)-client-grpc'"
	@echo "                     uses '--dry-run' by default, automation uses PUBLISH_DRY_RUN=0 to upload crate"
	@echo "  $(BOLD)rust-clean$(SGR0)       -- Run 'cargo clean'"
	@echo "  $(BOLD)rust-check$(SGR0)       -- Run 'cargo check'"
	@echo "  $(BOLD)rust-test$(SGR0)        -- Run 'cargo test --all'"
	@echo "  $(BOLD)rust-example-ARG$(SGR0) -- Run 'cargo run --example ARG' (replace ARG with example name)"
	@echo "  $(BOLD)rust-clippy$(SGR0)      -- Run 'cargo clippy --all -- -D warnings'"
	@echo "  $(BOLD)rust-fmt$(SGR0)         -- Run 'cargo fmt --all -- --check' to check rust file formats."
	@echo "  $(BOLD)rust-tidy$(SGR0)        -- Run 'cargo fmt --all' to fix rust file formats if needed."
	@echo "  $(CYAN)Combined targets$(SGR0)"
	@echo "  $(BOLD)rust-test-all$(SGR0)    -- Run targets: rust-build rust-check rust-test rust-clippy rust-fmt"
	@echo "  $(BOLD)rust-all$(SGR0)         -- Run targets; rust-clean rust-test-all rust-release"

# Rust / cargo targets
check-cargo-registry:
	if [ ! -d "$(SOURCE_PATH)/.cargo/registry" ]; then mkdir -p "$(SOURCE_PATH)/.cargo/registry" ; fi

.SILENT: check-cargo-registry rust-docker-pull

rust-build: check-cargo-registry rust-docker-pull
	@echo "$(CYAN)Running cargo build...$(SGR0)"
	@$(call cargo_run,build)

rust-release: rust-docker-pull
	@echo "$(CYAN)Running cargo build --release...$(SGR0)"
	@$(call cargo_run,build,--release --target $(RELEASE_TARGET))

rust-publish: rust-docker-pull
	@echo "$(CYAN)Running cargo build --release...$(SGR0)"
ifeq ("$(PUBLISH_DRY_RUN)", "0")
	@echo $(call cargo_run,publish,--package $(PACKAGE_NAME)-client-grpc --target $(RELEASE_TARGET))
else
	@$(call cargo_run,publish,--dry-run --package $(PACKAGE_NAME)-client-grpc --target $(RELEASE_TARGET))
endif

rust-clean: check-cargo-registry rust-docker-pull
	@echo "$(CYAN)Running cargo clean...$(SGR0)"
	@$(call cargo_run,clean)

rust-check: check-cargo-registry rust-docker-pull
	@echo "$(CYAN)Running cargo check...$(SGR0)"
	@$(call cargo_run,check)

rust-test: check-cargo-registry rust-docker-pull
	@echo "$(CYAN)Running cargo test...$(SGR0)"
	@$(call cargo_run,test,--all)

rust-example-%: check-cargo-registry rust-docker-pull
	@echo "$(YELLOW)cargo run --example $* ...$(SGR0)"
	@$(call cargo_run,run --example $*)

rust-clippy: check-cargo-registry rust-docker-pull
	@echo "$(CYAN)Running clippy...$(SGR0)"
	@$(call cargo_run,clippy,--all -- -D warnings)

rust-fmt: check-cargo-registry rust-docker-pull
	@echo "$(CYAN)Running and checking Rust codes formats...$(SGR0)"
	@$(call cargo_run,fmt,--all -- --check)

rust-tidy: check-cargo-registry rust-docker-pull
	@echo "$(CYAN)Running rust file formatting fixes...$(SGR0)"
	@$(call cargo_run,fmt,--all)

rust-test-all: rust-build rust-check rust-test rust-clippy rust-fmt
rust-all: rust-clean rust-test-all rust-release
