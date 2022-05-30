
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

void test_engine(zfp_exec_policy policy) {
        FILE* fp = std::fopen("omp.dat", "w");

    std::uniform_real_distribution<double> unif(0,1);
    std::default_random_engine re;


    for (std::uint32_t LEN = 1; LEN < (std::uint32_t)10e3; LEN*=10) {
        printf("%s LEN %d\n", "omp.dat", LEN);
        for (double ACC = 1e-1; ACC > 1e-10; ACC /= 10) {

            const std::size_t original_size = sizeof(double)*LEN;
            double * const pOrignal = reinterpret_cast<double*>(std::malloc(original_size));

            for (std::uint32_t i = 0; i < LEN; ++i) {
                pOrignal[i] = unif(re);
            }

            zfp_stream* const stream = zfp_stream_open(NULL);
            if (zfp_stream_set_execution(stream, policy) == 1) {
                printf("    - %d engine available. Activated.\n", policy);
            } else {
                printf("    - %d not available..\n", policy);
                return;
            }

            zfp_field * const field  = zfp_field_1d(pOrignal, zfp_type_double, LEN);

            zfp_stream_set_accuracy(stream, ACC);

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
                return;
            }

            const double elapsed =  std::chrono::duration_cast<std::chrono::duration<double>>(t2-t1).count();
            std::fprintf(fp, "%d, %.10f, %.10f, %.10f\n", LEN, ACC, elapsed, original_size / (float)zfpsize);
        }
    }

    std::fclose(fp);
}

int main(int argc, char** argv) {

    test_engine(zfp_exec_serial);
    test_engine(zfp_exec_omp);
    test_engine(zfp_exec_cuda);


    return 0;

#ifndef BENCH
    std::printf(" -> Compressing %d doubles (%d bytes).\n", LEN, original_size);
#endif
#ifndef BENCH
    std::printf("    - Compressed size:  <= %d bytes (%d items eq.).\n", MAX_SIZE_compressed, MAX_SIZE_compressed / sizeof(double));
    std::printf("    - Compressed tol.:  %.10f (max relative error*).\n", accuracy);
#endif


    //if (zfp_stream_set_execution(stream, zfp_exec_omp)) {
    //    printf("    - OpenMP engine available. Activated.\n");
    //}

    //if (zfp_stream_set_execution(stream, zfp_exec_cuda)) {
    //    printf("    - Cuda engine available. Activated.\n");
    //}





#ifndef BENCH
    std::printf("    - Compressed size:  %d bytes (%d items eq.)\n", zfpsize, zfpsize / sizeof(double));
    std::printf("    - Compressed ratio: %.2fx\n", original_size / (float) zfpsize);
    std::printf("    - Compression Time: %.10fs\n", std::chrono::duration_cast<std::chrono::duration<double>>(t2-t1).count());

    std::printf(" -> Decompressing %d doubles (%d bytes).\n", LEN, original_size);
#endif
    //std::memset(pOrignal, 0, original_size);
//
    //zfp_stream_rewind(stream);
    //t1 = std::chrono::high_resolution_clock::now();
    //size_t size = zfp_decompress(stream, field);
    //t2 = std::chrono::high_resolution_clock::now();

#ifndef BENCH
    std::printf("    - Decompression Time: %.10fs\n", std::chrono::duration_cast<std::chrono::duration<double>>(t2-t1).count());
#endif

    return EXIT_SUCCESS;
}
