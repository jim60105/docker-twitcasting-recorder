#!/bin/bash
# TwitCasting Live Stream Recorder

if [[ -z "${1}" ]]; then
  echo "usage: $0 twitcasting_id [loop|once] [interval]"
  exit 1
fi

ID="${1}"
shift

if [[ "${1}" == "loop" || "${1}" == "once" ]]; then
  LOOP="${1}"
  shift
fi

# Check if the next argument is a number and store it into INTERVAL
if [[ "$1" =~ ^[0-9]+$ ]]; then
  INTERVAL="$1"
  shift
else
  INTERVAL=10
fi

echo "ID: ${ID}"
echo "LOOP: ${LOOP}"
echo "INTERVAL: ${INTERVAL}"
echo "ARGS: $*"

# Discord message with mention role
if [[ -n "${DISCORD_WEBHOOK}" ]]; then
  _body="{
  \"content\": \"${DISCORD_MENTION} Twitcasting monitor start! \nhttps://twitcasting.tv/${ID}/\",
  \"embeds\": [],
  \"components\": [
    {
      \"type\": 1,
      \"components\": [
        {
          \"type\": 2,
          \"style\": 5,
          \"label\": \"Twitcasting GO\",
          \"url\": \"https://twitcasting.tv/${ID}/\"
        }
      ]
    }
  ]
}"

  curl -s -X POST -H 'Content-type: application/json' -d "$_body" "$DISCORD_WEBHOOK"
fi

while true; do
  # Monitor live streams of specific user
  while true; do
    LOG_PREFIX=$(date +"[%m/%d/%y %H:%M:%S] [twitcasting@${ID}] ")
    STREAM_API="https://twitcasting.tv/streamserver.php?target=${ID}&mode=client"
    (curl -s "$STREAM_API" | grep -q '"live":true') && break

    echo "$LOG_PREFIX [VRB] The stream is not available now. Retry after $INTERVAL seconds..."
    sleep "$INTERVAL"
  done

  # Record using MPEG-2 TS format to avoid broken file caused by interruption
  echo "$LOG_PREFIX [INFO] Start recording..."
  echo "ID: ${ID}"
  echo "ARGS: $*"

  # Discord message with mention role
  if [[ -n "${DISCORD_WEBHOOK}" ]]; then
    _body="{
  \"content\": \"${DISCORD_MENTION} Twitcasting Live Begins! \nhttps://twitcasting.tv/${ID}/\",
  \"embeds\": [],
  \"components\": [
    {
      \"type\": 1,
      \"components\": [
        {
          \"type\": 2,
          \"style\": 5,
          \"label\": \"Twitcasting GO\",
          \"url\": \"https://twitcasting.tv/${ID}/\"
        }
      ]
    }
  ]
}"

    curl -s -X POST -H 'Content-type: application/json' \
      -d "$_body" "$DISCORD_WEBHOOK"
  fi

  # Start recording
  if [ -z "$*" ]; then
    python /main.py "${ID}"
  else
    # shellcheck disable=SC2086
    python /main.py "$@" "${ID}"
  fi

  LOG_PREFIX=$(date +"[%m/%d/%y %H:%M:%S] [twitcasting@${ID}] ")
  echo "$LOG_PREFIX [INFO] Stop recording ${ID}"

  # Discord message with mention role
  if [[ -n "${DISCORD_WEBHOOK}" ]]; then
    _body="{
  \"content\": \"Twitcasting Live is over! \nhttps://twitcasting.tv/${ID}/\",
  \"embeds\": [],
  \"components\": [
    {
      \"type\": 1,
      \"components\": [
        {
          \"type\": 2,
          \"style\": 5,
          \"label\": \"Check live history\",
          \"url\": \"https://twitcasting.tv/${ID}/show/\"
        }
      ]
    }
  ]
}"
    curl -s -X POST -H 'Content-type: application/json' \
      -d "$_body" "$DISCORD_WEBHOOK"
  fi

  # Exit if we just need to record current stream
  [[ "$LOOP" == "once" ]] && break
done
