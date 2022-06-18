set -a

ws_dir="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )"
if [[ "$(basename -- "$ws_dir")" == "conf" ]]; then
    ws_dir=$(dirname -- "$ws_dir")
fi
src_dir=$ws_dir/src
cling_dir=$src_dir/cppyy-backend/cling
clingwrapper_dir=$src_dir/cppyy-backend/clingwrapper
cppyy_backend_dir=$src_dir/cppyy-backend
CPyCppyy_dir=$src_dir/CPyCppyy
cppyy_dir=$src_dir/cppyy
prog_dir=$ws_dir/prog
cppyy_backend_package_dir=$ws_dir/.venv/lib/python3.8/site-packages/cppyy_backend
cppyy_package_dir=$ws_dir/.venv/lib/python3.8/site-packages/cppyy
cppyy_test_dir=$cppyy_dir/test

clnd()
{
    cd $cling_dir
}

cwrd() {
    cd $clingwrapper_dir
}

cbkd() {
    cd $cppyy_backend_dir
}

ccpd() {
    cd $CPyCppyy_dir
}

cpyd() {
    cd $cppyy_dir
}

cpid() {
    cd $prog_dir
}

bpgd() {
    cd $cppyy_backend_package_dir
}

cpgd() {
    cd $cppyy_package_dir
}

cpytd() {
    cd $cppyy_test_dir
}

cwsd() {
    cd $ws_dir
}


cbnis () {( set -e
    cd $src_dir

    gh repo clone wlav/cppyy-backend

    clnd
    python setup.py egg_info
    python3 create_src_directory.py
    python -m pip install . --upgrade

    cwrd
    python -m pip install . --upgrade --no-use-pep517 --no-deps

    cd $src_dir

    gh repo clone wlav/CPyCppyy

    ccpd
    python -m pip install . --upgrade --no-use-pep517 --no-deps

    cd $src_dir

    gh repo clone wlav/cppyy

    cpyd
    python -m pip install . --upgrade --no-deps
    python -m pip install pytest
    cpid
)}

cpyb() {( set -e
    cpyd
    python -m pip install . --upgrade --no-deps --force-reinstall

    cpid
)}

clnb() {( set -e
    echo "Building ClingWrapper..."
    clnd
    cd build
    make -j8

    cp lib/libClingWrappers.so $cling_dir/python/cppyy_backend/lib/libcppyy_backend.so

    # cwrd
    # cp src/cpp_cppyy.h src/cppyy.h src/callcontext.h src/clingwrapper.h src/capi.h $cppyy_backend_package_dir/include/

    cpid
    echo "Built ClingWrapper"
)}

ccpb() {( set -e
    echo "Building CPyCppyy..."
    ccpd
    cd build
    make -j4
    echo "Built CPyCppyy"
)}

cpylb() {( set -e
    clnb

    ccpb

    cpyd
    python -m pip install . --upgrade --no-deps --force-reinstall

    cpid
)}

cpyvlb() {( set -e
    clnb

    cpyd
    python -m pip install . --upgrade --no-deps --force-reinstall

    cpid
)}

cpyplb() {( set -e
    ccpb

    cpyd
    python -m pip install . --upgrade --no-deps --force-reinstall

    cpid
)}

cwrb() {( set -e
    cwrd
    python -m pip install . --upgrade --no-use-pep517 --no-deps --force-reinstall -v

    cpyd
    python -m pip install . --upgrade --no-deps --force-reinstall

    cpid
)}

cpyt() {( set -e 
    cpytd
    make all
    python -m pytest -sv

    cpid
)}

cpybt() {( set -e
    cpyb
    cpyt
)}

cpylbt() {( set -e
    cpylb
    cpyt
)}

cpyvlbt() {( set -e
    cpyvlb
    cpyt
)}

help() {( set -e
    echo "clnb - Build clingwrapper"
    echo "clnd - Change dir to cppyy-backend/cling"
    echo "ccpb - Build CPyCppyy"
    echo "ccpd - Change dir to CPyCppyy"
    echo "cpyb - Build cppyy"
    echo "cpyd - Change dir to cppyy"
)}

pythonpath_add() {
    if [ -d "$1" ] && [[ ":$PYTHONPATH:" != *":$1:"* ]]; then
        PYTHONPATH="${PYTHONPATH:+"$PYTHONPATH:"}$1"
    fi
}

ldlibrarypath_add() {
    if [ -d "$1" ] && [[ ":$LDLIBRARYPATH:" != *":$1:"* ]]; then
        LDLIBRARYPATH="${LDLIBRARYPATH:+"$LDLIBRARYPATH:"}$1"
    fi
}

# Commands to run when loading the script:
source $ws_dir/.venv/bin/activate
cd $ws_dir
pythonpath_add $CPyCppyy_dir/build
pythonpath_add $cling_dir/python
# pythonpath_add $cling_dir/builddir
ldlibrarypath_add $cling_dir/build/lib

set +a
