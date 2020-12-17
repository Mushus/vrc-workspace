PATH_DOTENV        := .env
UNITY_LISENCE_NAME := Unity_v2018.x.ulf

PATH_MAKEFILE_DIR  := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PATH_UNITY_LISENCE := $(PATH_MAKEFILE_DIR)/.unity_lisence
PATH_UNITY_CACHE   := $(PATH_MAKEFILE_DIR)/.cache/unity

TAG_UNITY_WIN := 'unity:win-latest' 

.PHONY: build@blender, build@krita, build@unitypackage-exporter, build@unity, pre-activate@unity-win, activate@unity-win

build@blender:
	docker build ./.docker/blender -t blender:latest

build@krita:
	docker build ./.docker/krita -t krita:latest

build@unitypackage-exporter:
	docker build ./.docker/unitypackage-exporter -t unitypackage-exporter:latest

build@unity-win:
	docker build ./.docker/unity-win -t $(TAG_UNITY_WIN)

pre-activate@unity-win:
	export $(shell cat $(PATH_DOTENV) | xargs) && \
	docker run -it --rm \
		-v "$(PATH_UNITY_LISENCE):/root/project" \
		$(TAG_UNITY_WIN) \
		/opt/Unity/Editor/Unity -batchmode -projectPath /root/project \
    	-username $(UNITY_USERNAME) -password $(UNITY_PASSWORD) -quit -nographics -logFile \
		-createManualActivationFile \
	|| exit 0

activate@unity-win:
	export $(shell cat $(PATH_DOTENV) | xargs) && \
	docker run -it --rm \
		-v "$(PATH_UNITY_LISENCE):/root/project" \
		-v "$(PATH_UNITY_CACHE)/share:/root/.local/share/unity3d" \
		$(TAG_UNITY_WIN) \
		/opt/Unity/Editor/Unity -batchmode -projectPath /root/project \
    	-username $(UNITY_USERNAME) -password $(UNITY_PASSWORD) -quit -nographics -logFile \
		-manualLicenseFile "/root/project/$(UNITY_LISENCE_NAME)" \
	|| exit 0
