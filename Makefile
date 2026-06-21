TARGET ?= final
BUILD_TYPE ?= cpu

CMD :=
ARGS :=

include build_arg.properties


GIT_REPO := $(shell git config --get remote.origin.url)
GIT_COMMIT := $(shell git rev-parse HEAD)
GIT_BRANCH := $(shell git branch --show-current)
GIT_DIRTY := $(shell test -n "$$(git status --porcelain)" && echo true || echo false)
BUILD_DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
VERSION := $(shell git describe --tags --always --dirty)


IMAGE_NAME := lokeshkurre/vscode-web

ifeq ($(BUILD_TYPE),gpu)
IMAGE_TAG := ubuntu$(UBUNTU_VERSION)-py$(PYTHON_VERSION)-vscode$(VSCODE_VERSION)-cuda$(CUDA_MAJOR).$(CUDA_MINOR)
else
IMAGE_TAG := ubuntu$(UBUNTU_VERSION)-py$(PYTHON_VERSION)-vscode$(VSCODE_VERSION)-cpu
endif

IMAGE := $(IMAGE_NAME):$(IMAGE_TAG)


BUILD_ARGS := $(shell awk '\
	!/^#/ && NF { \
	print "--build-arg", $$0 \
	}' build_arg.properties)


.PHONY: version build build-cpu build-gpu run


version:
	@echo "Image:       $(IMAGE)"
	@echo "Target:      $(TARGET)"
	@echo "Build Type:  $(BUILD_TYPE)"
	@echo "Commit:      $(GIT_COMMIT)"
	@echo "Version:     $(VERSION)"
	@echo "Dirty:       $(GIT_DIRTY)"


build:
	docker build \
		--progress plain \
		--target $(TARGET) \
		--build-arg BUILD_TYPE=$(BUILD_TYPE) \
		--build-arg GIT_REPO="$(GIT_REPO)" \
		--build-arg GIT_COMMIT="$(GIT_COMMIT)" \
		--build-arg GIT_BRANCH="$(GIT_BRANCH)" \
		--build-arg GIT_DIRTY="$(GIT_DIRTY)" \
		--build-arg BUILD_DATE="$(BUILD_DATE)" \
		--build-arg VERSION="$(VERSION)" \
		$(BUILD_ARGS) \
		-t $(IMAGE) \
		-f dists/vscode-web/Dockerfile \
		.


build-cpu:
	$(MAKE) build \
		BUILD_TYPE=cpu


build-gpu:
	$(MAKE) build \
		BUILD_TYPE=gpu


run:
	docker run \
		-it \
		--rm \
		--net=host \
		-v /var/run/docker.sock:/var/run/docker.sock \
		$(ARGS) \
		$(IMAGE) \
		$(CMD)