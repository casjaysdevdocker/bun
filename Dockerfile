FROM casjaysdevdocker/debian:latest as build

ARG TIMEZONE="America/New_York" \
  IMAGE_NAME="bun" \
  LICENSE="MIT" \
  DEBUG="" \
  PORTS="1-65535"

ENV TZ="$TIMEZONE" \
  DEBUG="$DEBUG" \
  SHELL="/bin/bash" \
  ENV="$HOME/.bashrc" \
  TERM="xterm-256color" \
  HOSTNAME="${HOSTNAME:-casjaysdev-$IMAGE_NAME}" \
  PORT="3000" \
  BUN_INSTALL="/usr/local/share/bun"

RUN set -ex; \
  mkdir -p "/usr/local/share/template-files/data/htdocs/www" && \
  apt-get update && apt-get upgrade -yy && apt-get install -yy \
  unzip && \
  curl -q -fsSL https://bun.sh/install | bash && \
  ln -sf /usr/local/share/bun/bun /usr/local/bin && \
  git clone "https://github.com/casjay-templates/bunjs" "/usr/local/share/template-files/data/htdocs/www/" && \
  cd "/usr/local/share/template-files/data/htdocs/www" && \
  /usr/local/bin/bun install

COPY ./bin/. /usr/local/bin/
COPY ./data/. /usr/local/share/template-files/data/
COPY ./config/. /usr/local/share/template-files/config/

RUN rm -Rf /tmp/* /bin/.gitkeep /config /data /var/lib/apt/lists/* /usr/local/share/template-files/data/htdocs/www/.git

FROM scratch

ARG BUILD_DATE="$(date +'%Y-%m-%d %H:%M')"

LABEL org.label-schema.name="bun" \
  org.label-schema.description="containerized version of bun" \
  org.label-schema.url="https://github.com/casjaysdevdocker/bun/bun" \
  org.label-schema.vcs-url="https://github.com/casjaysdevdocker/bun/bun" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.version=$BUILD_DATE \
  org.label-schema.vcs-ref=$BUILD_DATE \
  org.label-schema.license="WTFPL" \
  org.label-schema.vcs-type="Git" \
  org.label-schema.schema-version="latest" \
  org.label-schema.vendor="CasjaysDev" \
  maintainer="CasjaysDev <docker-admin@casjaysdev.com>"

ENV SHELL="/bin/bash" \
  ENV="$HOME/.bashrc" \
  TERM="xterm-256color" \
  HOSTNAME="casjaysdev-alpine" \
  TZ="${TZ:-America/New_York}" \
  TIMEZONE="$TIMEZONE" \
  PHP_SERVER="none" \
  PORT=""

COPY --from=build /. /

WORKDIR /data/htdocs/www

VOLUME [ "/config","/data" ]

EXPOSE $PORTS

ENTRYPOINT [ "tini", "-p", "SIGTERM", "--" ]
CMD [ "/usr/local/bin/entrypoint-bun.sh" ]
HEALTHCHECK --start-period=1m --interval=2m --timeout=3s CMD [ "/usr/local/bin/entrypoint-bun.sh", "healthcheck" ]
