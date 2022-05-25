#!/usr/bin/env bash

mkdir -p build
cd build

CC=mpicc CXX=mpicxx FC=mpif90 cmake ..
make -j 8

time ./zfp_experiment
