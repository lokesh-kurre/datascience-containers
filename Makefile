
CMD := 
UV_ENV_FILE := .env

include build_arg.properties

.PHONY: help version clean build run start-jupyter-server venv-setup start-code code build-vscode-web run-vscode-web

help:
	@echo "Targets:"
	@echo "  make version           Show pinned VS Code/build values"
	@echo "  make build             Build base notebook image"
	@echo "  make run               Run base notebook image"
	@echo "  make build-vscode-web  Build VS Code web image using build_arg.properties"
	@echo "  make run-vscode-web    Run VS Code web image"
	@echo "  make clean             Remove local test container"
	@echo ""
	@echo "Notes:"
	@echo "  - Override values with: make build-vscode-web VSCODE_VERSION=1.124.2"
	@echo "  - Arbitrary docker flags: make run-vscode-web ARGS='-e NB_PREFIX=/vscode'"

version:
	@echo "Build Mode:" $(BUILD_MODE)
	@echo "VSCode Version:" $(VSCODE_VERSION)
	@echo "VSCode Git Hash:" $(VSCODE_GIT_HASH)
	@echo "Ubuntu Version:" $(UBUNTU_VERSION)
	@echo "Python Version:" $(PYTHON_VERSION)


build-vscode-web:
	docker build --progress plain \
		$(shell awk '!/^#/ && NF { gsub(/[ \t]*=[ \t]*/, "="); gsub(/#.*$$/, ""); print "--build-arg", $$0 }' build_arg.properties) \
		-t lokeshkurre/vscode-web:ubuntu$(UBUNTU_VERSION)-vscode$(VSCODE_VERSION)-py$(PYTHON_VERSION)-runtime -f dists/vscode-web/Dockerfile .

stop-vscode-web:
	docker stop test-vscode-web || true

run-vscode-web: stop-vscode-web
	docker run -it --rm --net=host \
		-v /var/run/docker.sock:/var/run/docker.sock \
		--name test-vscode-web $(ARGS) lokeshkurre/vscode-web:ubuntu$(UBUNTU_VERSION)-vscode$(VSCODE_VERSION)-py$(PYTHON_VERSION)-runtime $(CMD)