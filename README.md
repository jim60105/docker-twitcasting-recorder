# Live Stream Recorder


## How to use

Volume mount your host to `/download`

Replace `[TWITCASTING_ID]` with the user account you want to monitor.

### Run once

```bash
docker run --rm -v ${PWD}:/download ghcr.io/jim60105/docker-twitcasting-recorder [TWITCASTING_ID] once
```

### Monitor

`10` in this example means 'Repeat check every `10` seconds'.

```bash
docker run --rm -v ${PWD}:/download ghcr.io/jim60105/docker-twitcasting-recorder [TWITCASTING_ID] loop 10
```

## Discord webhook notice

Discord webhook notice only works with environment variables.\
Of course, you can use docker run with -e\
But it is recommended to use Docker-compose deployment.

1. Clone this git repo.
1. Copy `.env_sample` to `.env`
1. Fill out `.env`
1. `docker-compose up -d`
