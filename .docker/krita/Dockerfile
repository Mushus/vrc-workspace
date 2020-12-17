FROM alpine:3.12

RUN apk add --update --no-cache \
    --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing \
    --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community \
    --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main \
    xvfb dbus krita

# virtual display
ENV DISPLAY :1
RUN dbus-uuidgen

COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

WORKDIR /workspace
ENTRYPOINT ["/entrypoint.sh"]