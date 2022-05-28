nvc++ -Izfp/include -O3 main.cpp -o cpp -lzfp -Lzfp/build/lib && LD_LIBRARY_PATH="zfp/build/lib:$LD_LIBRARY_PATH" ./cpp
