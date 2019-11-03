#!/bin/bash -e

ROOT=`git rev-parse --show-toplevel`

# pushd doesnt work when invoked from zsh
_OLDPWD=`pwd`

cd ${ROOT}
LOG_DIR=${ROOT}
LOG_NAME=output.log

if [[ -f "${LOG_NAME}" ]]; then
    echo "== Removing old log ${LOG_DIR}/${LOG_NAME}"
    rm ${LOG_NAME}
fi

if [[ -d "work" ]]; then
    echo "== Removing old library `pwd`/work" | tee ${LOG_DIR}/${LOG_NAME}
    rm -r work
fi

echo "== Making new build directory `pwd`/work" | tee -a ${LOG_DIR}/${LOG_NAME}
mkdir work
WORK=${ROOT}/work
cd src

echo "== Analysing source files"  | tee -a ${LOG_DIR}/${LOG_NAME}
ENTITIES=(spi_master msb_spi_tb lsb_spi_tb spi_master_beh_impl)

echo "== Starting with the package"  | tee -a ${LOG_DIR}/${LOG_NAME}
echo "  spi_package.vhd" | tee -a ${LOG_DIR}/${LOG_NAME}
ghdl -a -v --workdir=${WORK} spi_package.vhd | tee -a ${LOG_DIR}/${LOG_NAME}

echo "== Now the rest"  | tee -a ${LOG_DIR}/${LOG_NAME}
for f in "${ENTITIES[@]}"
do
    FPATH=""
    if [[ ${f} == *tb ]]; then
        FPATH="${ROOT}/test/"
    fi

    echo "  ${f}.vhd" | tee -a ${LOG_DIR}/${LOG_NAME}
    ghdl -a -v --workdir=${WORK} ${FPATH}${f}.vhd | tee -a ${LOG_DIR}/${LOG_NAME}
done

echo "== Elaborating entities" | tee -a ${LOG_DIR}/${LOG_NAME}
for f in "${ENTITIES[@]}"
do
    echo "  ${f}" | tee -a ${LOG_DIR}/${LOG_NAME}
    if [[ ${f} != *impl ]]; then
        ghdl -e -v --workdir=${WORK} ${f} | tee -a ${LOG_DIR}/${LOG_NAME}
    fi
done

echo "== Running tests" | tee -a ${LOG_DIR}/${LOG_NAME}
for f in "${ENTITIES[@]}"
do
    if [[ ${f} = *tb ]]; then
        echo "  ${f}" | tee -a ${LOG_DIR}/${LOG_NAME}
        ghdl -r -v --workdir=${WORK} ${f} --wave=${f}.ghw | tee -a ${LOG_DIR}/${LOG_NAME}
        echo "  ${f} Complete" | tee -a ${LOG_DIR}/${LOG_NAME}
    fi
done

cd ${_OLDPWD}
echo "== \u001b[32mDone\u001b[0m" | tee -a ${LOG_DIR}/${LOG_NAME}
