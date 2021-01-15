#!/bin/sh

#set -x
set  -eu

. ./make.config

BSEC_VERSION="1.4.8.0"

if [ ! -d "${BSEC_DIR}" ]; then
  echo 'BSEC directory missing, downloading...'
  BSEC_FILENAME=bsec_1-4-8-0_generic_release.zip
  wget https://www.bosch-sensortec.com/media/boschsensortec/downloads/bsec/$BSEC_FILENAME -O $BSEC_FILENAME
  unzip -d src $BSEC_FILENAME
  wget https://github.com/BoschSensortec/BME680_driver/archive/bme680_v3.5.10.tar.gz -O bme680_v3.5.10.tar.gz
  mkdir src/BSEC_1.4.8.0_Generic_Release/API
  tar xfzv bme680_v3.5.10.tar.gz -C src/BSEC_1.4.8.0_Generic_Release/API --strip-components=1
fi

# if [ ! -d "${CONFIG_DIR}" ]; then
#   mkdir "${CONFIG_DIR}"
# fi

# STATEFILE="${CONFIG_DIR}/bsec_iaq.state"
# if [ ! -f "${STATEFILE}" ]; then
#   touch "${STATEFILE}"
# fi

echo 'Patching...'
dir="${BSEC_DIR}/examples/bsec_iot_example"
patch='patches/eCO2+bVOCe.diff'
if patch -N --dry-run --silent -d "${dir}/" \
  < "${patch}" 2>/dev/null
then
  patch -d "${dir}/" < "${patch}"
else
  echo 'Already applied.'
fi

EXAMPLES_DIR="${BSEC_DIR}/examples/bsec_iot_example"

echo 'Compiling...'
/opt/cross-pi-gcc/bin/arm-linux-gnueabihf-gcc -Wall -Wno-unused-but-set-variable -Wno-unused-variable -static \
  -std=c99 -pedantic \
  -iquote"${BSEC_DIR}"/API \
  -iquote"${BSEC_DIR}"/algo/${ARCH} \
  -iquote"${EXAMPLES_DIR}" \
  "${EXAMPLES_DIR}"/bme680.c \
  ./bsec_integration.c \
  ./bsec_bme680.c \
  -L"${BSEC_DIR}"/algo/"${ARCH}" -lalgobsec \
  -lm -lrt -s \
  -o bsec_bme680
echo "Compiled BSEC version $BSEC_VERSION to ./bsec_bme680"
echo $BSEC_VERSION >./version

cp "${BSEC_DIR}"/config/"${CONFIG}"/bsec_iaq.config ./
echo 'Copied config to ./bsec_iaq.config'

