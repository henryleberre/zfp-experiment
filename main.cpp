
#include <cmath>
#include <array>
#include <string>
#include <chrono>
#include <cstdio>
#include <random>
#include <cstdlib>
#include <cstdint>
#include <cstring>

#include <zfp.h>

#include <cuda.h>
#include <curand.h>
#include <cuda_runtime.h>
#include <curand_kernel.h>
#include <device_launch_parameters.h>

void test_engine(FILE* fp, zfp_exec_policy policy) {
    std::uniform_real_distribution<double> unif(0,1);
    std::default_random_engine re;

    for (std::uint32_t LEN = 100; LEN < (std::uint32_t)10e7; LEN*=10) {
        printf("LEN %d\n", LEN);

        const std::size_t original_size = sizeof(double)*LEN;
        double * const pOriginalCPU = reinterpret_cast<double*>(std::malloc(original_size));

        for (std::uint32_t i = 0; i < LEN; ++i) {
            pOriginalCPU[i] = unif(re);
        }

	    double* pOriginalGPU = nullptr;
	    cudaMalloc(&pOriginalGPU, original_size);
	    cudaMemcpy(pOriginalGPU, pOriginalCPU, original_size, cudaMemcpyKind::cudaMemcpyHostToDevice);

	    std::free(pOriginalCPU);

        zfp_stream* const stream = zfp_stream_open(NULL);
        if (zfp_stream_set_execution(stream, policy)) {
            printf("    - %d %d engine available. Activated.\n", policy, LEN);
        } else {
            printf("    - %d not available..\n", policy);
            std::exit(-1);
        }

        for (double RATE = 0.01; RATE <= 10; RATE += 0.5) {
            const double actual_rate = zfp_stream_set_rate(stream, RATE, zfp_type_double, 1, false);

            zfp_field * const field = zfp_field_1d(pOriginalGPU, zfp_type_double, LEN);

            const std::uint32_t MAX_SIZE_compressed = zfp_stream_maximum_size(stream, field);

            double * const pCompressedGPU = nullptr;
	        printf("%d", (int)cudaMalloc((void**)&pCompressedGPU, MAX_SIZE_compressed));


            bitstream* bits = stream_open(pCompressedGPU, MAX_SIZE_compressed);

            zfp_stream_set_bit_stream(stream, bits);
            zfp_stream_rewind(stream);

            auto t1 = std::chrono::high_resolution_clock::now();

            std::size_t zfpsize = zfp_compress(stream, field);

            auto t2 = std::chrono::high_resolution_clock::now();

            if (!zfpsize) {
                std::printf("    -> Fatal error: Failed to compress (%d).\n", (int)zfpsize);
            }

            const double elapsed = std::chrono::duration_cast<std::chrono::duration<double>>(t2-t1).count();
            std::fprintf(fp, "%d, %d, %.10f, %d, %d, %.10f, %.10f, %.10f\n", (int)policy, LEN, RATE, LEN*8, zfpsize, actual_rate, elapsed, original_size / (float)zfpsize);
            
	        cudaFree((void*)pCompressedGPU);
            zfp_field_free(field);
        }
    
    	cudaFree((void*)pOriginalGPU);
        zfp_stream_close(stream);
    }
}

int main(int argc, char** argv) {
    FILE* fp = std::fopen("cpp_results.txt", "w");

    //test_engine(fp, zfp_exec_serial);
    //test_engine(fp, zfp_exec_omp);
    test_engine(fp, zfp_exec_cuda);
	
    std::fclose(fp);


    return 0;
}
