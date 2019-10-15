#!/bin/bash -e

# silent push and pop
pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

pushd .
cd ..
LOG_DIR=`pwd`
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
WORK=`pwd`/work
ROOT=`pwd`
cd src

echo "== Analysing source files"  | tee -a ${LOG_DIR}/${LOG_NAME}
ENTITIES=(spi spi_tb)
for f in "${ENTITIES[@]}"
do
    FPATH=""
    if [[ ${f} == *tb ]]; then
        FPATH="${ROOT}/test/"
    fi

    echo "  ${f}.vhd" | tee -a ${LOG_DIR}/${LOG_NAME}
    ghdl -a -v --workdir=${WORK} ${FPATH}${f}.vhd | tee -a ${LOG_DIR}/${LOG_NAME}
done

popd
echo "== Elaborating entities" | tee -a ${LOG_DIR}/${LOG_NAME}
for f in "${ENTITIES[@]}"
do
    echo "  ${f}" | tee -a ${LOG_DIR}/${LOG_NAME}
    ghdl -e -v --workdir=${WORK} ${f} | tee -a ${LOG_DIR}/${LOG_NAME}
done

echo "== Running tests" | tee -a ${LOG_DIR}/${LOG_NAME}
for f in "${ENTITIES[@]}"
do
    if [[ ${f} = *tb ]]; then
        echo "  ${f}" | tee -a ${LOG_DIR}/${LOG_NAME}
        ghdl -r -v --workdir=${WORK} ${f} --vcd=${f}.vcd | tee -a ${LOG_DIR}/${LOG_NAME}
        echo "  ${f} Complete" | tee -a ${LOG_DIR}/${LOG_NAME}
    fi
done

echo "== Done" | tee -a ${LOG_DIR}/${LOG_NAME}
