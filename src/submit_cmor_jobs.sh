#/bin/bash -l

start_year=1979
end_year=2024

for year in $(seq $start_year $end_year); do
    echo "Submitting ${year}"

    start_date=${year}01
    end_date=${year}12

    sbatch master_cmor_loop.sh -s $start_date -e $end_date

done
