program main

    use openacc

    implicit none

    ! OpenACC Setup
    integer :: devNum
    integer(acc_device_kind) :: devtype

    ! Timing
    integer :: cr, cm, elapsed
    real    :: rate
    integer :: t1, t2

    ! ZFP test arrays
    integer :: i = 1
    real*8, dimension(1000000) :: original

    ! Initialize OpenACC
    devtype = acc_get_device_type()
    devNum  = acc_get_num_devices(devtype)
    
    print '("OpenACC Device "I0" (/"I0")")', 0, devNum

    call acc_set_device_num(0, devtype)   

    ! Intialize Timing
    call system_clock(COUNT_RATE=cr, COUNT_MAX=cm) 
    rate = real(cr)

    ! Insert data into the buffer to be compressed
    call system_clock(t1)
        original(1)=0
        original(2)=1
        do i = 3, SIZE(original)
            original(i)=original(i-1)+original(i-2)
        end do
    call system_clock(t2)

    elapsed = (t2-t1) / rate

    print '(" - Took "I0"s to fill the original array of size "I0".")', elapsed, size(original)

    !$acc data copy(original)
    !!$acc kernels loop
    !!$acc end kernels
    !$acc end data

    print *, original(10)

    !

end program main
