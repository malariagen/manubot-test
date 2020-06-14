#!/usr/bin/env bash

## deploy-pr.sh: run during a CI build to deploy TODO.

# Set options for extra caution & debugging
set -o errexit \
    -o nounset \
    -o pipefail

echo >&2 "[INFO] WIP: This event is a pull request."
echo >&2 "[INFO] WIP: SHA $GITHUB_PULL_REQUEST_SHA"
