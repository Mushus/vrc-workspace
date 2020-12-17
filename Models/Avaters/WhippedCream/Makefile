MODEL_KEK         := WhippedCream
README_TEMPLATE   := README-for-priced.md
LISENCE_TEMPLATE  := LISENCE-for-priced.md
BLEND_FILE_NAME   := WhippedCream.blend
OUTPUT_DIR        := WhippedCream
MODEL_CONFIG_NAME := .model_config
OUTPUT_ZIP_FILE   := output.zip
IMAGE_NAMES       := BaseColor

REPO_ROOT         := $(shell git rev-parse --show-toplevel)
PATH_MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
CURRENT_DIR       := $(shell realpath --relative-to=$(REPO_ROOT) $(PATH_MAKEFILE_DIR))
PATH_UNITY_CACHE  := $(REPO_ROOT)/.cache/unity

DOCKER_IMAGE_BLENDER      := blender:latest
DOCKER_IMAGE_KRITA        := krita:latest
DOCKER_IMAGE_UNITY        := unity:win-latest
VOLUME_FLAG_BLENDER_DIR   := $(REPO_ROOT):/workspace
VOLUME_FLAG_CURRENT_DIR   := $(PATH_MAKEFILE_DIR):/workspace
VOLUME_FLAG_UNITY_DIR     := $(REPO_ROOT)/SDK3Avater:/root/project
VOLUME_FLAG_UNITY_LISENCE := $(REPO_ROOT)/.unity_cache/share:/root/.local
README_FILE_PATH          := $(REPO_ROOT)/templates/$(README_TEMPLATE)
LISENCE_FILE_PATH         := $(REPO_ROOT)/templates/$(LISENCE_TEMPLATE)
MODEL_CONFIG_PATH         := $(MODEL_CONFIG_NAME)
DOTENV_PATH               := $(REPO_ROOT)/.env
MODEL_CONTENT_PATH        := $(PATH_MAKEFILE_DIR)/MODEL_CONTENTS.md
OUT_MODEL_CONFIG_PATH     := $(OUTPUT_DIR)/.model_config
OUT_README_PATH           := $(OUTPUT_DIR)/README.md
OUT_LISENCE_PATH          := $(OUTPUT_DIR)/LISENCE.md
OUT_BLEND_PATH            := $(OUTPUT_DIR)/$(BLEND_FILE_NAME)
OUT_FBX_PATH              := $(OUTPUT_DIR)/$(shell basename $(BLEND_FILE_NAME) .blend).fbx
OUT_UNITYPACKAGE_PATH     := $(OUTPUT_DIR)/Avater.unitypackage

# custom script 
.PHONY: clean dist-all

clean:
	rm -rf $(OUTPUT_DIR)
	rm -f $(OUTPUT_ZIP_FILE)
	
output-all: \
	$(OUTPUT_DIR) \
	$(OUT_README_PATH) \
	$(OUT_LISENCE_PATH) \
	$(OUT_BLEND_PATH) \
	$(OUT_FBX_PATH) \
	$(OUTPUT_DIR)/BaseColor.png \
	$(OUTPUT_DIR)/BaseColor.psd \
	$(OUTPUT_DIR)/BaseColor.kra \
	$(OUTPUT_DIR)/Normal.psd \
	$(OUTPUT_DIR)/Normal.png \
	$(OUTPUT_DIR)/Normal.kra \
	$(OUTPUT_DIR)/MatCap.psd \
	$(OUTPUT_DIR)/MatCap.png \
	$(OUTPUT_DIR)/MatCap.kra \
	$(OUTPUT_DIR)/Displacement.psd \
	$(OUTPUT_DIR)/Displacement.png \
	$(OUTPUT_DIR)/Displacement.kra \
	$(OUT_UNITYPACKAGE_PATH) \
	;

# build files
$(OUTPUT_DIR):
	mkdir -p $(OUTPUT_DIR)

$(OUT_BLEND_PATH): $(BLEND_FILE_NAME)
	cp $< $@

$(OUT_FBX_PATH): $(BLEND_FILE_NAME)
	docker run \
		-v $(VOLUME_FLAG_BLENDER_DIR) \
		-it $(DOCKER_IMAGE_BLENDER) $(CURRENT_DIR)/$< \
		-P ./scripts/autoGenerate.py \
		-- $(CURRENT_DIR)/$(OUT_FBX_PATH)

$(OUT_MODEL_CONFIG_PATH): $(OUT_FBX_PATH)
	docker run \
		-v $(VOLUME_FLAG_BLENDER_DIR) \
		-it $(DOCKER_IMAGE_BLENDER) \
		-P ./scripts/getFbxInfo.py \
		-- $(CURRENT_DIR)/$(OUT_FBX_PATH) \
	| sed -n '/^\env:/p' \
	| sed 's/^\env:/export /' \
	| sed -e 's/\r//g' > $@

$(OUT_README_PATH): $(MODEL_CONFIG_PATH) $(OUT_MODEL_CONFIG_PATH) $(README_FILE_PATH)
	. ./$(MODEL_CONFIG_PATH) && \
	. ./$(OUT_MODEL_CONFIG_PATH) && \
	envsubst < $(README_FILE_PATH) > $@

$(OUT_LISENCE_PATH): $(MODEL_CONFIG_PATH) $(OUT_MODEL_CONFIG_PATH) $(LISENCE_FILE_PATH)
	. ./$(MODEL_CONFIG_PATH) && \
	. ./$(OUT_MODEL_CONFIG_PATH) && \
	envsubst < $(LISENCE_FILE_PATH) > $@

$(OUTPUT_ZIP_FILE): output-all
	zip -r $@ $(OUTPUT_DIR)/* -x $(OUT_MODEL_CONFIG_PATH)

$(OUTPUT_DIR)/%.png: %.kra
	docker run -it --rm \
		-v $(VOLUME_FLAG_CURRENT_DIR) \
		$(DOCKER_IMAGE_KRITA) \
		$< --export --export-filename $@

$(OUTPUT_DIR)/%.psd: %.kra
	docker run -it --rm \
		-v $(VOLUME_FLAG_CURRENT_DIR) \
		$(DOCKER_IMAGE_KRITA) \
		$< --export --export-filename $@

$(OUTPUT_DIR)/%.kra: %.kra
	cp $< $@

$(OUT_UNITYPACKAGE_PATH):
	docker run -it --rm \
		-v "$(REPO_ROOT)/SDK3Avater:/workspace" \
		-v "$(PATH_MAKEFILE_DIR):/output" \
		unitypackage-exporter:latest \
		-r -o /output/$@ Assets/$(MODEL_KEK)
