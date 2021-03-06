#!/bin/bash
set -ev


# Update variables from install
# CMake
if [[ "${TRAVIS_OS_NAME}" == "linux" ]]; then
    export PATH=${DEPS_DIR}/cmake/bin:${PATH}
fi

# Anaconda
export PATH=${DEPS_DIR}/miniconda/bin:$PATH
hash -r
source activate testenv

# Add MKL shared libraries to the path
MKL_SHARED_LIB_DIR=`ls -d ${DEPS_DIR}/miniconda/pkgs/*/lib | grep mkl-2 | tail -1`
OPENMP_SHARED_LIB_DIR=`ls -d ${DEPS_DIR}/miniconda/pkgs/*/lib | grep openmp | tail -1`
if [[ "${TRAVIS_OS_NAME}" == "linux" ]]; then
    export LD_LIBRARY_PATH=${MKL_SHARED_LIB_DIR}:${OPENMP_SHARED_LIB_DIR}:${LD_LIBRARY_PATH}
else if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
    export DYLD_LIBRARY_PATH=${MKL_SHARED_LIB_DIR}:${OPENMP_SHARED_LIB_DIR}:${DYLD_LIBRARY_PATH}
fi
fi




# Test C interface
# ---------------------------------------------------

# Compile OSQP
echo "Change directory to Travis build ${TRAVIS_BUILD_DIR}"
cd ${TRAVIS_BUILD_DIR}
mkdir build
cd build
cmake -G "Unix Makefiles" -DCOVERAGE=ON ..
make


# Test OSQP C
${TRAVIS_BUILD_DIR}/build/out/osqp_tester

# Pefrorm code coverage (only in Linux case for one version of python)
if [[ $TRAVIS_OS_NAME == "linux" ]] && [[ $PYTHON_VERSION == "3.6" ]]; then
    cd ${TRAVIS_BUILD_DIR}/build
    lcov --directory . --capture -o coverage.info # capture coverage info
    lcov --remove coverage.info "${TRAVIS_BUILD_DIR}/tests/*" \
        "${TRAVIS_BUILD_DIR}/lin_sys/direct/suitesparse/amd/*" \
        "${TRAVIS_BUILD_DIR}/lin_sys/direct/suitesparse/ldl/*" \
        "${TRAVIS_BUILD_DIR}/lin_sys/direct/suitesparse/SuiteSparse_config*" \
        "/usr/include/x86_64-linux-gnu/**/*" \
        -o coverage.info # filter out tests and unnecessary files
    lcov --list coverage.info # debug before upload
    coveralls-lcov coverage.info # uploads to coveralls
fi


# Test Python interface
# ---------------------------------------------------

# Install Python interface
cd ${TRAVIS_BUILD_DIR}/interfaces/python
python setup.py install

# Test OSQP Python
cd ${TRAVIS_BUILD_DIR}/interfaces/python
pytest
