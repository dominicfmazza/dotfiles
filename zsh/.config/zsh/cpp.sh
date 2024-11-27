# Compilation flags
export ARCHFLAGS="-arch $(uname -m)"

if [ -f "/opt/rh/gcc-toolset-13/enable" ]; then
    source /opt/rh/gcc-toolset-13/enable
    export X_SCLS="scl enable gcc-toolset-13 'echo $X_SCLS'"
fi

if [ -f "/usr/bin/clang" ]; then
    export CXX=/usr/bin/clang++
    export CC=/usr/bin/clang
fi
