FROM casjaysdevdocker/debian:latest AS build

ARG DEBIAN_VERSION="bullseye"
ARG DEFAULT_DATA_DIR="/usr/local/share/template-files/data" 
ARG DEFAULT_CONF_DIR="/usr/local/share/template-files/config" 
ARG DEFAULT_TEMPLATE_DIR="/usr/local/share/template-files/defaults"
ARG PACK_LIST="bash sudo tini iproute2 unzip curl git"

ENV LANG=en_US.utf8 \
  ENV=ENV=~/.bashrc \
  TZ="America/New_York" \
  SHELL="/bin/sh" \
  TERM="xterm-256color" \
  TIMEZONE="${TZ:-$TIMEZONE}" \
  HOSTNAME="casjaysdev-bun" \
  DEBIAN_FRONTEND="noninteractive" \
  BUN_INSTALL="/usr/local/share/bun"

COPY ./rootfs/. /

RUN set -ex; \
  rm -Rf "/etc/apt/sources.list" ; \
  mkdir -p "${DEFAULT_DATA_DIR}" "${DEFAULT_CONF_DIR}" "${DEFAULT_TEMPLATE_DIR}" ; \
  echo 'export DEBIAN_FRONTEND="noninteractive"' >"/etc/profile.d/apt.sh" && chmod 755 "/etc/profile.d/apt.sh" && \
  echo "deb http://deb.debian.org/debian ${DEBIAN_VERSION} main contrib non-free" >>"/etc/apt/sources.list" ; \
  echo "deb http://deb.debian.org/debian ${DEBIAN_VERSION}-updates main contrib non-free" >>"/etc/apt/sources.list" ; \
  echo "deb http://deb.debian.org/debian-security/ ${DEBIAN_VERSION}-security main contrib non-free" >>"/etc/apt/sources.list" ; \
  apt-get update -yy && apt-get upgrade -yy && apt-get install -yy ${PACK_LIST} && \
  curl -q -fsSL "https://bun.sh/install" | bash && \
  ln -sf /usr/local/share/bun/bin/bun /usr/local/bin && \
  mkdir -p "${DEFAULT_DATA_DIR}/htdocs/www" && \
  git clone "https://github.com/casjay-templates/bunjs" "${DEFAULT_DATA_DIR}/htdocs/www/" && \
  rm -Rf ${DEFAULT_DATA_DIR}/htdocs/www/.git && \
  cd "${DEFAULT_DATA_DIR}/htdocs/www" && \
  /usr/local/bin/bun install

RUN echo 'Running cleanup' ; \
  update-alternatives --install /bin/sh sh /bin/bash 1 ; \
  apt-get clean ; \
  rm -Rf /usr/share/doc/* /usr/share/info/* /tmp/* /var/tmp/* ; \
  rm -Rf /usr/local/bin/.gitkeep /config /data /var/lib/apt/lists/* ; \
  rm -rf /lib/systemd/system/multi-user.target.wants/* ; \
  rm -rf /etc/systemd/system/*.wants/* ; \
  rm -rf /lib/systemd/system/local-fs.target.wants/* ; \
  rm -rf /lib/systemd/system/sockets.target.wants/*udev* ; \
  rm -rf /lib/systemd/system/sockets.target.wants/*initctl* ; \
  rm -rf /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* ; \
  rm -rf /lib/systemd/system/systemd-update-utmp* ; \
  if [ -d "/lib/systemd/system/sysinit.target.wants" ]; then cd "/lib/systemd/system/sysinit.target.wants" && rm $(ls | grep -v systemd-tmpfiles-setup) ; fi

FROM scratch

ARG SERVICE_PORT="3000" 
ARG EXPOSE_PORTS="1-65535" 
ARG PHP_SERVER="bun" 
ARG NODE_VERSION="system" 
ARG NODE_MANAGER="system" 
ARG BUILD_VERSION="latest" 
ARG LICENSE="MIT" 
ARG IMAGE_NAME="bun" 
ARG BUILD_DATE="Thu Oct 20 03:47:13 PM EDT 2022" 
ARG TIMEZONE="America/New_York"

LABEL maintainer="CasjaysDev <docker-admin@casjaysdev.com>" \
  org.opencontainers.image.vendor="CasjaysDev" \
  org.opencontainers.image.authors="CasjaysDev" \
  org.opencontainers.image.vcs-type="Git" \
  org.opencontainers.image.name="${IMAGE_NAME}" \
  org.opencontainers.image.base.name="${IMAGE_NAME}" \
  org.opencontainers.image.license="${LICENSE}" \
  org.opencontainers.image.vcs-ref="${BUILD_VERSION}" \
  org.opencontainers.image.build-date="${BUILD_DATE}" \
  org.opencontainers.image.version="${BUILD_VERSION}" \
  org.opencontainers.image.schema-version="${BUILD_VERSION}" \
  org.opencontainers.image.url="https://hub.docker.com/r/casjaysdevdocker/${IMAGE_NAME}" \
  org.opencontainers.image.vcs-url="https://github.com/casjaysdevdocker/${IMAGE_NAME}" \
  org.opencontainers.image.url.source="https://github.com/casjaysdevdocker/${IMAGE_NAME}" \
  org.opencontainers.image.documentation="https://hub.docker.com/r/casjaysdevdocker/${IMAGE_NAME}" \
  org.opencontainers.image.description="Containerized version of ${IMAGE_NAME}"

ENV LANG=en_US.utf8 \
  ENV=~/.bashrc \
  SHELL="/bin/bash" \
  PORT="${SERVICE_PORT}" \
  TERM="xterm-256color" \
  PHP_SERVER="${PHP_SERVER}" \
  NODE_VERSION="${NODE_VERSION}" \
  NODE_MANAGER="${NODE_MANAGER}" \
  CONTAINER_NAME="${IMAGE_NAME}" \
  TZ="${TZ:-America/New_York}" \
  TIMEZONE="${TZ:-$TIMEZONE}" \
  HOSTNAME="casjaysdev-${IMAGE_NAME}" \
  USER="root"

COPY --from=build /. /

USER root
WORKDIR /data/htdocs/www

VOLUME [ "/config","/data" ]

EXPOSE $EXPOSE_PORTS

#CMD [ "" ]
ENTRYPOINT [ "tini", "-p", "SIGTERM", "--", "/usr/local/bin/entrypoint.sh" ]
HEALTHCHECK --start-period=1m --interval=2m --timeout=3s CMD [ "/usr/local/bin/entrypoint.sh", "healthcheck" ]
