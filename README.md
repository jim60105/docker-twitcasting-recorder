# Live Stream Recorder

## How to use

- Volume mount output folder to `/download`
- Replace `[TWITCASTING_ID]` in the following command with the channel id you want to monitor.
- Any other arguments will be passed to the underlying python script. Check [TwitCasting Recorder](https://github.com/jim60105/twitcasting-recorder?tab=readme-ov-file#usage) for more information.

### Monitor (default)

The standard operation is to monitor the channel, checking every 10 seconds, and record the live stream when it is live.  
To modify the interval frequency, you can specify the argument such as `loop 60`.

```bash
docker run --rm -v ${PWD}:/download ghcr.io/jim60105/twitcasting-recorder [TWITCASTING_ID]
docker run --rm -v ${PWD}:/download ghcr.io/jim60105/twitcasting-recorder [TWITCASTING_ID] loop 60
```

### Run once

Use `once` as the argument to run the script once and exit.

```bash
docker run --rm -v ${PWD}:/download ghcr.io/jim60105/twitcasting-recorder [TWITCASTING_ID] once
```

### Run once and specify output file name

Any other arguments will be passed to the underlying python script. Check [TwitCasting Recorder](https://github.com/jim60105/twitcasting-recorder?tab=readme-ov-file#usage) for more information.

```bash
docker run --rm -v ${PWD}:/download ghcr.io/jim60105/twitcasting-recorder [TWITCASTING_ID] once -o [OUTPUT_FILE_NAME]
```

## Discord webhook notification

The functionality of Discord webhook notification can be config by using the environment variables.  
While it is possible to use the -e option with docker run, it is strongly advised to use docker-compose deployment for a better choice.

1. Clone this git repo.
1. Copy `.env_sample` to `.env`
1. Fill out `.env`
1. `docker-compose up -d`

## LICENSE

<img src="https://github.com/jim60105/docker-twitcasting-recorder/assets/16995691/a280afe8-e29e-4b52-ba3a-07583aba4337" alt="open graph" width="200" />

[GNU GENERAL PUBLIC LICENSE Version 3](LICENSE)

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
