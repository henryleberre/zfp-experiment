program main

    use zFORp
    use openacc
    use iso_c_binding

    implicit none

    ! OpenACC Setup
    integer :: devNum
    integer(acc_device_kind) :: devtype

    ! Timing
    integer :: cr, cm, elapsed
    real    :: rate
    integer :: t1, t2

    ! ZFP test arrays & settings
    integer (kind=8) :: i = 1, LEN = 1000000
    real*8 :: accuracy = 1e-10
    real*8, dimension(:), target, allocatable :: original,  compressed,  uncompressed
    type(c_ptr) :: pOriginal, pCompressed, pUncompressed
    integer (kind=8) :: MAX_LEN_compressed, LEN_compressed
    real*8 :: res

    ! ZFP datatypes
    type(zFORp_field)     :: field     ! Field to describe the region to be compressed
    type(zFORp_stream)    :: stream    ! Stream used to compress data (holds compression params)
    type(zFORp_bitstream) :: bitstream ! Bitstream to handle compression I/O

    print *, "- [ZFP Experiment] @ Henry A. Le Berre"

    ! Initialize OpenACC
    devtype = acc_get_device_type()
    devNum  = acc_get_num_devices(devtype)

    print '(" - OpenACC Device "I0" (/"I0")")', 0, devNum

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

    print '(" - Took "I0"s to fill the original array of size "I0".")', elapsed, size(original)

    !!$acc data copy(original)

    pCompressed = c_loc(compressed)
    bitstream = zFORp_bitstream_stream_open(pCompressed, MAX_LEN_compressed)

    pOriginal = c_loc(original)
    field = zFORp_field_1d(pOriginal, zFORp_type_double, INT(LEN))

    stream = zFORp_stream_open(bitstream)
    res = zFORp_stream_set_accuracy(stream, accuracy)

    MAX_LEN_compressed = zFORp_stream_maximum_size(stream, field)

    allocate(compressed(MAX_LEN_compressed))

    call system_clock(t1)
        LEN_compressed = zFORp_compress(stream, field)
    call system_clock(t2)

    elapsed = t2 - t1

    print '(" - Took "I0"s to compress to size "I0".")', elapsed, LEN_compressed

    !zfp_stream_set_execution()
    !zfp_stream_open(NULL);

    !!$acc kernels loop
    !!$acc end kernels
    !!$acc end data

end program main
