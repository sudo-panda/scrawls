#!/bin/bash
setup_venv() {
    if [ ! -d "$1/.venv" ]; then
        echo "=====   Creating .venv in $1 directory   ====="
        cd $1
        python3 -m venv .venv
    fi
}

setup_cppyy_backend() {
    echo "=====   Setting up cppyy-backend in $1 directory   ====="
    cd $1
    if [ ! -d "$1/cppyy-backend" ]; then
        echo "-----   Cloning cppyy-backend   -----"
        git clone https://github.com/sudo-panda/cppyy-backend.git
        git config --global --add safe.directory $1/cppyy-backend
    fi

    cd cppyy-backend
    git stash
    git checkout rm-root-meta

    cd cling
    python3 setup.py egg_info
    python3 create_src_directory.py

    if [ ! -L "$1/cppyy-backend/cling/src/core/metacling/src/clingwrapper" ]; then
        ln -s $1/cppyy-backend/clingwrapper/src $1/cppyy-backend/cling/src/core/metacling/src/clingwrapper
    fi

    if [ ! -L "$1/cppyy-backend/cling/src/interpreter/cling/lib/Interpreter/clingwrapper" ]; then
        ln -s $1/cppyy-backend/clingwrapper/src $1/cppyy-backend/cling/src/interpreter/cling/lib/Interpreter/clingwrapper
    fi

    mkdir build
    cd build

    echo "-----   Running cmake in ${pwd} directory   -----"
    cmake  \
        -DCMAKE_BUILD_TYPE="Debug" \
        -DLLVM_BUILD_TYPE="Debug"  \
        -DLLVM_ENABLE_TERMINFO="0" \
        -Dbuiltin_cling="ON"       \
        -Dbuiltin_zlib="ON"        \
        -Dclingtest="ON"           \
        -Dminimal="ON"             \
        -Druntime_cxxmodules="OFF" \
        ../src

    echo "-----   Running make in ${pwd} directory   -----"
    make -j6

    echo "-----   Copying shared library file   -----"
    mkdir -p ../python/cppyy_backend/lib
    cp lib/libClingWrappers.so ../python/cppyy_backend/lib/libcppyy_backend.so

    echo "-----   Copying headers ...   -----"
    mkdir -p etc/llvm
    mkdir -p etc/llvm/ADT
    mkdir -p etc/llvm/Config
    mkdir -p etc/llvm/Support
    mkdir -p etc/llvm-c

    touch etc/llvm/Config/abi-breaking.h
    touch etc/llvm/Config/llvm-config.h
    cp  ../src/interpreter/cling/include/cling/Interpreter/InvocationOptions.h \
        ../src/interpreter/cling/include/cling/Interpreter/Interpreter.h       \
        etc/cling/Interpreter/
    cp  ../src/interpreter/llvm/src/include/llvm/ADT/iterator.h       \
        ../src/interpreter/llvm/src/include/llvm/ADT/iterator_range.h \
        ../src/interpreter/llvm/src/include/llvm/ADT/None.h           \
        ../src/interpreter/llvm/src/include/llvm/ADT/Optional.h       \
        ../src/interpreter/llvm/src/include/llvm/ADT/SmallVector.h    \
        ../src/interpreter/llvm/src/include/llvm/ADT/STLExtras.h      \
        ../src/interpreter/llvm/src/include/llvm/ADT/StringRef.h      \
        etc/llvm/ADT/
    cp  ../src/interpreter/llvm/src/include/llvm/Support/AlignOf.h       \
        ../src/interpreter/llvm/src/include/llvm/Support/Compiler.h      \
        ../src/interpreter/llvm/src/include/llvm/Support/DataTypes.h     \
        ../src/interpreter/llvm/src/include/llvm/Support/ErrorHandling.h \
        ../src/interpreter/llvm/src/include/llvm/Support/MathExtras.h    \
        ../src/interpreter/llvm/src/include/llvm/Support/MemAlloc.h      \
        ../src/interpreter/llvm/src/include/llvm/Support/SwapByteOrder.h \
        ../src/interpreter/llvm/src/include/llvm/Support/type_traits.h   \
        etc/llvm/Support
    cp ../src/interpreter/llvm/src/include/llvm-c/DataTypes.h \
        etc/llvm-c

    echo "=====   Done! cppyy-backend installed   ====="
    echo ""
}

setup_cpycppyy() {
    echo "=====   Setting up CPyCppyy in $1 directory   ====="
    cd $1

    if [ ! -d "$1/CPyCppyy" ]; then
        echo "-----   Cloning CPyCppyy   -----"
        git clone https://github.com/sudo-panda/CPyCppyy.git
        git config --global --add safe.directory $1/CPyCppyy
    fi

    cd CPyCppyy
    git stash
    git checkout wip
    git pull --rebase

    mkdir build
    cd build

    echo "-----   Running cmake in ${pwd} directory   -----"
    cmake -DCMAKE_BUILD_TYPE="Debug" ..

    echo " Running make in ${pwd} directory"
    make -j6

    echo "=====   Done! CPyCppyy installed   ====="
    echo ""
}

setup_cppyy() {
    echo "=====   Setting up cppyy in $1 directory   ====="
    cd $1

    if [ ! -d "$1/cppyy" ]; then
        echo "-----   Cloning cppyy   -----"
        git clone https://github.com/sudo-panda/cppyy.git
        git config --global --add safe.directory $1/cppyy
    fi

    cd cppyy
    git stash
    git checkout rm-root-meta
    git pull --rebase

    python3 -m pip install wheel
    python3 -m pip install . --upgrade --no-deps

    echo "=====   Done! cppyy installed   ====="
}

pythonpath_add() {
    if [ -d "$1" ] && [[ ":$PYTHONPATH:" != *":$1:"* ]]; then
        PYTHONPATH="${PYTHONPATH:+"$PYTHONPATH:"}$1"
    fi
}

update_script() {
    echo "=====   Updating $2 in $1 directory   ====="
    cd $1
    wget https://raw.githubusercontent.com/sudo-panda/scrawls/main/cppyy_setup.sh -O $2
}

INSTALL_DIR="$( pwd )"

if [[ $1 == "--update" ]]; then
    update_script "$( dirname -- "$0"; )" "$( basename -- "$0";)"
    exit
elif [[ $# -eq 1 ]]; then
    INSTALL_DIR=$( readlink -f $1 )
    if [[ ! -d $INSTALL_DIR ]]; then
        echo "$INSTALL_DIR is not a valid path"
        exit
    fi
fi

echo "=====   Setting up cppyy in $INSTALL_DIR   ====="

setup_venv "$INSTALL_DIR"

source .venv/bin/activate
mkdir $INSTALL_DIR/src

setup_cppyy_backend "$INSTALL_DIR/src"
pythonpath_add "$INSTALL_DIR/src/cppyy-backend/cling/python"

setup_cpycppyy "$INSTALL_DIR/src"
pythonpath_add "$INSTALL_DIR/src/CPyCppyy/build"

setup_cppyy "$INSTALL_DIR/src"



