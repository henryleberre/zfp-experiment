#!/usr/bin/env bash

set -o xtrace

mkdir -p build
cd build

cmake ..

make -j 8

time ./zfp_experiment
