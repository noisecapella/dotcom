#!/usr/bin/env bash
set -e
mix coveralls.json -u --exclude=wallaby --trace
bash <(curl -s https://codecov.io/bash) -t "$CODECOV_UPLOAD_TOKEN"
