#!/bin/bash
mkdir build
cd build

CMAKE_ARCH="-m"$ARCH
INCLUDE_PATH=${PREFIX}/include
LIBRARY_PATH=${PREFIX}/lib

if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  export CFLAGS="$CFLAGS -fPIC $CMAKE_ARCH"
  export LDFLAGS="$LDFLAGS $CMAKE_ARCH"
  DYNAMIC_EXT="so"
  DLIB_JPEG="-DJPEG_INCLUDE_DIR=${INCLUDE_PATH} -DJPEG_LIBRARY=${LIBRARY_PATH}/libjpeg.${DYNAMIC_EXT}"
fi
if [ "$(uname -s)" == "Darwin" ]; then
  DLIB_JPEG=""
  DYNAMIC_EXT="dylib"
  export MACOSX_VERSION_MIN="10.9"
  export MACOSX_DEPLOYMENT_TARGET="${MACOSX_VERSION_MIN}"
  export CMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_VERSION_MIN}"
  export CXXFLAGS="${CXXFLAGS} -mmacosx-version-min=${MACOSX_VERSION_MIN}"
  export CXXFLAGS="${CXXFLAGS} -stdlib=libc++"
  export LDFLAGS="${LDFLAGS} -headerpad_max_install_names"
  export LDFLAGS="${LDFLAGS} -mmacosx-version-min=${MACOSX_VERSION_MIN}"
  export LDFLAGS="${LDFLAGS} -lc++"
fi

if [ $PY3K -eq 1 ]; then
  export PY_STR="${PY_VER}m"
else
  export PY_STR="${PY_VER}"
fi

# Make the probably sensible assumption that a 64-bit
# machine supports SSE4 instructions - if this becomes
# a problem we should turn this off.
if [ $ARCH -eq 64 ]; then
  USE_SSE4=1
else
  USE_SSE4=0
fi

export LDFLAGS="-L${LIBRARY_PATH} $LDFLAGS"

cmake -LAH ../tools/python \
-DCMAKE_PREFIX_PATH=$PREFIX \
-DBUILD_SHARED_LIBS=1 \
-DBoost_USE_STATIC_LIBS=0 \
-DBoost_USE_STATIC_RUNTIME=0 \
-DBOOST_ROOT=$PREFIX \
-DBOOST_INCLUDEDIR="${INCLUDE_PATH}" \
-DBOOST_LIBRARYDIR="${LIBRARY_PATH}" \
-DPYTHON_LIBRARY="${LIBRARY_PATH}/libpython$PY_STR.$DYNAMIC_EXT" \
-DPYTHON_INCLUDE_DIR="${INCLUDE_PATH}/python$PY_STR" \
-DPYTHON3=$PY3K \
-DDLIB_LINK_WITH_LIBPNG=1 \
-DPNG_INCLUDE_DIR="${INCLUDE_PATH}" \
-DPNG_PNG_INCLUDE_DIR="${INCLUDE_PATH}" \
-DPNG_LIBRARY="${LIBRARY_PATH}/libpng.${DYNAMIC_EXT}" \
-DDLIB_LINK_WITH_LIBJPEG=1 \
${DLIB_JPEG} \
-DDLIB_LINK_WITH_SQLITE3=1 \
-DDLIB_NO_GUI_SUPPORT=1 \
-DUSE_SSE2_INSTRUCTIONS=1 \
-DUSE_SSE4_INSTRUCTIONS=$USE_SSE4 \
-DDLIB_USE_BLAS=0 \
-DDLIB_USE_LAPACK=0
# Use the conda build in the mkl folder for BLAS

# On Travis, due to the heavy template expansion, we need
# to limit the number of cores (and thus the memory
# usage) else we get a compiler error.
CMAKE_CPU_COUNT=1

cmake --build . --config Release --target install -- -j${CMAKE_CPU_COUNT}

cp dlib.so $SP_DIR

