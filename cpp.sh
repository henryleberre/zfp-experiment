set -e

nvc++ -Izfp/include -O3 main.cpp -o cpp -lcudart -lzfp -L/sw/ascent/cuda/11.0.3/lib64 -Lzfp/build/lib64

LD_LIBRARY_PATH="zfp/build/lib64:$LD_LIBRARY_PATH" ./cpp
