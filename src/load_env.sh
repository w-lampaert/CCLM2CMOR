#!/bin/bash -l

toolchain='2022a'

source ./load_modules.sh $toolchain

if [[ ! -d venv_cmor ]]; then
    python -m venv venv_cmor
    source venv_cmor/bin/activate
    pip install setuptools
    pip install cftime==1.4.1
    pip install netCDF4
else
    source venv_cmor/bin/activate
fi

