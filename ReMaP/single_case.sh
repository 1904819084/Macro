# usage: bash single_case.sh ariane133
set -e

script_dir="$(cd "$(dirname "$0")" && pwd)"
python_bin="${script_dir}/../.venv/bin/python"
cmake_bin="${script_dir}/../.venv/bin/cmake"

export PATH="/opt/homebrew/opt/flex/bin:/opt/homebrew/opt/bison/bin:${script_dir}/../.venv/bin:${PATH}"
export MPLCONFIGDIR="${script_dir}/../.matplotlib"
export DYLD_FALLBACK_LIBRARY_PATH="/opt/homebrew/opt/cairo/lib:/opt/homebrew/lib:${DYLD_FALLBACK_LIBRARY_PATH}"
export PKG_CONFIG_PATH="/opt/homebrew/opt/cairo/lib/pkgconfig:/opt/homebrew/opt/libpng/lib/pkgconfig:/opt/homebrew/opt/freetype/lib/pkgconfig:/opt/homebrew/opt/fontconfig/lib/pkgconfig:/opt/homebrew/opt/pixman/lib/pkgconfig:${PKG_CONFIG_PATH}"
export LDFLAGS="-L/opt/homebrew/opt/libomp/lib -L/opt/homebrew/opt/bison/lib -L/opt/homebrew/opt/flex/lib ${LDFLAGS}"
export CPPFLAGS="-I/opt/homebrew/opt/libomp/include -I/opt/homebrew/opt/flex/include ${CPPFLAGS}"
export CFLAGS="-I/opt/homebrew/opt/libomp/include -I/opt/homebrew/opt/flex/include ${CFLAGS}"
export CXXFLAGS="-I/opt/homebrew/opt/libomp/include -I/opt/homebrew/opt/flex/include ${CXXFLAGS}"

orig=$(pwd)
cd "${script_dir}"
mkdir -p build
cd build
if [ ! -f Makefile ]; then
    "${cmake_bin}" .. \
        -DCMAKE_INSTALL_PREFIX=../install \
        -DPython_EXECUTABLE="${python_bin}" \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DBoost_INCLUDE_DIR=/opt/homebrew/opt/boost/include \
        -DBISON_EXECUTABLE=/opt/homebrew/opt/bison/bin/bison \
        -DFLEX_EXECUTABLE=/opt/homebrew/opt/flex/bin/flex \
        -DFLEX_INCLUDE_DIR=/opt/homebrew/opt/flex/include \
        -DOpenMP_C_FLAGS="-Xclang -fopenmp -I/opt/homebrew/opt/libomp/include" \
        -DOpenMP_C_LIB_NAMES=omp \
        -DOpenMP_CXX_FLAGS="-Xclang -fopenmp -I/opt/homebrew/opt/libomp/include" \
        -DOpenMP_CXX_LIB_NAMES=omp \
        -DOpenMP_omp_LIBRARY=/opt/homebrew/opt/libomp/lib/libomp.dylib
fi
make -j16
make -j16 install
cd ../install
for design in $@
do
    "${python_bin}" dreamplace/Placer.py test/or_cases/$design.json
done
cd ${orig}
