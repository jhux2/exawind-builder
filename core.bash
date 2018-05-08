#!/bin/bash

__EXAWIND_CORE_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

exawind_help ()
{
    cat <<EOF
Exawind build script

Usage:
    ${BASH_SOURCE[0]} <task> <arguments>

With no tasks provided, the script will configure the project and compile the code

Available tasks:
    cmake - configure the project
    make  - compile the code
    ctest - run tests (if available)
    run   - run arbitrary command using the environment used to compile the code
EOF
}

exawind_save_func ()
{
    local orig_func=$(declare -f $1)
    local new_func="$2${orig_func#$1}"
    eval "$new_func"
}

exawind_env ()
{
    local srcdir=${__EXAWIND_CORE_DIR}
    if [ -z "$EXAWIND_SYSTEM" ] ; then
       echo "EXAWIND_SYSTEM variable has not been defined"
       exit 1
    fi

    local sys=${EXAWIND_SYSTEM}
    local compiler=${EXAWIND_COMPILER:-gcc}
    source ${srcdir}/envs/${sys}.bash
    exawind_env_${compiler}
}

exawind_cmake_full ()
{
    set +e
    rm -rf CMakeCache.txt CMakeFiles
    set -e
    exawind_cmake
}

exawind_make ()
{
    local extra_args=${EXAWIND_NUM_JOBS:-8}

    if [ "$#" == "0" ] ; then
        extra_args="-j ${num_tasks}"
    else
        extra_args="$@"
    fi

    command make ${extra_args}
}

exawind_ctest ()
{
    export OMP_NUM_THREADS=${OMP_NUM_THREADS:-1};
    export OMP_PROC_BIND=${OMP_PROC_BIND:-true};
    export OMP_PLACES=${OMP_PLACES:-threads}

    local extra_args=${EXAWIND_NUM_JOBS:-8}

    if [ "$#" == "0" ] ; then
        extra_args="-j ${num_tasks}"
    else
        extra_args="$@"
    fi

    command ctest ${extra_args}
}

exawind_rpath_dirs ()
{
    local rpath_dirs=""

    for dep in "$@" ; do
        root_dir_var="$(echo $dep | sed -e 's/\([-a-zA-Z0-9_]*\).*/\1/;s/-/_/' | tr '[:lower:]' '[:upper:]')_ROOT_DIR"
        libpath=${!root_dir_var}/lib
        if [ -d ${libpath} ] ; then
            rpath_dirs=${libpath}:${rpath_dirs}
        fi

        lib64path=${!root_dir_var}/lib64
        if [ -d ${lib64path} ] ; then
            rpath_dirs=${lib64path}:${rpath_dirs}
        fi
    done
    echo $rpath_dirs
}

exawind_main ()
{
    if [ "$#" == "0" ] ; then
        exawind_env && exawind_proj_env && exawind_cmake && exawind_make
    else
        subcmd=$1

        case ${subcmd} in
            "-h" | "--help" | "-?")
                exawind_help
                exit 0
                ;;
            *)
                shift
                exawind_env && exawind_proj_env && exawind_${subcmd} "$@"

                if [ $? = 127 ] ; then
                    echo "ERROR: ${subcmd} is not a valid command."
                    exawind_help
                fi
                ;;
        esac
    fi
}
