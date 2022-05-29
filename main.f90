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
    real    :: elapsed
    real    :: rate
    integer :: t1, t2

    ! ZFP test arrays & settings
    integer (kind=8) :: i = 1, LEN = 100
    real*8 :: accuracy = 1e-2
    real*8, dimension(:), target, allocatable :: original
    byte,   dimension(:), target, allocatable :: compressed
    real*8, dimension(:), target, allocatable :: uncompressed
    type(c_ptr) :: pOriginal, pCompressed, pUncompressed
    integer (kind=8) :: MAX_SIZE_compressed, SIZE_compressed
    integer(c_size_t) :: stream_offset
    real*8 :: res, compression_ratio

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

    ! Create & Insert data into the buffer to be compressed
    call system_clock(t1)
        allocate(original(LEN))

        original(1)=0
        original(2)=1
        do i = 3, LEN
            original(i)=original(i-1)+original(i-2)
        end do
    call system_clock(t2)

    elapsed = (t2-t1) / rate

    print '(" [INIT] Generated the original array of size "I0" bytes ("I0" items)  in "D"s .")', LEN*8, LEN, elapsed

    pOriginal = c_loc(original)
    field = zFORp_field_1d(pOriginal, zFORp_type_double, INT(LEN))

    !bitstream%object = c_null_ptr
    stream = zFORp_stream_open(bitstream)
    res    = zFORp_stream_set_accuracy(stream, accuracy)
    MAX_SIZE_compressed = zFORp_stream_maximum_size(stream, field)

    ! Create Bistream & Allocate Bistream buffer
    allocate(compressed(MAX_SIZE_compressed))
    pCompressed = c_loc(compressed)

    bitstream = zFORp_bitstream_stream_open(pCompressed, MAX_SIZE_compressed)
    call zFORp_stream_set_bit_stream(stream, bitstream)

    !!$acc data copy(original)

    call zFORp_stream_rewind(stream)

    call system_clock(t1)
        stream_offset   = zFORp_compress(stream, field)
        SIZE_compressed = stream_offset
    call system_clock(t2)

    elapsed = t2 - t1

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

    print '(" [ZFPD] Decompressed to "I0" bytes ("I0" items) in "D"s.")', LEN*8, LEN, elapsed

    if (SIZE_compressed .ne. stream_offset) then
        print '(" [INTE] Failure during .")'
        stop 1
    end if

    print '(" [INTE] Success.")'

    PRINT *, original - uncompressed

    !zfp_stream_set_execution()
    !zfp_stream_open(NULL);

    !!$acc kernels loop
    !!$acc end kernels
    !!$acc end data

end program main
