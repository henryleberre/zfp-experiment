nvc++ -Izfp/include -O3 main.cpp -o cpp -lzfp -Lzfp/build/lib64

LD_LIBRARY_PATH="zfp/build/lib64:$LD_LIBRARY_PATH" ./cpp
