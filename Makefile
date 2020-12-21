PATH_DOTENV        := .env

TAG_UNITY_WIN := 'unity:win-latest' 

.PHONY: build@blender, build@krita, build@unitypackage-exporter, build@chromium-node, build@booth-uploader

build@blender:
	DOCKER_BUILDKIT=1 docker build ./.docker/blender -t blender:latest

build@krita:
	DOCKER_BUILDKIT=1 docker build ./.docker/krita -t krita:latest

build@unitypackage-exporter:
	DOCKER_BUILDKIT=1 docker build ./.docker/unitypackage-exporter -t unitypackage-exporter:latest

build@chromium-node:
	DOCKER_BUILDKIT=1 docker build ./.docker/chromium-node -t chromium-node:latest

build@booth-uploader: build@chromium-node
	DOCKER_BUILDKIT=1 docker build ./.docker/booth-uploader -t booth-uploader:latest