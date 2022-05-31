
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

#define BENCH

void test_engine(FILE* fp, zfp_exec_policy policy) {
    std::uniform_real_distribution<double> unif(0,1);
    std::default_random_engine re;

    for (std::uint32_t LEN = 1; LEN < (std::uint32_t)10e7; LEN*=10) {
        printf("%s LEN %d\n", "omp.dat", LEN);

        for (double RATE = 1e-1; RATE <= 1e1; RATE += 2e-1) {

            const std::size_t original_size = sizeof(double)*LEN;
            double * const pOrignal = reinterpret_cast<double*>(std::malloc(original_size));

            for (std::uint32_t i = 0; i < LEN; ++i) {
                pOrignal[i] = unif(re);
            }

            zfp_stream* const stream = zfp_stream_open(NULL);
            if (zfp_stream_set_execution(stream, policy)) {
                printf("    - %d %d %.10f engine available. Activated.\n", policy, LEN, RATE);
            } else {
                printf("    - %d not available..\n", policy);
                return;
            }

            const double actual_rate = zfp_stream_set_rate(stream, RATE, zfp_type_double, 1, false);

            zfp_field * const field = zfp_field_1d(pOrignal, zfp_type_double, LEN);

            const std::uint32_t MAX_SIZE_compressed = zfp_stream_maximum_size(stream, field);

            double * const pCompressed = (double*)std::malloc(MAX_SIZE_compressed);

            bitstream* bits = stream_open(pCompressed, MAX_SIZE_compressed);

            zfp_stream_set_bit_stream(stream, bits);
            zfp_stream_rewind(stream);

            auto t1 = std::chrono::high_resolution_clock::now();

            std::size_t zfpsize = zfp_compress(stream, field);

            auto t2 = std::chrono::high_resolution_clock::now();

            if (!zfpsize) {
                std::printf("    -> Fatal error: Failed to compress.\n");
            }

            const double elapsed = std::chrono::duration_cast<std::chrono::duration<double>>(t2-t1).count();
            std::fprintf(fp, "%d, %d, %.10f, %d, %d, %.10f, %.10f, %.10f\n", (int)policy, LEN, RATE, LEN*8, zfpsize, actual_rate, elapsed, original_size / (float)zfpsize);
            
	    std::free(pOrignal);
	    std::free(pCompressed);
	}
    }
}

int main(int argc, char** argv) {
    FILE* fp = std::fopen("cpp_results.txt", "w");

    test_engine(fp, zfp_exec_serial);
    test_engine(fp, zfp_exec_omp);
    test_engine(fp, zfp_exec_cuda);
	
    std::fclose(fp);


    return 0;
}
