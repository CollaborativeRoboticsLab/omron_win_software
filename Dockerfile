FROM ubuntu:24.04

ARG DEFAULT_APP="MobilePlanner"
ARG TMFLOW_URL=""

ENV DEBIAN_FRONTEND=noninteractive \
    DEFAULT_APP=${DEFAULT_APP} \
    WINEPREFIX=/wine \
    WINEDEBUG=-all \
    WINEDLLOVERRIDES=mscoree,mshtml=

RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    ca-certificates \
    cabextract \
    curl \
    tini \
    unzip \
    wine32 \
    wine64 \
    winbind \
    xauth \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/omron

COPY exe/ /opt/omron/exe/
COPY scripts/run-omron-app.sh /usr/local/bin/run-omron-app
COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint

RUN if [ -n "$TMFLOW_URL" ]; then \
        mkdir -p /tmp/tmflow /opt/omron/exe/tmflow-download \
        && curl -fL "$TMFLOW_URL" -o /tmp/tmflow/tmflow.zip \
        && unzip -q /tmp/tmflow/tmflow.zip -d /opt/omron/exe/tmflow-download \
        && rm -rf /tmp/tmflow; \
    fi \
    && chmod +x /usr/local/bin/run-omron-app /usr/local/bin/docker-entrypoint \
    && ln -sf /usr/local/bin/run-omron-app /usr/local/bin/MobilePlanner \
    && ln -sf /usr/local/bin/run-omron-app /usr/local/bin/TMFlow \
    && mkdir -p "$WINEPREFIX" \
    && xvfb-run -a wineboot --init \
    && wineserver -w

ENTRYPOINT ["tini", "--", "/usr/local/bin/docker-entrypoint"]
CMD []

