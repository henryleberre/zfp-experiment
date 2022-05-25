#!/usr/bin/env bash

cd build
CC=mpicc CXX=mpicxx FC=mpif90 cmake ..
make -j 8
./zfp_experiment
