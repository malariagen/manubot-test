#!/usr/bin/env bash

## deploy-pr.sh: run during a CI build to deploy the built webpage dir for this PR to gh-pages/PR/[PR_number]

# Set options for extra caution & debugging
set -o errexit \
    -o nounset \
    -o pipefail

echo >&2 "[INFO] WIP: This event is a pull request."
echo >&2 "[INFO] WIP: SHA $GITHUB_PULL_REQUEST_SHA"
echo >&2 "[INFO] WIP: num $GITHUB_PULL_REQUEST_NUMBER"
echo >&2 "[INFO] WIP: branch $GITHUB_PULL_REQUEST_HEAD_REF"

# The branch $GITHUB_PULL_REQUEST_HEAD_REF is already checked out and built

# set environment variables for either Travis or GitHub Actions
REPO_SLUG=${TRAVIS_REPO_SLUG:-$GITHUB_REPOSITORY}
COMMIT=${TRAVIS_COMMIT:-$GITHUB_SHA}
CI_BUILD_WEB_URL=${CI_BUILD_WEB_URL:-$TRAVIS_BUILD_WEB_URL}
CI_JOB_WEB_URL=${CI_JOB_WEB_URL:-$TRAVIS_JOB_WEB_URL}

# Don't do this
#BRANCH=${TRAVIS_BRANCH:-master}

# Add commit hash to the README
OWNER_NAME="$(dirname "$REPO_SLUG")"
REPO_NAME="$(basename "$REPO_SLUG")"
export REPO_SLUG COMMIT OWNER_NAME REPO_NAME
envsubst < webpage/README.md > webpage/README-complete.md
mv webpage/README-complete.md webpage/README.md

# Configure git
git config --global push.default simple
git config --global user.email "$(git log --max-count=1 --format='%ae')"
git config --global user.name "$(git log --max-count=1 --format='%an')"

# Don't do this
#git checkout "$BRANCH"

# Configure deployment credentials
MANUBOT_DEPLOY_VIA_SSH=true
git remote set-url origin "git@github.com:$REPO_SLUG.git"
if [ -v MANUBOT_SSH_PRIVATE_KEY ] && [ "$MANUBOT_SSH_PRIVATE_KEY" != "" ]; then
  echo >&2 "[INFO] Detected MANUBOT_SSH_PRIVATE_KEY. Will deploy via SSH."
elif [ -v MANUBOT_ACCESS_TOKEN ] && [ "$MANUBOT_ACCESS_TOKEN" != "" ]; then
  echo >&2 "[INFO] Detected MANUBOT_ACCESS_TOKEN. Will deploy via HTTPS."
  MANUBOT_DEPLOY_VIA_SSH=false
  git remote set-url origin "https://$MANUBOT_ACCESS_TOKEN@github.com/$REPO_SLUG.git"
else
  echo >&2 "[INFO] Missing MANUBOT_SSH_PRIVATE_KEY and MANUBOT_ACCESS_TOKEN. Will deploy via SSH."
fi

if [ $MANUBOT_DEPLOY_VIA_SSH = "true" ]; then
# Decrypt and add SSH key
eval "$(ssh-agent -s)"
(
set +o xtrace  # disable xtrace in subshell for private key operations
if [ -v MANUBOT_SSH_PRIVATE_KEY ]; then
  base64 --decode <<< "$MANUBOT_SSH_PRIVATE_KEY" | ssh-add -
else
echo >&2 "DeprecationWarning: Loading deploy.key from an encrypted file.
In the future, using the MANUBOT_ACCESS_TOKEN or MANUBOT_SSH_PRIVATE_KEY environment variable may be required."
openssl aes-256-cbc \
  -K $encrypted_9befd6eddffe_key \
  -iv $encrypted_9befd6eddffe_iv \
  -in ci/deploy.key.enc \
  -out ci/deploy.key -d
chmod 600 ci/deploy.key
ssh-add ci/deploy.key
fi
)
fi

# Don't do this
## Fetch and create gh-pages and output branches
## Travis does a shallow and single branch git clone
#git remote set-branches --add origin gh-pages output
#git fetch origin gh-pages:gh-pages output:output || \
#  echo >&2 "[INFO] could not fetch gh-pages or output from origin."

# Don't do this
## Configure versioned webpage and timestamp
#manubot webpage \
#  --timestamp \
#  --no-ots-cache \
#  --checkout=gh-pages \
#  --version="$COMMIT"

# Commit message
MESSAGE="\
$(git log --max-count=1 --format='%s')
[ci skip]

This build is based on
https://github.com/$REPO_SLUG/commit/$COMMIT.

This commit was created by the following CI build and job:
$CI_BUILD_WEB_URL
$CI_JOB_WEB_URL
"


# WIP
webpage_ls=$(ls -ls webpage)
echo >&2 "[INFO] WIP: webpage_ls $webpage_ls"
tar -zcvf /tmp/$GITHUB_PULL_REQUEST_NUMBER.tar.gz webpage/v/latest
git stash
git checkout gh-pages
mkdir PR
tar -zxvf /tmp/$GITHUB_PULL_REQUEST_NUMBER.tar.gz -C PR
git_status=$(git status)
echo >&2 "[INFO] WIP: git_status $git_status"


if [ $MANUBOT_DEPLOY_VIA_SSH = "true" ]; then
  # Workaround https://github.com/travis-ci/travis-ci/issues/8082
  ssh-agent -k
fi
