FROM alpine:3.12

RUN apk add --update --no-cache \
    --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing \
    --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community \
    blender

WORKDIR /workspace
ENTRYPOINT ["blender", "--background"]