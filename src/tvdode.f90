module tvdode
!>---------------------------------------------------------------------------------------------
!> This module contains two TVD (total variation diminishing) high-order schemes for solving
!> initial value problems. It is very important to use TVD schemes for time integration. Even
!> with a TVD spacial discretization, if the time discretization is done by a non-TVD method,
!> the result may be oscillatory.
!> Source: ICASE 97-65 by Shu, 1997.
!>---------------------------------------------------------------------------------------------
    use, intrinsic :: iso_fortran_env, only : real64
    implicit none
    private

    public :: rktvd123, mstvd3

    integer, parameter :: rk = real64

    abstract interface
        pure subroutine integrand(t, u, udot)
            import :: rk
            real(rk), intent(in) :: t, u(:)
            real(rk), intent(out) :: udot(:)
        end subroutine
    end interface

    contains

    pure subroutine rktvd123(fu, u, t, tout, dt, order, itask, istate)
    !>-----------------------------------------------------------------------------------------
    !> This subroutine implements the optimal 1st, 2nd and 3rd order TVD RK methods described
    !> in ICASE 97-65 (Shu, 1997).
    !> The routine was built to work similarly to LSODE.
    !>
    !> ARGUMENTS:
    !> fu         function with the derivative u'(t)
    !> u          vector(N) with the variables to integrate u(t)
    !> t          time; on return it will be the current value of t (close to tout)
    !> tout       time where next output is desired
    !> dt         time step
    !> order      order of the method (1, 2 or 3)
    !> itask      flag incating the task to be performed
    !>            1   normal integration until tout
    !>            2   single dt step
    !> istate     flag incating the state of the integration
    !>            1   first call for a problem
    !>            2   subsequent call for a problem
    !>
    !> INTERNAL VARIABLES:
    !> ui        vector(N) with intermediate value of u(t)
    !> udot      vector(N) with evaluated derivative of u(t)
    !>
    !> TO DO:
    !> Adjust dt in final step to avoid overshoting tout by some fraction of dt.
    !>-----------------------------------------------------------------------------------------
    procedure(integrand) :: fu
    real(rk), intent(inout) :: u(:), t
    real(rk), intent(in) :: tout, dt
    integer, intent (in) :: order, itask
    integer, intent (inout) :: istate
    character(:), allocatable :: msg
    real(rk), dimension(size(u)) :: ui, udot

       !> Check input conditions
        if (t > tout) return

        if (istate ==1) then          
            if (order < 1 .OR. order > 3) then
                msg = "Invalid input 'order' in 'rktvd'. Valid set: {1, 2, 3}."
                error stop msg
            end if
            if (itask < 1 .OR. itask > 2) then
                msg = "Invalid input 'itask' in 'rktvd'. Valid set: {1, 2}."
                error stop msg
            end if
        else if (istate < 1 .OR. istate > 2) then
            msg = "Invalid value 'istate' in 'rktvd'. Valid set: {1, 2}."
            error stop msg
        end if

        !> Algorthm selection
        select case (order)
        !> ------------------------------ 1st order RK (Euler) --------------------------------
        !> Equation (4.10), page 43.
            case (1)
                do
                    call fu(t, u, udot)
                    u = u + dt*udot
                    t = t + dt
                    if (t >= tout .OR. itask == 2) exit
                end do

        !> -------------------------------- 2nd order RK --------------------------------------
        !> Equation (4.10), page 43.
            case (2)
                do
                    call fu(t, u, udot)
                    ui = u + dt*udot
                    call fu(t, ui, udot)
                    u = (u + ui + dt*udot)/2
                    t = t + dt
                    if (t >= tout .OR. itask == 2) exit
                end do

        !> -------------------------------- 3rd order RK --------------------------------------
        !> Equation (4.11), page 43.
            case (3)
                do
                    call fu(t, u, udot)
                    ui = u + dt*udot
                    call fu(t, ui, udot)
                    ui = (3*u + ui + dt*udot)/4
                    call fu(t, ui, udot)
                    u = (u + 2*ui + 2*dt*udot)/3
                    t = t + dt
                    if (t >= tout .OR. itask == 2) exit
                end do

        end select

        !> If we got so far, all must be ok
        !> To be extended
        if (istate == 1) then
            istate = 2
        end if

    end subroutine rktvd123
    !>#########################################################################################


    pure subroutine mstvd3(fu, u, t, tout, dt, uold, udotold, istate)
    !>-----------------------------------------------------------------------------------------
    !> This subroutine implements a 5-step, 3rd order TVD multi-step method described
    !> in ICASE 97-65 (Shu, 1997). In theory, this method should have an efficiency 1.5 times
    !> higher than the RK method of the same order. However, in practice they appear to be
    !> almost identical.
    !> The routine was built to work similarly to LSODE.
    !>
    !> ARGUMENTS:
    !> fu            function with the derivative u'(t)
    !> u             vector(N) with variables to integrate u(t)
    !> t             time; on return it will be the current value of t (close to tout)
    !> tout          time where next output is desired
    !> dt            time step
    !> istate        index to specify the state of the calculation (1 for the first call)
    !> uold          array(N,4) with the 4 previous values of u(t)
    !> udotold       array(N,4) with the 4 previous values of utot(t)
    !>
    !> INTERNAL VARIABLES:
    !> ui            vector(N) with intermediate value of u(t)
    !> udot          vector(N) with evaluated derivative of u(t)
    !>-----------------------------------------------------------------------------------------
    procedure(integrand) :: fu
    real(rk), intent(inout) :: u(:), t, uold(:,:), udotold(:,:)
    real(rk), intent(in) :: tout, dt
    integer, intent (inout) :: istate
    real(rk), dimension(size(u)) :: ui, udot
    integer, parameter :: order=3
    character(:), allocatable :: msg
    integer :: itask_rktvd, istate_rktvd

        !> Check input conditions
        if (t > tout) return

        if (size(uold,2) /= 4 .OR. size(udotold,2) /= 4) then
            msg = "Invalid dimensions of arrays 'uold' or 'udotold' in 'mstvd3'."
            error stop msg
        end if

        if (istate < 1 .OR. istate > 2) then
            msg = "Invalid input 'istate' in 'mstvd3'. Valid set: {1, 2}."
            error stop msg
        end if

        !> The first 4 starting values must be computed with a single-step method: we chose
        !> the RK method of the same order.
        !> The factor 2 in 't+2*dt' is not important, it just needs to be larger than 1.0
        !> so that one full 'dt' step can be computed.
        if (istate == 1) then

            itask_rktvd = 2
            istate_rktvd = 1

            uold(:,4) = u
            call fu(t, u, udotold(:,4))

            call rktvd123(fu, u, t, t+2*dt, dt, order, itask_rktvd, istate_rktvd)
            uold(:,3) = u
            call fu(t, u, udotold(:,3))

            call rktvd123(fu, u, t, t+2*dt, dt, order, itask_rktvd, istate_rktvd)
            uold(:,2) = u
            call fu(t, u, udotold(:,2))

            call rktvd123(fu, u, t, t+2*dt, dt, order, itask_rktvd, istate_rktvd)
            uold(:,1) = u
            call fu(t, u, udotold(:,1))

            call rktvd123(fu, u, t, t+2*dt, dt, order, itask_rktvd, istate_rktvd)

            istate=2

        end if


        !> Equation (4.26), page 48.
        do

            if (t > tout) exit

            call fu(t, u, udot)
            ui = (25*u + 50*dt*udot + 7*uold(:,4) + 10*dt*udotold(:,4))/32
            t = t + dt

            !> Shift u values one step into the past
            uold(:,4) = uold(:,3)
            uold(:,3) = uold(:,2)
            uold(:,2) = uold(:,1)
            uold(:,1) = u
            u  = ui

            !> Shift udot values one step into the past
            udotold(:,4) = udotold(:,3)
            udotold(:,3) = udotold(:,2)
            udotold(:,2) = udotold(:,1)
            udotold(:,1) = udot

        end do

    end subroutine mstvd3
    !>#########################################################################################

end module tvdode
!>#############################################################################################
