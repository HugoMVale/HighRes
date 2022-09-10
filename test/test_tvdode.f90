module test_tvdode
!----------------------------------------------------------------------------------------------
!! Test for module 'tvdode' using test-drive.
!----------------------------------------------------------------------------------------------
    use tvdode, only : rktvd, mstvd
    use iso_fortran_env, only : real64, error_unit
    use testdrive, only : new_unittest, unittest_type, error_type, check
    implicit none
    private

    public :: collect_tests_tvdode

    integer, parameter :: rk = real64
    logical, parameter :: verbose = .false.
    integer, parameter :: nu = 10
    real(rk) :: a(nu)

    contains

    !> Collect all exported unit tests
    subroutine collect_tests_tvdode(testsuite)
        ! Collection of tests
        type(unittest_type), allocatable, intent(out) :: testsuite(:)

        testsuite = [ &
        new_unittest("rktvd", test_rktvd), &
        new_unittest("mstvd", test_mstvd) &
        ]

    end subroutine

    subroutine test_rktvd(error)
        type(error_type), allocatable, intent(out) :: error
        integer :: order, itask, istate
        real(rk) :: t, tout, dt, u(nu), uref(nu), rtol(3)
        integer :: i

        istate = 1
        itask = 1
        rtol = [2e-2_rk, 1e-3_rk, 1e-3_rk]

        ! Analytical solution at t=tout
        ! We use a simple series of 1st order ode's
        tout = 1._rk
        do i = 1, size(u)
          a(i) = 1._rk + real(i-1,rk)
          uref(i) = exp(a(i))*tout
        end do

        ! Run check for each order
        do order = 1, 3

          ! Initial conditions and ode settings
          u = 1._rk
          t = 0._rk
          dt = (tout/3000)*order

          ! Numerical solution at t=tout
          call rktvd(fu, u, t, tout, dt, order, itask, istate)

          ! Check error
          call check(error, u, uref, rel=.true., thr=rtol(order))

          ! Show results if test fails (for debugging)
          if (allocated(error) .or. verbose) then
            write(error_unit, '(2(a6), 2(a26))') "order", "i", "u(i)", "uref(i)"
            do i = 1, size(u)
              write(error_unit, '(2(i6), 2(es26.16e3))'), order, i, u(i), uref(i)
            end do
          end if

      end do

    end subroutine test_rktvd

    subroutine test_mstvd(error)
      type(error_type), allocatable, intent(out) :: error
      integer :: istate
      real(rk) :: t, tout, dt, u(nu), uref(nu), uold(nu,4), udotold(nu,4)
      integer :: i

      istate = 1

      ! Analytical solution at t=tout
      tout = 1_rk
      do i = 1, size(u)
        a(i) = 1._rk + real(i-1,rk)
        uref(i) = exp(a(i))*tout
      end do

      ! Initial conditions and ode settings
      u = 1._rk
      t = 0._rk
      dt = tout/1000

      ! Numerical solution at t=tout
      call mstvd(fu, u, t, tout, dt, uold, udotold, istate)

      ! Check error
      call check(error, u, uref, rel=.true., thr=1e-3_rk)

      ! Show results if test fails (for debugging)
      if (allocated(error) .or. verbose) then
        write(error_unit, '(a4, 2(a26))') "i", "u(i)", "uref(i)"
        do i = 1, size(u)
          write(error_unit, '(i4, 2(es26.16e3))') i, u(i), uref(i)
        end do
      end if

    end subroutine test_mstvd

    !> Simple linear u'(u) to test ode solvers
    pure subroutine fu(t, u, udot)
      real(rk), intent(in) :: t, u(:)
      real(rk), intent(out) :: udot(:)
      udot = a*u
    end subroutine


end module test_tvdode
