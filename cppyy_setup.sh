#!/bin/bash
setup_venv() {
    if [ ! -d "$1/.venv" ]; then
        echo "Creating .venv in $1 directory"
        cd $1
        python3 -m venv .venv
    fi
}

setup_cppyy_backend() {
    echo "Setting up cppyy-backend in $1 directory"
    cd $1
    if [ ! -d "$1/cppyy-backend" ]; then
        git clone https://github.com/sudo-panda/cppyy-backend.git
    fi

    cd cppyy-backend
    git stash
    git checkout rm-root-meta

    cd cling
    python3 setup.py egg_info

    if [ ! -d "$1/cppyy-backend/cling/src" ]; then
        python3 create_src_directory.py
    fi

    if [ ! -L "$1/cppyy-backend/cling/src/core/metacling/src/clingwrapper" ]; then
        ln -s $1/cppyy-backend/clingwrapper/src $1/cppyy-backend/cling/src/core/metacling/src/clingwrapper
    fi

    mkdir build
    cd build

    echo " Running cmake in ${pwd} directory"
    cmake  \
        -DCMAKE_BUILD_TYPE="Debug" \
        -DLLVM_BUILD_TYPE="Debug"  \
        -DLLVM_ENABLE_TERMINFO="0" \
        -Dbuiltin_cling="ON"       \
        -Dbuiltin_zlib="ON"        \
        -Dminimal="ON"             \
        -Druntime_cxxmodules="OFF" \
        ../src

    echo " Running make in ${pwd} directory"
    make -j6

    echo " Copying shared library file"
    cp lib/libClingWrappers.so ../python/cppyy_backend/lib/libcppyy_backend.so

    echo " Copying headers ..."
    mkdir etc/llvm
    mkdir etc/llvm/ADT
    mkdir etc/llvm/Config
    mkdir etc/llvm/Support
    mkdir etc/llvm-c

    touch etc/llvm/Config/abi-breaking.h
    touch etc/llvm/Config/llvm-config.h

    cp ../src/interpreter/cling/include/cling/Interpreter/Interpreter.h \
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
    echo " Done! cppyy-backend installed"
}

setup_cpycppyy() {
    echo "Setting up CPyCppyy in $1 directory"
    cd $1

    if [ ! -d "$1/CPyCppyy" ]; then
        echo " Cloning CPyCppyy"
        git clone https://github.com/sudo-panda/CPyCppyy.git
    fi

    cd CPyCppyy
    git stash
    git checkout wip
    git pull --rebase

    mkdir build
    cd build

    echo " Running cmake in ${pwd} directory"
    cmake -DCMAKE_BUILD_TYPE="Debug" ..

    echo " Running make in ${pwd} directory"
    make -j6

    echo " Done! CPyCppyy installed"
}

setup_cppyy() {
    echo "Setting up cppyy in $1 directory"
    cd $1

    if [ ! -d "$1/cppyy" ]; then
        echo " Cloning cppyy"
        git clone https://github.com/sudo-panda/cppyy.git
    fi

    cd cppyy
    git stash
    git checkout rm-root-meta
    git pull --rebase

    cd cppyy
    python3 -m pip install . --upgrade --no-deps

    echo " Done! cppyy installed"
}

pythonpath_add() {
    if [ -d "$1" ] && [[ ":$PYTHONPATH:" != *":$1:"* ]]; then
        PYTHONPATH="${PYTHONPATH:+"$PYTHONPATH:"}$1"
    fi
}

update_script() {
    echo "Updating $2 in $1 directory"
    cd $1
    wget https://raw.githubusercontent.com/sudo-panda/scrawls/main/cppyy_setup.sh -O $2
}

if [ $# -eq 0 ]; then
    INSTALL_DIR=${pwd}
elif [[ $1 == "--update" ]]; then
    update_script "$( dirname -- "$0"; )" "$( basename -- "$0";)"
    exit
else
    echo "$1"
    INSTALL_DIR=$1
fi

setup_venv "$INSTALL_DIR"

setup_cppyy_backend "$INSTALL_DIR/src"
pythonpath_add "$INSTALL_DIR/src/cppyy-backend/cling/python"

setup_cpycppyy "$INSTALL_DIR/src"
pythonpath_add "$INSTALL_DIR/src/CPyCppyy/build"

setup_cppyy "$INSTALL_DIR/src"



