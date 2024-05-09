# syntax=docker/dockerfile:1
ARG UID=1001
ARG VERSION=EDGE
ARG RELEASE=0

########################################
# Build stage
########################################
FROM python:3.12-slim as build

# RUN mount cache for multi-arch: https://github.com/docker/buildx/issues/549#issuecomment-1788297892
ARG TARGETARCH
ARG TARGETVARIANT

WORKDIR /source

# Install under /root/.local
ENV PIP_USER="true"
ARG PIP_NO_WARN_SCRIPT_LOCATION=0
ARG PIP_ROOT_USER_ACTION="ignore"
ARG PIP_NO_COMPILE="true"
ARG PIP_DISABLE_PIP_VERSION_CHECK="true"

# Install requirements
RUN --mount=type=cache,id=pip-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/pip \
    --mount=source=twitcasting-recorder/requirements.txt,target=requirements.txt,rw \
    pip install -U --force-reinstall pip setuptools wheel && \
    pip install -r requirements.txt && \
    find "/root/.local" -name '*.pyc' -print0 | xargs -0 rm -f || true ; \
    find "/root/.local" -type d -name '__pycache__' -print0 | xargs -0 rm -rf || true ;

########################################
# Compile with Nuitka
########################################
FROM build as compile

ARG TARGETARCH
ARG TARGETVARIANT

# https://nuitka.net/user-documentation/tips.html#control-where-caches-live
ENV NUITKA_CACHE_DIR_CCACHE=/cache
ENV NUITKA_CACHE_DIR_DOWNLOADS=/cache
ENV NUITKA_CACHE_DIR_CLCACHE=/cache
ENV NUITKA_CACHE_DIR_BYTECODE=/cache
ENV NUITKA_CACHE_DIR_DLL_DEPENDENCIES=/cache

# Install build dependencies for Nuitka
RUN --mount=type=cache,id=apt-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=aptlists-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/lib/apt/lists \
    echo 'deb http://deb.debian.org/debian bookworm-backports main' > /etc/apt/sources.list.d/backports.list && \
    apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    patchelf ccache clang upx-ucl

# Install Nuitka
RUN --mount=type=cache,id=pip-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/pip \
    pip install nuitka

# Compile with nuitka
RUN --mount=type=cache,id=nuitka-$TARGETARCH$TARGETVARIANT,target=/cache \
    --mount=source=twitcasting-recorder,target=.,rw \
    python3 -m nuitka \
    --python-flag=nosite,-O \
    --clang \
    --lto=yes \
    # The upx plugin will stop when any error occurs, such as the file is too large.(768MB)
    # https://github.com/upx/upx/issues/374
    --enable-plugins=upx \
    --output-dir=/ \
    --report=/compilationreport.xml \
    --standalone \
    --deployment \
    --remove-output \
    main.py 

########################################
# Report stage
########################################
FROM scratch AS report

ARG UID
COPY --link --chown=$UID:0 --chmod=775 --from=compile /compilationreport.xml /

########################################
# Final stage
########################################
FROM debian:bookworm-slim as final

# Install runtime dependencies
RUN --mount=type=cache,id=apt-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=aptlists-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/var/lib/apt/lists \
    apt-get update && apt-get install -y --no-install-recommends \
    libxcb1 curl ca-certificates

# ffmpeg
COPY --link --from=ghcr.io/jim60105/static-ffmpeg-upx:7.0-1 /ffmpeg /usr/bin/
# COPY --link --from=ghcr.io/jim60105/static-ffmpeg-upx:7.0-1 /ffprobe /usr/bin/

# dumb-init
COPY --link --from=ghcr.io/jim60105/static-ffmpeg-upx:7.0-1 /dumb-init /usr/bin/

# Create directories with correct permissions
ARG UID
RUN install -d -m 775 -o $UID -g 0 /download && \
    install -d -m 775 -o $UID -g 0 /licenses && \
    install -d -m 775 -o $UID -g 0 /app

# Copy licenses (OpenShift Policy)
COPY --link --chown=$UID:0 --chmod=775 LICENSE /licenses/Dockerfile.LICENSE
COPY --link --chown=$UID:0 --chmod=775 twitcasting-recorder/LICENSE /licenses/twitcasting-recorder.LICENSE

# Copy dependencies and code (and support arbitrary uid for OpenShift best practice)
COPY --link --chown=$UID:0 --chmod=775 --from=compile /main.dist /app
COPY --link --chown=$UID:0 --chmod=775 record_twitcast.sh /app/record_twitcast.sh

ENV PATH="/app:$PATH"

WORKDIR /

VOLUME [ "/download" ]

USER $UID

STOPSIGNAL SIGINT

# Use dumb-init as PID 1 to handle signals properly
ENTRYPOINT [ "dumb-init", "--", "/bin/sh", "/app/record_twitcast.sh" ]

ARG VERSION
ARG RELEASE
LABEL name="jim60105/docker-twitcasting-recorder" \
    # Authors for twitcasting-recorder
    vendor="prinsss,jim60105" \
    # Maintainer for this docker image
    maintainer="jim60105" \
    # Dockerfile source repository
    url="https://github.com/jim60105/docker-twitcasting-recorder" \
    version=${VERSION} \
    # This should be a number, incremented with each change
    release=${RELEASE} \
    io.k8s.display-name="twitcasting-recorder" \
    summary="TwitCasting Recorder: Just another Python implementation of TwitCasting live stream recorder." \
    description="For more information about this tool, please visit the following website: https://github.com/jim60105/twitcasting-recorder."
