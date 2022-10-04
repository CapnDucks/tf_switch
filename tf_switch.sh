#!/bin/sh
# Terraform Switch
# Allows you to switch between terraform versions
# Capnducks (coder@capnduck.com)
# Tested on both mac and ubuntu
#
JQ="$(command -v jq)"
CURL="$(command -v curl)"
CHECK_URL="https://checkpoint-api.hashicorp.com/v1/check/terraform"
DOWNLOAD_URL="https://releases.hashicorp.com/terraform"
USAGE="Usage: tf_switch {version you'd like to use}: eg. 'tf_switch 0.14.11'\n You can specify 'latest' to get the latest version\n You can specify 'list' to get a list of versions available\n"
TF_VERSION="${1}"
TF_PATH="$(command -v terraform | cut -d\/ -f1-4)"
KERNEL=$(uname -s | tr "[:upper:]" "[:lower:]")
VERSION="0.0.12"
TEMP_DIR=$(mktemp -d)

if [ -z ${JQ} ] && [ ${TF_VERSION} = "latest" ]; then
  printf "jq is not installed or is not in your PATH.  Please rectify the error.\n"
  exit 1
fi

if [ -z ${CURL} ]; then
  printf "curl is not installed or is not in your PATH.  Please rectify the error.\n"
  exit 1
fi
#
if [ -z ${TF_VERSION} ]; then
  printf "${USAGE}"
  exit 0 # Not an error to ask for help
fi

if [ "${TF_VERSION}" = "latest" ]; then
  VERSION="$(curl -sL {$CHECK_URL} | jq -r .current_version)"
else
  VERSION="${TF_VERSION}"
fi

if [ "$TF_VERSION" = "list" ]; then
  VERSIONS="$(curl -LSs {$DOWNLOAD_URL} | grep -Eo '/[.0-9]+/' | grep -Eo '[.0-9]+' | sort -V)"
  printf "$VERSIONS\n"
  exit 0 #Not an error to list versions
fi

if [ -z ${TF_PATH} ]; then
  echo "Terraform not found in ${PATH} !"
  echo "Please enter FULL path to install terraform"
  read TF_PATH
fi

TARGET_URL="${DOWNLOAD_URL}/${VERSION}/terraform_${VERSION}_${KERNEL}_amd64.zip"
#
echo "Downloading and switching to TF v${VERSION}"
echo "Please wait"
cd $TEMP_DIR
curl -s "${TARGET_URL}" -o "terraform_${VERSION}_${KERNEL}_amd64.zip"
unzip -o "terraform_${VERSION}_${KERNEL}_amd64.zip"
mv terraform "${TF_PATH}"

echo "You are now using"
terraform version | head -2
rm -rf $TEMP_DIR
