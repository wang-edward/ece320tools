#!/bin/bash
echo "This script will automatically run all the benchmarks you've placed in $1/verif/data, and compare your trace output to the golden trace files using JZJ's autograder!"
echo "To add more benchmarks, copy the .x files for the desired benchmarks from the rv32-benchmarks repo into $1/verif/data."

filter="$2"

source $1/env.sh

num_benchmarks=0
num_passed=0
fails=()
for xfile in $1/verif/data/*; do
    benchmark=$(basename "$xfile" .x)

    if [[ -n "$filter" && "$benchmark" != "$filter" ]]; then
        continue
    fi

    num_benchmarks=$(($num_benchmarks + 1));

    make -C "$1/verif/scripts" -s run TEST=test_pd MEM_PATH="../data/$benchmark.x"

    golden=$(realpath "$1/verif/golden_sim/$benchmark.trace")
    user=$(realpath "$1/verif/sim/verilator/test_pd/$benchmark.trace")
    output=$(cargo run --release --bin pd6simdiff "$golden" "$user")
    echo "$output"

    if [[ $output != *"At least one error"* ]]; then
       num_passed=$(( num_passed + 1 ))
    else
        fails+=("$benchmark")
    fi
done
echo "$num_passed/$num_benchmarks passed! See output for details on (potential) error messages"

if (( ${#fails[@]} > 0 )); then
    echo "Failed tests:"
    for f in "${fails[@]}"; do
        echo "  - $f"
    done
fi

echo
echo "Thanks for using PD6 autotest :)"
