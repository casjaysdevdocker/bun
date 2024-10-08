# Docker image for bun using the debian template
ARG LICENSE="MIT"
ARG IMAGE_NAME="bun"
ARG BUILD_DATE="Wed Mar 15 03:46:25 PM EDT 2023"
ARG LANGUAGE="en_US.UTF-8"
ARG TIMEZONE="America/New_York"
ARG WWW_ROOT_DIR="/data/htdocs"
ARG DEFAULT_FILE_DIR="/usr/local/share/template-files"
ARG DEFAULT_DATA_DIR="/usr/local/share/template-files/data"
ARG DEFAULT_CONF_DIR="/usr/local/share/template-files/config"
ARG DEFAULT_TEMPLATE_DIR="/usr/local/share/template-files/defaults"

ARG IMAGE_REPO="debian"
ARG IMAGE_VERSION="latest"
ARG CONTAINER_VERSION="${IMAGE_VERSION}"

ARG SERVICE_PORT=""
ARG EXPOSE_PORTS=""
ARG NODE_VERSION="system"
ARG NODE_MANAGER="system"

ARG USER="root"
ARG DISTRO_VERSION="bullseye"
ARG BUILD_VERSION="${DISTRO_VERSION}"

FROM tianon/gosu:latest AS gosu
FROM ${IMAGE_REPO}:${IMAGE_VERSION} AS build
ARG USER
ARG LICENSE
ARG LANGUAGE
ARG TIMEZONE
ARG IMAGE_NAME
ARG BUILD_DATE
ARG SERVICE_PORT
ARG EXPOSE_PORTS
ARG NODE_VERSION
ARG NODE_MANAGER
ARG BUILD_VERSION
ARG WWW_ROOT_DIR
ARG DEFAULT_FILE_DIR
ARG DEFAULT_DATA_DIR
ARG DEFAULT_CONF_DIR
ARG DEFAULT_TEMPLATE_DIR
ARG DISTRO_VERSION
ARG BUN_INSTALL="/usr/local/share/bun"

ARG PACK_LIST="bash bash-completion git curl wget sudo tini xz-utils iproute2 locales procps net-tools bsd-mailx unzip \
  "

ENV ENV=~/.bashrc
ENV SHELL="/bin/sh"
ENV TZ="${TIMEZONE}"
ENV TIMEZONE="${TZ}"
ENV container="docker"
ENV LANG="${LANGUAGE}"
ENV TERM="xterm-256color"
ENV HOSTNAME="casjaysdev-bun"
ENV DEBIAN_FRONTEND="noninteractive"
ENV BUN_INSTALL="${BUN_INSTALL}"

USER ${USER}
WORKDIR /root

COPY --from=gosu /usr/local/bin/gosu /usr/local/bin/gosu
COPY ./rootfs/. /

RUN set -ex; \
  mkdir -p "${DEFAULT_DATA_DIR}" "${DEFAULT_CONF_DIR}" "${DEFAULT_TEMPLATE_DIR}" ; \
  apt-get update && apt-get install -yy locales && echo "$LANG UTF-8" >"/etc/locale.gen" ; \
  dpkg-reconfigure --frontend=noninteractive locales ; update-locale LANG=$LANG ; \
  echo 'export DEBIAN_FRONTEND="'${DEBIAN_FRONTEND}'"' >"/etc/profile.d/apt.sh" && chmod 755 "/etc/profile.d/apt.sh" && \
  DEBIAN_CODENAME="$(grep -s 'VERSION_CODENAME=' /etc/os-release | awk -F'=' '{print $2}')" ; \
  [ -z "$DEBIAN_CODENAME" ] || sed -i "s|$DEBIAN_CODENAME|$DISTRO_VERSION|g" "/etc/apt/sources.list" ; \
  apt-get update -yy && apt-get upgrade -yy && apt-get install -yy ${PACK_LIST}

RUN touch "/etc/profile" "/root/.profile" ; \
  { [ -f "/etc/bash/bashrc" ] && cp -Rf "/etc/bash/bashrc" "/root/.bashrc" ; } || { [ -f "/etc/bashrc" ] && cp -Rf "/etc/bashrc" "/root/.bashrc" ; } || { [ -f "/etc/bash.bashrc" ] && cp -Rf "/etc/bash.bashrc" "/root/.bashrc" ; }; \
  sed -i 's|root:x:.*|root:x:0:0:root:/root:/bin/bash|g' "/etc/passwd" ; \
  grep -s -q 'alias quit' "/root/.bashrc" || printf '# Profile\n\n%s\n%s\n%s\n' '. /etc/profile' '. /root/.profile' "alias quit='exit 0 2>/dev/null'" >>"/root/.bashrc" ; \
  [ -f "/usr/local/etc/docker/env/default.sample" ] && [ -d "/etc/profile.d" ] && \
  cp -Rf "/usr/local/etc/docker/env/default.sample" "/etc/profile.d/container.env.sh" && chmod 755 "/etc/profile.d/container.env.sh" ; \
  update-alternatives --install /bin/sh sh /bin/bash 1

RUN set -ex ; \
  curl -q -fsSL "https://bun.sh/install" | bash && \
  ln -sf /usr/local/share/bun/bin/bun /usr/local/bin && \
  mkdir -p "${DEFAULT_DATA_DIR}/htdocs/www" && \
  git clone "https://github.com/casjay-templates/bunjs" "${DEFAULT_DATA_DIR}/htdocs/www/" && \
  rm -Rf ${DEFAULT_DATA_DIR}/htdocs/www/.git && \
  cd "${DEFAULT_DATA_DIR}/htdocs/www" && \
  /usr/local/bin/bun install

RUN echo 'Running cleanup' ; \
  apt-get clean

RUN rm -Rf "/config" "/data" ; \
  rm -rf /etc/systemd/system/*.wants/* ; \
  rm -rf /lib/systemd/system/systemd-update-utmp* ; \
  rm -rf /lib/systemd/system/anaconda.target.wants/*; \
  rm -rf /lib/systemd/system/local-fs.target.wants/* ; \
  rm -rf /lib/systemd/system/multi-user.target.wants/* ; \
  rm -rf /lib/systemd/system/sockets.target.wants/*udev* ; \
  rm -rf /lib/systemd/system/sockets.target.wants/*initctl* ; \
  rm -Rf /usr/share/doc/* /usr/share/info/* /tmp/* /var/tmp/* /var/cache/*/* ; \
  if [ -d "/lib/systemd/system/sysinit.target.wants" ]; then cd "/lib/systemd/system/sysinit.target.wants" && rm -f $(ls | grep -v systemd-tmpfiles-setup) ; fi

RUN echo "Init done"

FROM scratch
ARG USER
ARG LICENSE
ARG LANGUAGE
ARG TIMEZONE
ARG IMAGE_NAME
ARG BUILD_DATE
ARG SERVICE_PORT
ARG EXPOSE_PORTS
ARG NODE_VERSION
ARG NODE_MANAGER
ARG BUILD_VERSION
ARG DEFAULT_DATA_DIR
ARG DEFAULT_CONF_DIR
ARG DEFAULT_TEMPLATE_DIR
ARG DISTRO_VERSION

USER ${USER}
WORKDIR /root

LABEL maintainer="CasjaysDev <docker-admin@casjaysdev.pro>"
LABEL org.opencontainers.image.vendor="CasjaysDev"
LABEL org.opencontainers.image.authors="CasjaysDev"
LABEL org.opencontainers.image.vcs-type="Git"
LABEL org.opencontainers.image.name="${IMAGE_NAME}"
LABEL org.opencontainers.image.base.name="${IMAGE_NAME}"
LABEL org.opencontainers.image.license="${LICENSE}"
LABEL org.opencontainers.image.vcs-ref="${BUILD_VERSION}"
LABEL org.opencontainers.image.build-date="${BUILD_DATE}"
LABEL org.opencontainers.image.version="${BUILD_VERSION}"
LABEL org.opencontainers.image.schema-version="${BUILD_VERSION}"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/casjaysdevdocker/${IMAGE_NAME}"
LABEL org.opencontainers.image.vcs-url="https://github.com/casjaysdevdocker/${IMAGE_NAME}"
LABEL org.opencontainers.image.url.source="https://github.com/casjaysdevdocker/${IMAGE_NAME}"
LABEL org.opencontainers.image.documentation="https://hub.docker.com/r/casjaysdevdocker/${IMAGE_NAME}"
LABEL org.opencontainers.image.description="Containerized version of ${IMAGE_NAME}"
LABEL com.github.containers.toolbox="false"

ENV ENV=~/.bashrc
ENV SHELL="/bin/bash"
ENV TZ="${TIMEZONE}"
ENV TIMEZONE="${TZ}"
ENV LANG="${LANGUAGE}"
ENV PORT="${SERVICE_PORT}"
ENV ENV_PORTS="${EXPOSE_PORTS}"
ENV TERM="xterm-256color"
ENV NODE_VERSION="${NODE_VERSION}"
ENV NODE_MANAGER="${NODE_MANAGER}"
ENV CONTAINER_NAME="${IMAGE_NAME}"
ENV HOSTNAME="casjaysdev-${IMAGE_NAME}"
ENV USER="${USER}"

COPY --from=build /. /

VOLUME [ "/config","/data" ]

EXPOSE ${ENV_PORTS}

CMD [ "" ]
ENTRYPOINT [ "tini", "--", "/usr/local/bin/entrypoint.sh" ]
HEALTHCHECK --start-period=10m --interval=5m --timeout=15s CMD [ "/usr/local/bin/entrypoint.sh", "healthcheck" ]
