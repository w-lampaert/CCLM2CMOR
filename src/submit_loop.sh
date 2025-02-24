#!/bin/bash -l

start_year=1979
end_year=2024

for year in $(seq $start_year $end_year); do

	sbatch master_cmor_loop.sh "${year}01" "${year}12"
done
