# Common Variables
REPO       := ghcr.io/llm-gitops/serve
MODEL_REPO := ghcr.io/llm-gitops/modelss
VERSION    := v1.0.0
BUILD_DIR  := build
LLAMA_DIR  := llama-cpp-python

# Phony Targets Declaration
.PHONY: build-cpu build-gpu build-llama-7b-gpu build-llama-70b-gpu copy-dockerfile pull-artifact push-image

# Targets for copying dockerfiles based on the specified type
copy-dockerfile:
	@cp $(LLAMA_DIR)/Dockerfile.$(TYPE) $(BUILD_DIR)/Dockerfile

# Target for pulling artifacts
pull-artifact:
	@if [ -z "$(MODEL)" ] || [ -z "$(HASH)" ]; then \
		echo "MODEL and HASH variables must be set"; \
		exit 1; \
	fi
	@flux pull artifact --timeout=120m0s --output ./$(BUILD_DIR) oci://$(MODEL_REPO)/$(MODEL):$(VERSION)-$(HASH)
	@mv ./$(BUILD_DIR)/*.gguf ./$(BUILD_DIR)/model.gguf

# Target for building docker image
build-image:
	@docker build -t $(REPO)/$(IMAGE_NAME):$(VERSION)-$(TAG_SUFFIX) ./$(BUILD_DIR)

# Target for pushing docker image
push-image:
	@docker push $(REPO)/$(IMAGE_NAME):$(VERSION)-$(TAG_SUFFIX)

# Original Targets Refactored
build-cpu: TYPE=cpu
build-cpu: IMAGE_NAME=llama-cpp-python
build-cpu: TAG_SUFFIX=cpu
build-cpu: copy-dockerfile build-image push-image

build-gpu: TYPE=cublas
build-gpu: IMAGE_NAME=llama-cpp-python
build-gpu: TAG_SUFFIX=gpu
build-gpu: copy-dockerfile build-image push-image

build-llama-7b-gpu:  TYPE=cublas-bundle
build-llama-7b-gpu:  IMAGE_NAME=llama-2-7b-chat-q5km
build-llama-7b-gpu:  TAG_SUFFIX=gpu-bundled
build-llama-7b-gpu:  MODEL=llama-2-7b-chat-4k
build-llama-7b-gpu:  HASH=q5km-gguf
build-llama-7b-gpu:  pull-artifact copy-dockerfile build-image push-image

build-llama-70b-gpu: TYPE=cublas-bundle
build-llama-70b-gpu: IMAGE_NAME=llama-2-70b-chat-q5km
build-llama-70b-gpu: TAG_SUFFIX=gpu-bundled
build-llama-70b-gpu: MODEL=llama-2-70b-chat-4k
build-llama-70b-gpu: HASH=q5km-gguf
build-llama-70b-gpu: pull-artifact copy-dockerfile build-image push-image
