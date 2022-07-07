program main

    use zFORp
    use openacc
    use iso_c_binding

    implicit none

    ! OpenACC Setup
    integer :: devNum
    integer(acc_device_kind) :: devtype

    ! Timing
    integer :: cr, cm
    real    :: elapsed, elapsed_compression, elapsed_decompression
    real    :: rate
    integer :: t1, t2

    ! ZFP test arrays & settings
    integer (kind=8) :: i, j, LEN
    real*8 :: accuracy = 1e-2
    real*8, dimension(:), target, allocatable :: original
    byte,   dimension(:), target, allocatable :: compressed
    real*8, dimension(:), target, allocatable :: uncompressed
    type(c_ptr) :: pOriginal, pCompressed, pUncompressed
    integer (kind=8) :: MAX_SIZE_compressed, SIZE_compressed
    integer(c_size_t) :: stream_offset
    real*8 :: compression_ratio
    real (kind=8) :: zfp_rate = 1, actual_zfp_rate

    integer(c_int), dimension(3) :: POLICIES = (/ zFORp_exec_serial, zFORp_exec_omp, zFORp_exec_cuda /)

    ! ZFP datatypes
    type(zFORp_field)     :: field     ! Field to describe the region to be compressed
    type(zFORp_stream)    :: stream    ! Stream used to compress data (holds compression params)
    type(zFORp_bitstream) :: bitstream ! Bitstream to handle (de)compression I/O

    print '("[ZFP Experiment] @ Henry A. Le Berre")'

    ! Initialize OpenACC
    devtype = acc_get_device_type()
    devNum  = acc_get_num_devices(devtype)

    call acc_set_device_num(0, devtype)

    print '(" [INIT] Bound OpenACC Device "I0" (/"I0")")', 0, devNum

    ! Intialize Timing
    call system_clock(COUNT_RATE=cr, COUNT_MAX=cm)
    rate = real(cr)

    print '(" [INIT] Initialized System Clock.")'

    open (unit=42, file="benchmark.dat", action='write',status='replace')

    do i = 1, size(POLICIES)
        i = 3
        LEN = 10
        do while(LEN .le. 1000000)

            ! Create & Insert data into the buffer to be compressed
            call system_clock(t1)
                allocate(original(LEN))

                original(1)=0
                original(2)=1
                do j = 3, LEN
                    original(j)=original(j-1)+original(j-2)
                end do
            call system_clock(t2)

            elapsed = (t2-t1) / rate

            print '(" [INIT] Generated the original array of size "I0" bytes ("I0" items) in "D"s .")', LEN*8, LEN, elapsed

            pOriginal = c_loc(original)
            field = zFORp_field_1d(pOriginal, zFORp_type_double, INT(LEN))

            !bitstream%object = c_null_ptr
            stream = zFORp_stream_open(bitstream)

            actual_zfp_rate = zFORp_stream_set_rate(stream, zfp_rate, zFORp_type_double, 1, 0)
            print '(" [INIT] Selected rate: "D".")', actual_zfp_rate

            MAX_SIZE_compressed = zFORp_stream_maximum_size(stream, field)
            print '(" [INIT] Max compressed size: "I0" bytes ("I0" items eq.).)")', MAX_SIZE_compressed, MAX_SIZE_compressed / 8

            ! Create Bistream & Allocate Bistream buffer
            allocate(compressed(MAX_SIZE_compressed))
            pCompressed = c_loc(compressed)

            print '(" [INIT] Allocated compressed buffer.")'

            bitstream = zFORp_bitstream_stream_open(pCompressed, MAX_SIZE_compressed)
            call zFORp_stream_set_bit_stream(stream, bitstream)
            call zFORp_stream_rewind(stream)

            if (zFORp_stream_set_execution(stream, POLICIES(i)) .eq. 0) then
                print '(" [INIT] ZFP Execution Policy "I0" Unsupported.")', POLICIES(i)
                deallocate(original)
                deallocate(compressed)
                cycle
            end if

            print '(" [INIT] ZFP Execution Policy "I0" Activated.")', POLICIES(i)

            !!$acc data copy(original)

            call system_clock(t1)
                stream_offset   = zFORp_compress(stream, field)
                SIZE_compressed = stream_offset
            call system_clock(t2)

            elapsed = t2 - t1
            elapsed_compression = elapsed

            print '(" [ZFPE] Compressed to "I0" bytes ("I0" items eq.) in "D"s.")', SIZE_compressed, SIZE_compressed / 8, elapsed

            compression_ratio = (LEN*8) / SIZE_compressed
            print '(" [ZFPE] Effective compression ratio of "D"")', compression_ratio

            allocate(uncompressed(LEN))
            pUncompressed = c_loc(uncompressed)

            field = zFORp_field_1d(pUncompressed, zFORp_type_double, INT(LEN))

            call zFORp_stream_rewind(stream)

            call system_clock(t1)
                stream_offset = zFORp_decompress(stream, field)
            call system_clock(t2)

            elapsed = t2 - t1
            elapsed_decompression = elapsed

            print '(" [ZFPD] Decompressed to "I0" bytes ("I0" items) in "D"s.")', LEN*8, LEN, elapsed

            if (SIZE_compressed .ne. stream_offset) then
                print '(" [INTE] Failure during .")'
                stop 1
            end if

            print '(" [INTE] Success.")'

            !PRINT *, original - uncompressed

            ! Save results
            write (42, '(I3" "I10" "I10" "ES10.4E0" "ES10.4E0:)'), POLICIES(i), LEN*8, SIZE_compressed, elapsed_compression, elapsed_decompression

            ! Deallocate temporary ZFP buffers
            deallocate(original)
            deallocate(compressed)
            deallocate(uncompressed)

            LEN = LEN*10
        end do
    end do

    close(42)

    !zfp_stream_set_execution()
    !zfp_stream_open(NULL);

    !!$acc kernels loop
    !!$acc end kernels
    !!$acc end data

end program main
