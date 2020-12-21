FROM alpine:3.12 AS builder

RUN mkdir /noto
ADD https://noto-website.storage.googleapis.com/pkgs/NotoSansCJKjp-hinted.zip /noto 
WORKDIR /noto
RUN unzip NotoSansCJKjp-hinted.zip


FROM alpine:3.12 AS runner

RUN apk add --update --no-cache \
    --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing \
    --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community \
    udev \
    # ttf-freefont \
    chromium \
    npm

RUN mkdir -p /usr/share/fonts/noto
COPY --from=builder /noto/*.otf /usr/share/fonts/noto
RUN chmod 644 -R /usr/share/fonts/noto/ && \
    fc-cache -fv
