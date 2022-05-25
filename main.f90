program main

    use openacc

    implicit none

    integer :: devNum
    integer(acc_device_kind) :: devtype

    ! Initialize OpenACC
    devtype = acc_get_device_type()
    devNum  = acc_get_num_devices(devtype)
    
    print '("OpenACC Device "I0" (/"I0")")', 0, devNum

    call acc_set_device_num(0, devtype)   

end program main
