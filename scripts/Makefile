# MODEL_KEY        := "[MODEL_KEY]"
# README_TEMPLATE  := "[README_TEMPLATE]"
# LISENCE_TEMPLATE := "[LISENCE_TEMPLATE]"
NAME_OUTPUT      ?= dist
NAME_OUTPUT_ZIP  ?= output.zip
FILE_FROM_KRA    ?=
FILE_COPIED      ?=
FILE_FROM_BLEND  ?=
FILE_MAIN_FBX    ?=

NAME_README        := README.md
NAME_LISENCE       := LISENCE.md
NAME_MODEL_CONFIG  := .model_config
NAME_UPLOAD_CONFIG := .upload_config
NAME_UNITYPACKAGE  := Avater.unitypackage

ABS_REPO_ROOT          := $(shell git rev-parse --show-toplevel)
PATH_MAKEFILE_DIR      := $(abspath .)
CURRENT_DIR            := $(shell realpath --relative-to=$(ABS_REPO_ROOT) $(PATH_MAKEFILE_DIR))
PATH_TEMPLATE          := $(ABS_REPO_ROOT)/templates
PATH_OUTPUT            := $(NAME_OUTPUT)
PATH_PACKAGED          := $(PATH_OUTPUT)/$(MODEL_KEY)
PATH_ZIP               := $(PATH_OUTPUT)/$(NAME_OUTPUT_ZIP)
PATH_OUT_MODEL_CONFIG  := $(PATH_OUTPUT)/$(NAME_MODEL_CONFIG)
PATH_OUT_UPLOAD_CONFIG := $(PATH_OUTPUT)/$(NAME_UPLOAD_CONFIG)
PATH_OUT_README        := $(PATH_PACKAGED)/$(NAME_README)
PATH_OUT_LISENCE       := $(PATH_PACKAGED)/$(NAME_LISENCE)
PATH_OUT_UNITYPACKAGE  := $(PATH_PACKAGED)/$(NAME_UNITYPACKAGE)
PATH_OUT_MAIN_FBX      := $(PATH_PACKAGED)/$(FILE_MAIN_FBX)
PATH_README_TEMPLATE   := $(PATH_TEMPLATE)/$(README_TEMPLATE)
PATH_LISENCE_TEMPLATE  := $(PATH_TEMPLATE)/$(LISENCE_TEMPLATE)
PATH_UPLOAD_CONFIG     := $(NAME_UPLOAD_CONFIG)
PATH_MODEL_CONFIG      := $(NAME_MODEL_CONFIG)

DOCKER_IMAGE_BLENDER  := blender:latest
DOCKER_IMAGE_KRITA    := krita:latest
DOCKER_IMAGE_UPLOADER := booth-uploader:latest

# custom script
.PHONY: clean zip upload

clean:
	rm -rf $(PATH_OUTPUT)

zip: $(PATH_ZIP)

upload: $(PATH_ZIP) $(PATH_OUT_UPLOAD_CONFIG)
	cat $(PATH_OUT_UPLOAD_CONFIG) \
	| docker run -i --rm \
		-v $(PATH_MAKEFILE_DIR):/workspace \
		-v $(ABS_REPO_ROOT)/.cache/cookie:/cache \
		-e UPLOADER_USERNAME \
		-e UPLOADER_PASSWORD \
		$(DOCKER_IMAGE_UPLOADER) \
		upload --cookie-path /cache/.cookie

define COPIED
$(addprefix $(PATH_PACKAGED)/,$(1)): $(1) $(PATH_PACKAGED)
	cp $$< $$@
endef

define CONVERT_FROM_BLEND
$(addprefix $(PATH_PACKAGED)/,$(1)): $(addprefix $(basename $(1)), .blend) $(PATH_PACKAGED)
	docker run -it --rm\
		-v $(ABS_REPO_ROOT):/workspace \
		$(DOCKER_IMAGE_BLENDER) $(CURRENT_DIR)/$$< \
		-P ./scripts/autoGenerate.py \
		-- $(CURRENT_DIR)/$$@
endef

define CONVERT_FROM_KRITA
$(addprefix $(PATH_PACKAGED)/,$(1)): $(addprefix $(basename $(1)), .kra) $(PATH_PACKAGED)
	docker run -it --rm \
		-v $(PATH_MAKEFILE_DIR):/workspace \
		$(DOCKER_IMAGE_KRITA) \
		$$< --export --export-filename $$@
endef

define ARCHIVE_ZIP
	cd $(PATH_OUTPUT) && zip $(abspath $@) $(shell realpath --relative-to=$(PATH_OUTPUT) $(1))

endef

$(PATH_ZIP): \
	$(PATH_OUT_README) \
	$(PATH_OUT_LISENCE) \
	$(PATH_OUT_UNITYPACKAGE) \
	$(addprefix $(PATH_PACKAGED)/, $(FILE_FROM_BLEND)) \
	$(addprefix $(PATH_PACKAGED)/, $(FILE_FROM_KRA)) \
	$(addprefix $(PATH_PACKAGED)/, $(FILE_COPIED)) \
	;
	$(foreach x, $?, $(call ARCHIVE_ZIP, $(x)))

# dist
$(PATH_OUTPUT):
	mkdir -p $@

# dist/[AVATER_NAME]
$(PATH_PACKAGED):
	mkdir -p $@

# .model_config
$(PATH_OUT_MODEL_CONFIG): $(PATH_OUT_MAIN_FBX) $(PATH_PACKAGED)
	docker run -it --rm \
		-v $(ABS_REPO_ROOT):/workspace \
		$(DOCKER_IMAGE_BLENDER) -P ./scripts/getFbxInfo.py -- $(CURRENT_DIR)/$< \
	| sed -n '/^\env:/p' \
	| sed 's/^\env:/export /' \
	| sed -e 's/\r//g' > $@

# README
$(PATH_OUT_README): $(PATH_MODEL_CONFIG) $(PATH_OUT_MODEL_CONFIG) $(PATH_README_TEMPLATE) $(PATH_PACKAGED)
	. ./$(PATH_MODEL_CONFIG) && \
	. ./$(PATH_OUT_MODEL_CONFIG) && \
	envsubst < $(PATH_README_TEMPLATE) > $@

#LISENCE
$(PATH_OUT_LISENCE): $(PATH_MODEL_CONFIG) $(PATH_OUT_MODEL_CONFIG) $(PATH_LISENCE_TEMPLATE) $(PATH_PACKAGED)
	. ./$(PATH_MODEL_CONFIG) && \
	. ./$(PATH_OUT_MODEL_CONFIG) && \
	envsubst < $(PATH_LISENCE_TEMPLATE) > $@

# コピーされるファイル
$(foreach x, $(FILE_COPIED), $(eval $(call COPIED, $(x))))

# Kritaから変換されるファイル
$(foreach x, $(FILE_FROM_KRA), $(eval $(call CONVERT_FROM_KRITA, $(x))))

# Blenderから変換されるファイル
$(foreach x, $(FILE_FROM_BLEND), $(eval $(call CONVERT_FROM_BLEND, $(x))))

# unitypackageファイル
$(PATH_OUT_UNITYPACKAGE):
	docker run -it --rm \
		-v "$(ABS_REPO_ROOT)/SDK3Avater:/workspace" \
		-v "$(PATH_MAKEFILE_DIR):/output" \
		unitypackage-exporter:latest -r -o /output/$@ Assets/$(MODEL_KEY)

# .upload_configファイル
$(PATH_OUT_UPLOAD_CONFIG): $(PATH_OUT_README) $(PATH_OUT_LISENCE) $(PATH_UPLOAD_CONFIG)
	MODEL_DESCRIPTION=`cat $(PATH_OUT_README) $(PATH_OUT_LISENCE) | python3 -c 'import json,sys; sys.stdout.write(json.dumps(sys.stdin.read()))'` && \
	export MODEL_DESCRIPTION && \
	envsubst < $(PATH_UPLOAD_CONFIG) > $@

