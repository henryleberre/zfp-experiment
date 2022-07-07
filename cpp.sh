set -o xtrace

nvc++ -I/nethome/hberre3/zfp/install/include \
      -L/nethome/hberre3/zfp/install/lib     \
      -I/opt/nvidia/hpc_sdk/Linux_x86_64/22.5/cuda/include \
      -L/opt/nvidia/hpc_sdk/Linux_x86_64/22.5/cuda/lib64   \
      -I/opt/nvidia/hpc_sdk/Linux_x86_64/22.5/cuda/11.0/targets/x86_64-linux/include \
      -L/opt/nvidia/hpc_sdk/Linux_x86_64/22.5/cuda/11.0/targets/x86_64-linux/lib \
      -O3 main.cpp -o cpp -lcudart -lzfp

LD_LIBRARY_PATH="/nethome/hberre3/zfp/install/lib:$LD_LIBRARY_PATH" ./cpp
