FROM python:3.10-alpine

WORKDIR /
COPY twitcasting-recorder/requirements.txt .

RUN apk add --no-cache --virtual build-deps \
      gcc \
      libc-dev && \
    apk add --no-cache \
      bash \
      ffmpeg \
      dumb-init \
      curl && \
    pip install --no-cache-dir -r requirements.txt && \
    apk del build-deps

COPY record_twitcast.sh .
COPY twitcasting-recorder/main.py .

ENTRYPOINT [ "/usr/bin/dumb-init", "--", "/bin/bash", "record_twitcast.sh" ]