# syntax=docker/dockerfile:1

FROM python:3.10-alpine as python

# Setup venv
RUN python3 -m venv /venv --upgrade-deps
ENV PATH="/venv/bin:$PATH"

FROM python as build

# Install build dependencies
RUN apk add --no-cache build-base

WORKDIR /app
COPY twitcasting-recorder/requirements.txt .

RUN pip3 install --no-cache-dir -r requirements.txt

FROM python as final

# Copy venv
COPY --from=build /venv /venv

# Uninstall both inside and outside of venv
RUN pip3 uninstall -y setuptools pip && \
    pip3 uninstall -y setuptools pip

RUN apk add --no-cache curl dumb-init

# ffmpeg
COPY --link --from=mwader/static-ffmpeg:6.0 /ffmpeg /usr/local/bin/

COPY --chown=1001:1001 record_twitcast.sh /app/record_twitcast.sh
COPY --chown=1001:1001 twitcasting-recorder/main.py /app/main.py

RUN mkdir -p /download && chown 1001:1001 /download
VOLUME [ "/download" ]

USER 1001

ENTRYPOINT [ "dumb-init", "--", "/bin/sh", "/app/record_twitcast.sh" ]
