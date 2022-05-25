# zfp-experiment

```console
$ chmod +x run.sh
$ ./run.sh
```

## References and Excerpts

- The only Fortran code example: [here](https://github.com/LLNL/zfp/blob/develop/tests/fortran/testFortran.f)

- ZFP's Fortran interface: [source](https://github.com/LLNL/zfp/blob/develop/fortran/zfp.f90).

- [ZFP Tutorial](https://zfp.readthedocs.io/en/latest/tutorial.html)

- [CUDA Execution Policy](https://zfp.readthedocs.io/en/release0.5.5/execution.html):

> The CUDA version of zfp supports both host and device memory. If device memory is allocated for fields or compressed streams, this is automatically detected and handled in a consistent manner. For example, with compression, if host memory pointers are provided for both the field and compressed stream, then device memory will transparently be allocated and the uncompressed data will be copied to the GPU. Once compression completes, the compressed stream is copied back to the host and device memory is deallocated. If both pointers are device pointers, then no copies are made. Additionally, any combination of mixing host and device pointers is supported.
