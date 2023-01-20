#!/bin/bash
# TwitCasting Live Stream Recorder

if [[ -z "$1" ]]; then
  echo "usage: $0 twitcasting_id [loop|once] [interval]"
  exit 1
fi

INTERVAL="${3:-10}"

# Discord message with mention role
if [[ -n "${DISCORD_WEBHOOK}" ]]; then
  _body="{
  \"content\": \"${DISCORD_MENTION} Twitcasting monitor start! \nhttps://twitcasting.tv/${1}/\",
  \"embeds\": [],
  \"components\": [
    {
      \"type\": 1,
      \"components\": [
        {
          \"type\": 2,
          \"style\": 5,
          \"label\": \"Twitcasting GO\",
          \"url\": \"https://twitcasting.tv/${1}/\"
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
    LOG_PREFIX=$(date +"[%m/%d/%y %H:%M:%S] [twitcasting@$1] ")
    STREAM_API="https://twitcasting.tv/streamserver.php?target=$1&mode=client"
    (curl -s "$STREAM_API" | grep -q '"live":true') && break

    echo "$LOG_PREFIX [VRB] The stream is not available now. Retry after $INTERVAL seconds..."
    sleep $INTERVAL
  done

  # Record using MPEG-2 TS format to avoid broken file caused by interruption
  echo "$LOG_PREFIX [INFO] Start recording..."

  # Discord message with mention role
  if [[ -n "${DISCORD_WEBHOOK}" ]]; then
    _body="{
  \"content\": \"${DISCORD_MENTION} Twitcasting Live Begins! \nhttps://twitcasting.tv/${1}/\",
  \"embeds\": [],
  \"components\": [
    {
      \"type\": 1,
      \"components\": [
        {
          \"type\": 2,
          \"style\": 5,
          \"label\": \"Twitcasting GO\",
          \"url\": \"https://twitcasting.tv/${1}/\"
        }
      ]
    }
  ]
}"

    curl -s -X POST -H 'Content-type: application/json' \
      -d "$_body" "$DISCORD_WEBHOOK"
  fi

  # Start recording
  python /main.py --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" "$1"
  LOG_PREFIX=$(date +"[%m/%d/%y %H:%M:%S] [twitcasting@$1] ")
  echo "$LOG_PREFIX [INFO] Stop recording $1"

  # Discord message with mention role
  if [[ -n "${DISCORD_WEBHOOK}" ]]; then
    _body="{
  \"content\": \"Twitcasting Live is over! \nhttps://twitcasting.tv/${1}/\",
  \"embeds\": [],
  \"components\": [
    {
      \"type\": 1,
      \"components\": [
        {
          \"type\": 2,
          \"style\": 5,
          \"label\": \"Check live history\",
          \"url\": \"https://twitcasting.tv/${1}/show/\"
        }
      ]
    }
  ]
}"
    curl -s -X POST -H 'Content-type: application/json' \
      -d "$_body" "$DISCORD_WEBHOOK"
  fi

  # Exit if we just need to record current stream
  [[ "$2" == "once" ]] && break
done
