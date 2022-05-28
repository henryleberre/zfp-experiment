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
    integer (kind=8) :: i = 1, LEN = 100000
    real*8 :: accuracy = 1e-2
    real*8, dimension(:), target, allocatable :: original
    byte,   dimension(:), target, allocatable :: compressed
    type(c_ptr) :: pOriginal, pCompressed
    integer (kind=8) :: MAX_SIZE_compressed, SIZE_compressed, SIZE_decompressed
    real*8 :: res, compression_ratio

    ! ZFP datatypes
    type(zFORp_field)     :: field     ! Field to describe the region to be compressed
    type(zFORp_stream)    :: stream    ! Stream used to compress data (holds compression params)
    type(zFORp_bitstream) :: bitstream ! Bitstream to handle compression I/O

    print *, "- [ZFP Experiment] @ Henry A. Le Berre"

    ! Initialize OpenACC
    devtype = acc_get_device_type()
    devNum  = acc_get_num_devices(devtype)

    print '(" - [INIT]")'
    print '("   - OpenACC Device "I0" (/"I0")")', 0, devNum

    call acc_set_device_num(0, devtype)   

    ! Intialize Timing
    call system_clock(COUNT_RATE=cr, COUNT_MAX=cm) 
    rate = real(cr)

    ! Create & Insert data into the buffer to be compressed
    allocate(original(LEN))

    call system_clock(t1)
        original(1)=0
        original(2)=1
        do i = 3, LEN
            original(i)=original(i-1)+original(i-2)
        end do
    call system_clock(t2)

    elapsed = (t2-t1) / rate

    print '("   - Took "D"s to fill the original array of size "I0" bytes ("I0" items).")', elapsed, LEN*8, LEN

    print '(" - [COMPRESSION]")'

    pOriginal = c_loc(original)
    field = zFORp_field_1d(pOriginal, zFORp_type_double, INT(LEN))

    !bitstream%object = c_null_ptr
    stream = zFORp_stream_open(bitstream)
    res    = zFORp_stream_set_accuracy(stream, accuracy)
    MAX_SIZE_compressed = zFORp_stream_maximum_size(stream, field)

    print '("   - Compressed size will be smaller than or equal to "I0" bytes ("I0" items eq.).")', MAX_SIZE_compressed, MAX_SIZE_compressed / 8

    ! Create Bistream & Allocate Bistream buffer
    allocate(compressed(MAX_SIZE_compressed))
    pCompressed = c_loc(compressed)

    bitstream = zFORp_bitstream_stream_open(pCompressed, MAX_SIZE_compressed)
    call zFORp_stream_set_bit_stream(stream, bitstream)

    !!$acc data copy(original)

    call system_clock(t1)
        SIZE_compressed = zFORp_compress(stream, field)
    call system_clock(t2)

    elapsed = t2 - t1

    print '("   - Took "D"s to compress to "I0" bytes ("I0" items eq.).")', elapsed, SIZE_compressed, SIZE_compressed / 8
    
    compression_ratio = (LEN*8) / SIZE_compressed
    print '("   - Effective compression ratio of "D"")', compression_ratio

    print '(" - [DECOMPRESSION]")'
    call zFORp_stream_rewind(stream)

    call system_clock(t1)
        SIZE_decompressed = zFORp_decompress(stream, field)
    call system_clock(t2)    

    elapsed = t2 - t1

    print '("   - Took "D"s to decompress to "I0" bytes ("I0" items).")', elapsed, SIZE_decompressed, SIZE_decompressed / 8

    print '(" - [CHECK INTEGRITY]")'

    if (LEN*8 .ne. SIZE_decompressed) then
        print *, "  - Fatal error: The input array and decompressed arrays have different lengths."
    end if

    !zfp_stream_set_execution()
    !zfp_stream_open(NULL);

    !!$acc kernels loop
    !!$acc end kernels
    !!$acc end data

end program main
