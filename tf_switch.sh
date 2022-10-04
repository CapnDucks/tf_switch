#!/bin/sh
# Terraform Switch
# Allows you to switch between terraform versions
# Capnducks (coder@capnduck.com)
# Tested on both mac and ubuntu
#
BASE_URL="https://releases.hashicorp.com/terraform"
CHECK_URL="https://checkpoint-api.hashicorp.com/v1/check/terraform"
CURL=$(command -v curl)
CURRENT_VERSION=$(terraform --version 2> /dev/null | head -n 1)
JQ=$(command -v jq)
KERNEL=$(uname -s | tr "[:upper:]" "[:lower:]")
NUM_RELEASES=${2:-25}
TEMP_DIR=$(mktemp -d)
TF_PATH="$(command -v terraform | cut -d\/ -f1-4)"
TF_VERSION="${1}"
UNZIP=$(command -v unzip)
USAGE="Usage: tf_switch {version you'd like to use}: eg. 'tf_switch 0.14.11'\n Or you can specify 'latest' to get the latest version\n If you are unsure what versions are available, you can use 'list {number}' to get a list of terraform releases (defaults to 25)\n"

if [ -z ${CURL} ]; then
  printf "curl is not installed or is not in your PATH.  Please rectify the error.\n"
  exit 1
fi

if [ -z $CURRENT_VERSION ]; then
  CURRENT_VERSION="no current version installed!"
fi

if [ -z ${JQ} ] && [ ${TF_VERSION} = "latest" ]; then
  printf "jq is not installed or is not in your PATH.  Please rectify the error.\n"
  exit 1
fi

if [ -z "${UNZIP}" ]; then
  printf "unzip is not installed or is not in your PATH. Please rectify the error.\n"
  exit 1
fi

if [ -z "${TF_VERSION}" ]; then
  printf "${USAGE}"
  printf "You are currently using: $CURRENT_VERSION\n"
  exit 0 # Not an error to ask for help
fi

if [ $TF_VERSION = "list" ]; then
  printf "Last $NUM_RELEASES releases of terraform:\n"
  curl -s https://releases.hashicorp.com/terraform  | grep -Eo '/[.0-9]+/' | grep -Eo '[.0-9]+' | sort -rV | head -n $NUM_RELEASES
  exit 0
fi

if [ "${TF_VERSION}" = "latest" ];
  then
    VERSION="$(curl -sL {$CHECK_URL} | jq -r .current_version)"
else
  VERSION="${TF_VERSION}"
fi

if [ -z ${TF_PATH} ]; then
  echo "Terraform path not found!"
  echo "Please enter FULL path to install terraform (eg: /home/user/bin)"
  echo "You MUST have permissions to the path provided and it MUST exist"
  echo "Your current PATH is: $PATH"
  read TF_PATH
fi

TARGET_URL="${BASE_URL}/${VERSION}/terraform_${VERSION}_${KERNEL}_amd64.zip"
TARGET_DL="terraform_${VERSION}_${KERNEL}_amd64.zip"

echo "Switching to TF v${VERSION}"
cd $TEMP_DIR

if [ ! -f "${TARGET_DL}" ]; then
    curl -s "${TARGET_URL}" -o "${TARGET_DL}"
fi

unzip -qo "${TARGET_DL}" 2> /dev/null
if [ $? != 0 ]; then
  echo "$VERSION is not a valid version of terraform"
  exit 1
fi

mv terraform "${TF_PATH}"

echo "You are now using"
terraform version | head -2
rm -rf $TEMP_DIR
