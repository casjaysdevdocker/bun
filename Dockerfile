FROM casjaysdevdocker/alpine:latest AS build

ARG alpine_version="v3.16"

ARG TIMEZONE="America/New_York" \
  IMAGE_NAME="bun" \
  LICENSE="MIT" \
  PORTS=""

ENV TZ="$TIMEZONE" \
  SHELL="/bin/bash" \
  TERM="xterm-256color" \
  HOSTNAME="${HOSTNAME:-casjaysdev-$IMAGE_NAME}" \
  BUN_INSTALL="/usr/local/share/bun"

RUN set -ex; \
  rm -Rf "/etc/apk/repositories"; \
  echo "http://dl-cdn.alpinelinux.org/alpine/$alpine_version/main" >> "/etc/apk/repositories"; \
  echo "http://dl-cdn.alpinelinux.org/alpine/$alpine_version/community" >> "/etc/apk/repositories"; \
  if [ "$alpine_version" = "edge" ]; then echo "http://dl-cdn.alpinelinux.org/alpine/$alpine_version/testing" >> "/etc/apk/repositories" ; fi ; \
  apk update --update-cache && \
  curl -fsSL https://bun.sh/install | bash && \
  ln -sf /usr/local/share/bun/bun /usr/local/bin

COPY ./bin/. /usr/local/bin/
COPY ./data/. /usr/local/share/template-files/data/
COPY ./config/. /usr/local/share/template-files/config/

RUN rm -Rf /bin/.gitkeep /config /data /var/cache/apk/*

FROM scratch
ARG BUILD_DATE="2022-10-12" \
  BUILD_VERSION="latest" \
  BUN_INSTALL="/usr/local/share/bun"

LABEL maintainer="CasjaysDev <docker-admin@casjaysdev.com>" \
  org.opencontainers.image.vcs-type="Git" \
  org.opencontainers.image.name="bun" \
  org.opencontainers.image.base.name="bun" \
  org.opencontainers.image.license="$LICENSE" \
  org.opencontainers.image.vcs-ref="$BUILD_VERSION" \
  org.opencontainers.image.build-date="$BUILD_DATE" \
  org.opencontainers.image.version="$BUILD_VERSION" \
  org.opencontainers.image.schema-version="$BUILD_VERSION" \
  org.opencontainers.image.url="https://hub.docker.com/r/casjaysdevdocker/bun" \
  org.opencontainers.image.vcs-url="https://github.com/casjaysdevdocker/bun" \
  org.opencontainers.image.url.source="https://github.com/casjaysdevdocker/bun" \
  org.opencontainers.image.documentation="https://hub.docker.com/r/casjaysdevdocker/bun" \
  org.opencontainers.image.vendor="CasjaysDev" \
  org.opencontainers.image.authors="CasjaysDev" \
  org.opencontainers.image.description="Containerized version of bun"

ENV SHELL="/bin/bash" \
  TERM="xterm-256color" \
  HOSTNAME="casjaysdev-bun" \
  TZ="${TZ:-America/New_York}" \
  TIMEZONE="$$TIMEZONE" \
  PHP_SERVER="none" \
  PORT=""

COPY --from=build /. /

WORKDIR /root

VOLUME [ "/config","/data" ]

EXPOSE $PORTS

ENTRYPOINT [ "tini", "-p", "SIGTERM", "--" ]
CMD [ "/usr/local/bin/entrypoint-bun.sh" ]
HEALTHCHECK --start-period=1m --interval=2m --timeout=3s CMD [ "/usr/local/bin/entrypoint-bun.sh", "healthcheck" ]

