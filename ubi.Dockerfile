# syntax=docker/dockerfile:1
ARG UID=1001

### Python
FROM registry.access.redhat.com/ubi9/ubi-minimal as base

ENV PYTHON_VERSION=3.11
ENV PYTHONUNBUFFERED=1
ENV PYTHONIOENCODING=UTF-8

RUN microdnf --setopt=install_weak_deps=0 --setopt=tsflags=nodocs -y install python3.11 && \
    microdnf -y clean all
RUN ln -s /usr/bin/python3.11 /usr/bin/python3 && \
    ln -s /usr/bin/python3.11 /usr/bin/python

### Build image
FROM base as build

RUN microdnf --setopt=install_weak_deps=0 --setopt=tsflags=nodocs -y install python3.11-pip findutils && \
    microdnf -y clean all

# RUN mount cache for multi-arch: https://github.com/docker/buildx/issues/549#issuecomment-1788297892
ARG TARGETARCH
ARG TARGETVARIANT

WORKDIR /app

# Install under /root/.local
ENV PIP_USER="true"
ARG PIP_NO_WARN_SCRIPT_LOCATION=0
ARG PIP_ROOT_USER_ACTION="ignore"

RUN --mount=type=cache,id=pip-$TARGETARCH$TARGETVARIANT,sharing=locked,target=/root/.cache/pip \
    --mount=source=twitcasting-recorder/requirements.txt,target=requirements.txt \
    pip3.11 install dumb-init -r requirements.txt && \
    # Cleanup
    find "/root/.local" -name '*.pyc' -print0 | xargs -0 rm -f || true ; \
    find "/root/.local" -type d -name '__pycache__' -print0 | xargs -0 rm -rf || true ;

### Final image
FROM base as final

ARG UID

# ffmpeg
COPY --link --from=mwader/static-ffmpeg:6.1.1 /ffmpeg /usr/local/bin/

# Copy dist and support arbitrary user ids (OpenShift best practice)
# https://docs.openshift.com/container-platform/4.14/openshift_images/create-images.html#use-uid_create-images
COPY --chmod=775 \
    --from=build /root/.local /root/.local
ENV PATH="/root/.local/bin:$PATH"
ENV PYTHONPATH "${PYTHONPATH}:/root/.local/lib/python3.11/site-packages" 

COPY --chown=$UID:0 --chmod=775 \
    record_twitcast.sh /app/record_twitcast.sh
COPY --chown=$UID:0 --chmod=775 \
    twitcasting-recorder/main.py /app/main.py

WORKDIR /
RUN install -d -m 775 -o $UID -g 0 /download
VOLUME [ "/download" ]
USER $UID

STOPSIGNAL SIGINT
ENTRYPOINT [ "dumb-init", "--", "/bin/sh", "/app/record_twitcast.sh" ]