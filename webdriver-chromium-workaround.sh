#!/usr/bin/env bash
#
# Author: Maxime BOCHON
# Created: 2019-10-31
#
# Description(fr):
#  Actuellement, `protractor` installe une version 2.x du "webdriver" de Chromium via le `webdriver-manager`.
#  Hors cette version du "webdriver" n'est pas compatible avec les versions de Chromium supérieures à 73.
#  Pourtant des "webdriver" compatibles existent pour chaque version de Chromium.
#  Ce script a pour but d'effectuer correctement la mise à jour du "webdriver" Chromium,
#  là où `webdriver-manager` de `protractor` semble échouer.
#
# Keywords: Protractor WebDriver Selenium WebDriver-Manager Chromium Chrome ChromeDriver Outdated NPM Node
#


# Parameters

TMP="/tmp"
DEP_LIST="find grep tail unzip curl wget xmllint chromium-browser"
DRIVERS_URL="http://chromedriver.storage.googleapis.com"
DRIVERS_LIST="chromedriver-list.xml"
DRIVER_ZIP="chromedriver_linux64.zip"
DRIVER_BIN="chromedriver"


# Check dependencies

for d in ${DEP_LIST}; do
  command -v $d >/dev/null 2>&1 || {
    echo >&2 "$d is required"
    exit 1
  }
done


# Locate local web driver to replace

DRIVER_PATH=$(find . -type f -regex '^.+/chromedriver_2\.[0-9][0-9]$')

if [[ $? -ne 0 ]] || [[ -z "${DRIVER_PATH}" ]]; then
  echo >&2 "Cannot find current web driver to replace."
  exit 2
fi


# Download Chromium web driver list from Google

curl -s ${DRIVERS_URL} -o ${TMP}/${DRIVERS_LIST}

if [[ $? -ne 0 ]]; then
  echo >&2 "Cannot download Chrome drivers list."
  exit 3
fi


# Read local Chromium version

VERSION=$(chromium-browser --version | grep -oP 'Chromium \K([0-9]+\.[0-9]+)')

if [[ $? -ne 0 ]] || [[ -z "${VERSION}" ]]; then
  echo >&2 "Cannot read local Chromium version."
  exit 4
fi


# Read web driver resource identifier from web driver list

DRIVER_RESOURCE=$(xmllint --format ${TMP}/${DRIVERS_LIST} | grep -oP ${VERSION/\./\\.}'\.[0-9.]+/'${DRIVER_ZIP/\./\\.} | tail -1)

if [[ $? -ne 0 ]] || [[ -z "${DRIVER_RESOURCE}" ]]; then
  echo >&2 "Cannot read web driver resource for current Chromium version."
  exit 5
fi


# Download web driver archive for current Chromium version

wget ${DRIVERS_URL}/${DRIVER_RESOURCE} -N -P ${TMP}

if [[ $? -ne 0 ]]; then
  echo >&2 "Cannot download Chrome driver for current Chromium version."
  exit 6
fi


# Extract web driver file from archive

rm -f ${TMP}/${DRIVER_BIN} && \
unzip ${TMP}/${DRIVER_ZIP} -d ${TMP}

if [[ $? -ne 0 ]]; then
  echo >&2 "Cannot unzip the Chrome driver file.";
  exit 7
fi


# Install new web driver (sneakily replace current one)

echo; echo ${TMP}/${DRIVER_BIN} "-->" ${DRIVER_PATH}; echo
mv ${TMP}/${DRIVER_BIN} ${DRIVER_PATH}

if [[ $? -ne 0 ]]; then
  echo >&2 "Cannot install the new Chrome driver.";
  exit 8
fi


# Clean up

rm -f ${TMP}/${DRIVER_ZIP}

