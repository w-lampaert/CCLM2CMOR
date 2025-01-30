#!/bin/bash -l

toolchain=$1

if [[ $VSC_INSTITUTE_CLUSTER = 'dodrio' ]]; then

    if [[ $VSC_ARCH_LOCAL = 'zen3' ]]; then

        if [[ $toolchain = '2022a' ]]; then

            module purge
            module load NCO/5.1.3-foss-2022a
            module load CDO/2.0.6-gompi-2022a
            module load Python/3.10.4-GCCcore-11.3.0
            echo "Modules loaded for ${VSC_INSTITUTE_CLUSTER} on node architecture ${VSC_ARCH_LOCAL} and toolchain ${toolchain}"

         else

             echo "No modules selected for toolchain ${toolchain} on cluster ${VSC_INSTITUTE_CLUSTER} and node architecture ${VSC_ARCH_LOCAL}"; exit 2
         fi
    fi
fi
