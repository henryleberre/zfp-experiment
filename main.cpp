
#include <cmath>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cstring>

#include <zfp.h>

int main(int argc, char** argv) {
    
    constexpr std::uint32_t LEN      = 1e9 / sizeof(double);
    constexpr double        accuracy = 1e-7;

    const std::size_t original_size = sizeof(double)*LEN;
    double * const pOrignal = reinterpret_cast<double*>(std::malloc(original_size));

    pOrignal[0] = 0; pOrignal[1] = 1;

    for (std::uint32_t i = 2; i < LEN; ++i) {
        pOrignal[i] = pOrignal[i-1] + pOrignal[i-2];
    }

    zfp_field * const field  = zfp_field_1d(pOrignal, zfp_type_double, LEN);
    zfp_stream* const stream = zfp_stream_open(NULL);

    zfp_stream_set_accuracy(stream, accuracy);
    std::printf(" -> Compressing %d doubles (%d bytes).\n", LEN, original_size);
    const std::uint32_t MAX_SIZE_compressed = zfp_stream_maximum_size(stream, field);
    std::printf("    - Compressed size:  <= %d bytes (%d items eq.).\n", MAX_SIZE_compressed, MAX_SIZE_compressed / sizeof(double));
    std::printf("    - Compressed tol.:  %.10f (max relative error*).\n", accuracy);
    
    double * const pCompressed = (double*)std::malloc(MAX_SIZE_compressed);
    
    bitstream* bits = stream_open(pCompressed, MAX_SIZE_compressed);

    zfp_stream_set_bit_stream(stream, bits);
    zfp_stream_rewind(stream);


    //if (zfp_stream_set_execution(stream, zfp_exec_omp)) {
    //    printf("    - OpenMP engine available. Activated.\n");
    //}

    //if (zfp_stream_set_execution(stream, zfp_exec_cuda)) {
    //    printf("    - Cuda engine available. Activated.\n");
    //}

    auto t1 = std::chrono::high_resolution_clock::now();

    std::size_t zfpsize = zfp_compress(stream, field); 

    auto t2 = std::chrono::high_resolution_clock::now();

    if (!zfpsize) {
        std::printf("    -> Fatal error: Failed to compress.\n");
        return -1;
    }

    std::printf("    - Compressed size:  %d bytes (%d items eq.)\n", zfpsize, zfpsize / sizeof(double));
    std::printf("    - Compressed ratio: %.2fx\n", original_size / (float) zfpsize);
    std::printf("    - Compression Time: %.10fs\n", std::chrono::duration_cast<std::chrono::duration<double>>(t2-t1).count());

    std::printf(" -> Decompressing %d doubles (%d bytes).\n", LEN, original_size);

    std::memset(pOrignal, 0, original_size);

    zfp_stream_rewind(stream);
    t1 = std::chrono::high_resolution_clock::now();
    size_t size = zfp_decompress(stream, field);
    t2 = std::chrono::high_resolution_clock::now();

    std::printf("    - Decompression Time: %.10fs\n", std::chrono::duration_cast<std::chrono::duration<double>>(t2-t1).count());

    return EXIT_SUCCESS;
}
