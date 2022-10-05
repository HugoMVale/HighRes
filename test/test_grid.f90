module test_grid
    !! Test for module 'grid' using test-drive.
   use grid, only: grid1
   use iso_fortran_env, only: real64, stderr => error_unit
   use testdrive, only: new_unittest, unittest_type, error_type, check
   implicit none
   private

   public :: collect_tests_grid

   integer, parameter :: rk = real64
   logical, parameter :: verbose = .false.
   real(rk), parameter :: atol = 1e-10_rk

contains

   !> Collect all exported unit tests
   subroutine collect_tests_grid(testsuite)
      ! Collection of tests
      type(unittest_type), allocatable, intent(out) :: testsuite(:)

      testsuite = [ &
                  new_unittest("linear", test_linear), &
                  new_unittest("log", test_log), &
                  new_unittest("geometric", test_geometric), &
                  new_unittest("bilinear", test_bilinear) &
                  ]

   end subroutine

   subroutine test_linear(error)
      type(error_type), allocatable, intent(out) :: error
      type(grid1) :: gx
      real(rk) :: xmin, xmax
      integer :: nc

      ! General settings
      xmin = 0._rk
      xmax = 1e3_rk
      nc = 1000000

      ! Make grid
      call gx%linear(xmin, xmax, nc, name="F [N]")

      ! Checks
      call check(error, gx%ncells, nc)
      if (allocated(error)) return
      call check(error, gx%edges(0), xmin, thr=atol)
      if (allocated(error)) return
      call check(error, gx%edges(nc), xmax, thr=atol)
      if (allocated(error)) return
      call check(error, gx%left, gx%edges(0:nc - 1))
      if (allocated(error)) return
      call check(error, gx%right, gx%edges(1:nc))
      if (allocated(error)) return
      call check(error, gx%width, gx%right - gx%left)
      if (allocated(error)) return
      call check(error, gx%center, (gx%left + gx%right)/2)
      if (allocated(error)) return

   end subroutine test_linear

   subroutine test_log(error)
      type(error_type), allocatable, intent(out) :: error
      type(grid1) :: gx
      real(rk) :: xmin, xmax
      integer :: nc

      ! General settings
      xmin = 1e-1_rk
      xmax = 1e3_rk
      nc = 1000000

      ! Make grid
      call gx%log(xmin, xmax, nc, name="T [K]")

      ! Checks
      call check(error, gx%ncells, nc)
      if (allocated(error)) return
      call check(error, gx%edges(0), xmin, thr=atol)
      if (allocated(error)) return
      call check(error, gx%edges(nc), xmax, thr=atol)
      if (allocated(error)) return
      call check(error, gx%left, gx%edges(0:nc - 1))
      if (allocated(error)) return
      call check(error, gx%right, gx%edges(1:nc))
      if (allocated(error)) return
      call check(error, gx%width, gx%right - gx%left)
      if (allocated(error)) return
      call check(error, gx%center, (gx%left + gx%right)/2)
      if (allocated(error)) return

   end subroutine test_log

   subroutine test_geometric(error)
      type(error_type), allocatable, intent(out) :: error
      type(grid1) :: gx
      real(rk) :: xmin, xmax, ratio
      integer :: nc

      ! General settings
      xmin = 1e-1_rk
      xmax = 1e3_rk
      ratio = 1.1_rk
      nc = 1000

      ! Make grid
      call gx%geometric(xmin, xmax, ratio, nc, name="P [W]")

      ! Checks
      call check(error, gx%ncells, nc)
      if (allocated(error)) return
      call check(error, gx%edges(0), xmin, thr=atol)
      if (allocated(error)) return
      call check(error, gx%edges(nc), xmax, thr=atol)
      if (allocated(error)) return
      call check(error, gx%left, gx%edges(0:nc - 1))
      if (allocated(error)) return
      call check(error, gx%right, gx%edges(1:nc))
      if (allocated(error)) return
      call check(error, gx%width, gx%right - gx%left)
      if (allocated(error)) return
      call check(error, gx%center, (gx%left + gx%right)/2)
      if (allocated(error)) return

   end subroutine test_geometric

   subroutine test_bilinear(error)
      type(error_type), allocatable, intent(out) :: error
      type(grid1) :: gx
      real(rk) :: xmin, xcross, xmax
      integer :: nc(2), ncsum

      ! General settings
      xmin = 0._rk
      xcross = 1e1_rk
      xmax = 1e3_rk
      nc = [124, 365]
      ncsum = sum(nc)

      ! Make grid
      call gx%bilinear(xmin, xcross, xmax, nc, name="W [J]")

      ! Checks
      call check(error, gx%ncells, ncsum)
      if (allocated(error)) return
      call check(error, gx%edges(0), xmin, thr=atol)
      if (allocated(error)) return
      call check(error, gx%edges(nc(1)), xcross, thr=atol)
      if (allocated(error)) return
      call check(error, gx%edges(ncsum), xmax, thr=atol)
      if (allocated(error)) return
      call check(error, gx%left, gx%edges(0:ncsum - 1))
      if (allocated(error)) return
      call check(error, gx%right, gx%edges(1:ncsum))
      if (allocated(error)) return
      call check(error, gx%width, gx%right - gx%left)
      if (allocated(error)) return
      call check(error, gx%center, (gx%left + gx%right)/2)
      if (allocated(error)) return

   end subroutine test_bilinear

end module test_grid
