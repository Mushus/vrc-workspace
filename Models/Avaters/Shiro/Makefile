MODEL_KEK          := Shiro
README_TEMPLATE    := README-for-free.md
LISENCE_TEMPLATE   := LISENCE-for-free.md
BLEND_FILE_NAME    := Shiro.blend
OUTPUT_DIR         := Shiro
MODEL_CONFIG_NAME  := .model_config
UPLOAD_CONFIG_NAME := .upload_config
OUTPUT_ZIP_FILE    := output.zip
IMAGE_NAMES        := BaseColor

REPO_ROOT         := $(shell git rev-parse --show-toplevel)
PATH_MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
CURRENT_DIR       := $(shell realpath --relative-to=$(REPO_ROOT) $(PATH_MAKEFILE_DIR))

DOCKER_IMAGE_BLENDER      := blender:latest
DOCKER_IMAGE_KRITA        := krita:latest
DOCKER_IMAGE_UPLOADER     := booth-uploader:latest
DOCKER_IMAGE_EXPORTER     := unitypackage-exporter:latest
VOLUME_FLAG_BLENDER_DIR   := $(REPO_ROOT):/workspace
VOLUME_FLAG_CURRENT_DIR   := $(PATH_MAKEFILE_DIR):/workspace
VOLUME_COOKIE_CACHE_PATH  := $(REPO_ROOT)/.cache/cookie:/cache
README_FILE_PATH          := $(REPO_ROOT)/templates/$(README_TEMPLATE)
LISENCE_FILE_PATH         := $(REPO_ROOT)/templates/$(LISENCE_TEMPLATE)
MODEL_CONFIG_PATH         := $(MODEL_CONFIG_NAME)
UPLOAD_CONFIG_PATH        := $(UPLOAD_CONFIG_NAME)
OUT_MODEL_CONFIG_PATH     := $(OUTPUT_DIR)/.model_config
OUT_UPLOAD_CONFIG_PATH    := $(OUTPUT_DIR)/.upload_config
OUT_README_PATH           := $(OUTPUT_DIR)/README.md
OUT_LISENCE_PATH          := $(OUTPUT_DIR)/LISENCE.md
OUT_BLEND_PATH            := $(OUTPUT_DIR)/$(BLEND_FILE_NAME)
OUT_FBX_PATH              := $(OUTPUT_DIR)/$(shell basename $(BLEND_FILE_NAME) .blend).fbx
OUT_UNITYPACKAGE_PATH     := $(OUTPUT_DIR)/Avater.unitypackage

# custom script 
.PHONY: clean upload

clean:
	rm -rf $(OUTPUT_DIR)
	rm -f $(OUTPUT_ZIP_FILE)

$(OUTPUT_ZIP_FILE): \
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
	$(OUT_UNITYPACKAGE_PATH) \
	;
	zip -r $@ $(OUTPUT_DIR)/* -x $(OUT_MODEL_CONFIG_PATH) -x $(OUT_UPLOAD_CONFIG_PATH)

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
		$(DOCKER_IMAGE_EXPORTER) \
		-r -o /output/$@ Assets/$(MODEL_KEK)

$(OUT_UPLOAD_CONFIG_PATH): $(OUT_README_PATH) $(OUT_LISENCE_PATH) $(UPLOAD_CONFIG_PATH)
	MODEL_DESCRIPTION=`cat $(OUT_README_PATH) $(OUT_LISENCE_PATH) | python3 -c 'import json,sys; sys.stdout.write(json.dumps(sys.stdin.read()))'` && \
	export MODEL_DESCRIPTION && \
	envsubst < $(UPLOAD_CONFIG_PATH) > $@

upload: $(OUTPUT_ZIP_FILE) $(OUT_UPLOAD_CONFIG_PATH)
	cat $(OUT_UPLOAD_CONFIG_PATH) \
	| docker run -i --rm \
		-v $(VOLUME_FLAG_CURRENT_DIR) \
		-v $(VOLUME_COOKIE_CACHE_PATH) \
		-e UPLOADER_USERNAME \
		-e UPLOADER_PASSWORD \
		$(DOCKER_IMAGE_UPLOADER) \
		upload --cookie-path /cache/.cookie
