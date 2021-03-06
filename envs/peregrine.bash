#!/bin/bash

export EXAWIND_NUM_JOBS_DEFAULT=24
export EXAWIND_MODULES_DIR=/nopt/nrel/ecom/ecp/base/modules

# Mapping identifying versions to load for each dependency
declare -A EXAWIND_MODMAP
EXAWIND_MODMAP[trilinos]=trilinos/develop

exawind_env_gcc ()
{
    module purge
    module load gcc/6.2.0
    # For extra protection, explicitly disable path to Intel modules in user environment
    module unuse ${EXAWIND_MODULES_DIR}/intel-18.1.163
    module use ${EXAWIND_MODULES_DIR}/gcc-6.2.0

    module load binutils openmpi/3.1.1 netlib-lapack cmake

    export CC=$(which gcc)
    export CXX=$(which g++)
    export FC=$(which gfortran)

    echo "==> Using modules: $(readlink -f ${EXAWIND_MODULES_DIR}/gcc-6.2.0)"
}

exawind_env_intel ()
{
    module purge
    module load gcc/6.2.0
    module use ${EXAWIND_MODULES_DIR}/gcc-6.2.0
    module load intel-parallel-studio/cluster.2018.1
    module use ${EXAWIND_MODULES_DIR}/intel-18.1.163

    module load binutils intel-mpi intel-mkl cmake

    export CC=$(which icc)
    export CXX=$(which icpc)
    export FC=$(which ifort)

    echo "==> Using modules: $(readlink -f ${EXAWIND_MODULES_DIR}/intel-18.1.163)"
}

exawind_load_deps ()
{
    for dep in $@ ; do
        root_dir_var="$(echo $dep | sed -e 's/\([-a-zA-Z0-9_]*\).*/\1/;s/-/_/' | tr '[:lower:]' '[:upper:]')_ROOT_DIR"

        local depname=${EXAWIND_MODMAP[$dep]:-$dep}
        if [ -z ${!root_dir_var} ] ; then
            module load ${depname}
        fi
        echo "==> ${depname} = ${!root_dir_var}"
    done
}
