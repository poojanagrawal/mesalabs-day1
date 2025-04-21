! ***********************************************************************

      module run_star_extras

      use star_lib
      use star_def
      use const_def
      use math_lib

      implicit none

      ! declarations for xtra_coeff_os (extra resolution of overshooting zones must now be defined directly in run_star_extras)
      real(dp) :: &
         xtra_coef_os_full_on, &
         xtra_coef_os_full_off, &
         xtra_coef_os_above_nonburn, &
         xtra_coef_os_below_nonburn, &
         xtra_coef_os_above_burn_h, &
         xtra_coef_os_below_burn_h, &
         xtra_coef_os_above_burn_he, &
         xtra_coef_os_below_burn_he, &
         xtra_coef_os_above_burn_z, &
         xtra_coef_os_below_burn_z, &
         xtra_dist_os_above_nonburn, &
         xtra_dist_os_below_nonburn, &
         xtra_dist_os_above_burn_h, &
         xtra_dist_os_below_burn_h, &
         xtra_dist_os_above_burn_he, &
         xtra_dist_os_below_burn_he, &
         xtra_dist_os_above_burn_z, &
         xtra_dist_os_below_burn_z

       ! Check different stages
       logical :: ask_reached_zams, ask_h1_ign, ask_h1_burn, ask_h1_dep, &
                  ask_he_ign, ask_he_burn, ask_he_dep, ask_blue_loop
       logical :: reached_zams, h1_ign, is_chb, h1_dep, shhb, he4_ign, he4_burn, he4_dep, &
                  is_bsg, is_rsg, blue_loop


      ! these routines are called by the standard run_star check_model
      contains

      subroutine extras_controls(id, ierr)
         integer, intent(in) :: id
         integer, intent(out) :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return

         ! this is the place to set any procedure pointers you want to change
         ! e.g., other_wind, other_mixing, other_energy  (see star_data.inc)


         ! the extras functions in this file will not be called
         ! unless you set their function pointers as done below.
         ! otherwise we use a null_ version which does nothing (except warn).

         s% extras_startup => extras_startup
         s% extras_start_step => extras_start_step
         s% extras_check_model => extras_check_model
         s% extras_finish_step => extras_finish_step
         s% extras_after_evolve => extras_after_evolve
         s% how_many_extra_history_columns => how_many_extra_history_columns
         s% data_for_extra_history_columns => data_for_extra_history_columns
         s% how_many_extra_profile_columns => how_many_extra_profile_columns
         s% data_for_extra_profile_columns => data_for_extra_profile_columns

         s% how_many_extra_history_header_items => how_many_extra_history_header_items
         s% data_for_extra_history_header_items => data_for_extra_history_header_items
         s% how_many_extra_profile_header_items => how_many_extra_profile_header_items
         s% data_for_extra_profile_header_items => data_for_extra_profile_header_items

         ! Meshing is now defined in run_star_extras through hook
         call load_resolution_settings(ierr)
         if (ierr /= 0) return
         s% other_mesh_delta_coeff_factor => other_mesh_delta_coeff_factor

         ! Once you have set the function pointers you want,
         ! then uncomment this (or set it in your star_job inlist)
         ! to disable the printed warning message,
         s% job% warn_run_star_extras = .true.
      end subroutine extras_controls


      subroutine load_resolution_settings(ierr)
         integer, intent(out) :: ierr
         integer :: unit

         xtra_coef_os_full_on = 1d-4
         xtra_coef_os_full_off = 0.1d0
         xtra_coef_os_above_nonburn = 0.2d0
         xtra_coef_os_below_nonburn = 0.2d0
         xtra_coef_os_above_burn_h = 0.2d0
         xtra_coef_os_below_burn_h = 0.2d0
         xtra_coef_os_above_burn_he = 0.2d0
         xtra_coef_os_below_burn_he = 0.2d0
         xtra_coef_os_above_burn_z = 0.2d0
         xtra_coef_os_below_burn_z = 0.2d0
         xtra_dist_os_above_nonburn = 2.0d0
         xtra_dist_os_below_nonburn = 2.0d0
         xtra_dist_os_above_burn_h = 2.0d0
         xtra_dist_os_below_burn_h = 2.0d0
         xtra_dist_os_above_burn_he = 2.0d0
         xtra_dist_os_below_burn_he = 2.0d0
         xtra_dist_os_above_burn_z = 2.0d0
         xtra_dist_os_below_burn_z = 2.0d0

         if (ierr /= 0) then
            write(*, *) 'Failed to load resultion settings'
         end if
      end subroutine load_resolution_settings


      subroutine extras_startup(id, restart, ierr)
         integer, intent(in) :: id
         logical, intent(in) :: restart
         integer, intent(out) :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return

         ! Keep track of evolutionary stage
         ! Assume initial models are run from birth
         reached_zams = .false.
         h1_ign = .false.
         h1_dep = .false.
         shhb = .false.
         he4_ign = .false.
         he4_burn = .false.
         he4_dep = .false.
         is_bsg = .false.
         is_rsg = .false.
         blue_loop = .false.

         ! During evolution ask if these are reached, needed for different
         ! saving of profiles/gyre codes during.
         ask_reached_zams = .true.
         ask_h1_ign = .true.
         ask_h1_burn = .true.

         ! Start of shell burning
         ask_h1_dep = .true.

         ! Star of helium ignition an he_core burning
         ask_he_ign = .true.
         ask_he_burn = .true.

         ! End of core helium burning
         ask_he_dep = .true.

         ! Check if star doing blue loop
         ask_blue_loop = .true.

         call set_composition(id, s% initial_z  , ierr)
      end subroutine extras_startup


      integer function extras_start_step(id)
         integer, intent(in) :: id
         integer :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
         extras_start_step = 0
      end function extras_start_step


      ! returns either keep_going, retry, or terminate.
      integer function extras_check_model(id)
         integer, intent(in) :: id
         integer :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
         extras_check_model = keep_going
         if (.false. .and. s% star_mass_h1 < 0.35d0) then
            ! stop when star hydrogen mass drops to specified level
            extras_check_model = terminate
            write(*, *) 'have reached desired hydrogen mass'
            return
         end if


         ! if you want to check multiple conditions, it can be useful
         ! to set a different termination code depending on which
         ! condition was triggered.  MESA provides 9 customizeable
         ! termination codes, named t_xtra1 .. t_xtra9.  You can
         ! customize the messages that will be printed upon exit by
         ! setting the corresponding termination_code_str value.
         ! termination_code_str(t_xtra1) = 'my termination condition'

         ! by default, indicate where (in the code) MESA terminated
         if (extras_check_model == terminate) s% termination_code = t_extras_check_model
      end function extras_check_model


      integer function how_many_extra_history_columns(id)
         integer, intent(in) :: id
         integer :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
         how_many_extra_history_columns = 0
      end function how_many_extra_history_columns


      subroutine data_for_extra_history_columns(id, n, names, vals, ierr)
         integer, intent(in) :: id, n
         character (len=maxlen_history_column_name) :: names(n)
         real(dp) :: vals(n)
         integer, intent(out) :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return

         ! note: do NOT add the extras names to history_columns.list
         ! the history_columns.list is only for the built-in history column options.
         ! it must not include the new column names you are adding here.

      end subroutine data_for_extra_history_columns


      integer function how_many_extra_profile_columns(id)
         integer, intent(in) :: id
         integer :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
         how_many_extra_profile_columns = 0
      end function how_many_extra_profile_columns


      subroutine data_for_extra_profile_columns(id, n, nz, names, vals, ierr)
         integer, intent(in) :: id, n, nz
         character (len=maxlen_profile_column_name) :: names(n)
         real(dp) :: vals(nz,n)
         integer, intent(out) :: ierr
         type (star_info), pointer :: s
         integer :: k
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return

         ! note: do NOT add the extra names to profile_columns.list
         ! the profile_columns.list is only for the built-in profile column options.
         ! it must not include the new column names you are adding here.

      end subroutine data_for_extra_profile_columns


      integer function how_many_extra_history_header_items(id)
         integer, intent(in) :: id
         integer :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
         how_many_extra_history_header_items = 0
      end function how_many_extra_history_header_items


      subroutine data_for_extra_history_header_items(id, n, names, vals, ierr)
         integer, intent(in) :: id, n
         character (len=maxlen_history_column_name) :: names(n)
         real(dp) :: vals(n)
         type(star_info), pointer :: s
         integer, intent(out) :: ierr
         ierr = 0
         call star_ptr(id,s,ierr)
         if(ierr/=0) return

         ! here is an example for adding an extra history header item
         ! also set how_many_extra_history_header_items
         ! names(1) = 'mixing_length_alpha'
         ! vals(1) = s% mixing_length_alpha

      end subroutine data_for_extra_history_header_items


      integer function how_many_extra_profile_header_items(id)
         integer, intent(in) :: id
         integer :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
         how_many_extra_profile_header_items = 0
      end function how_many_extra_profile_header_items


      subroutine data_for_extra_profile_header_items(id, n, names, vals, ierr)
         integer, intent(in) :: id, n
         character (len=maxlen_profile_column_name) :: names(n)
         real(dp) :: vals(n)
         type(star_info), pointer :: s
         integer, intent(out) :: ierr
         ierr = 0
         call star_ptr(id,s,ierr)
         if(ierr/=0) return

         ! here is an example for adding an extra profile header item
         ! also set how_many_extra_profile_header_items
         ! names(1) = 'mixing_length_alpha'
         ! vals(1) = s% mixing_length_alpha

      end subroutine data_for_extra_profile_header_items


      ! returns either keep_going or terminate.
      ! note: cannot request retry; extras_check_model can do that.
      integer function extras_finish_step(id)
         integer, intent(in) :: id
         integer :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
         extras_finish_step = keep_going

         ! to save a profile,
            ! s% need_to_save_profiles_now = .true.
         ! to update the star log,
            ! s% need_to_update_history_now = .true.

         ! see extras_check_model for information about custom termination codes
         ! by default, indicate where (in the code) MESA terminated
         if (extras_finish_step == terminate) s% termination_code = t_extras_finish_step
      end function extras_finish_step


      subroutine extras_after_evolve(id, ierr)
         integer, intent(in) :: id
         integer, intent(out) :: ierr
         type (star_info), pointer :: s
         ierr = 0
         call star_ptr(id, s, ierr)
         if (ierr /= 0) return
      end subroutine extras_after_evolve



      ! Other mesh routine (copied from agb testsuite included with MESA v.12778)
      subroutine other_mesh_delta_coeff_factor(id, ierr)
         use const_def
         use chem_def
         integer, intent(in) :: id
         real(dp), allocatable, dimension(:) :: eps_h, eps_he, eps_z ! Mathijs : the subroutine no longer takes these as arguments, so I've manually defined them below
         integer, intent(out) :: ierr
         type (star_info), pointer :: s
         real(dp) :: he_cntr, full_off, full_on, alfa_os
         integer :: k, kk, nz, max_eps_loc
         real(dp) :: xtra_coef, xtra_dist, coef, Hp, r_extra, max_eps, eps
         logical :: in_convective_region
         logical, parameter :: dbg = .false.

         include 'formats'

         !write(*,*) 'enter other_mesh_delta_coeff_factor'
         ierr = 0
         if (xtra_coef_os_above_nonburn == 1d0 .and. &
             xtra_coef_os_below_nonburn == 1d0 .and. &
             xtra_coef_os_above_burn_h == 1d0 .and. &
             xtra_coef_os_below_burn_h == 1d0 .and. &
             xtra_coef_os_above_burn_he == 1d0 .and. &
             xtra_coef_os_below_burn_he == 1d0 .and. &
             xtra_coef_os_above_burn_z == 1d0 .and. &
             xtra_coef_os_below_burn_z == 1d0) return

         call star_ptr(id, s, ierr)
         if (ierr /= 0) return

         ! Only turn on once reached ZAMS
         if (.not.reached_zams) return

         !write(*,*) 'Turning additional meshing on, i.e. xtra_coef_os_above_burn_h:', xtra_coef_os_above_burn_h
         nz = s% nz
         he_cntr = s% xa(s% net_iso(ihe4),nz)
         full_off = xtra_coef_os_full_off
         full_on = xtra_coef_os_full_on
         if (he_cntr >= full_off) then
            alfa_os = 0
         else if (he_cntr <= full_on) then
            alfa_os = 1
         else
            alfa_os = (full_off - he_cntr)/(full_off - full_on)
         end if
         !write(*,1) 'alfa_os', alfa_os
         if (alfa_os == 0) return

         ! Mathijs : Manually defining eps_h, eps_he and eps_z
         allocate(eps_h(s% nz), eps_he(s% nz), eps_z(s% nz))
         do k=1,s% nz
            eps_h(k) = s% eps_nuc_categories(ipp,k) + s% eps_nuc_categories(icno,k)
            eps_he(k) = s% eps_nuc_categories(i3alf,k)
            eps_z(k) = s% eps_nuc(k) - (eps_h(k) + eps_he(k))
         end do

         ! first go from surface to center doing below convective boundaries
         in_convective_region = (s% mixing_type(1) == convective_mixing)
         k = 2
         max_eps = -1d99
         max_eps_loc = -1
         do while (k <= nz)
            eps = eps_h(k) + eps_he(k) + eps_z(k)
            if (in_convective_region) then
               if (s% mixing_type(k) == convective_mixing) then
                  if (eps > max_eps) then
                     max_eps = eps
                     max_eps_loc = k
                  end if
               else
                  in_convective_region = .false.
                  if (max_eps < 1d0) then
                     xtra_coef = xtra_coef_os_below_nonburn
                     xtra_dist = xtra_dist_os_below_nonburn
                  else if (eps_h(max_eps_loc) > 0.5d0*max_eps) then
                     xtra_coef = xtra_coef_os_below_burn_h
                     xtra_dist = xtra_dist_os_below_burn_h
                  else if (eps_he(max_eps_loc) > 0.5d0*max_eps) then
                     xtra_coef = xtra_coef_os_below_burn_he
                     xtra_dist = xtra_dist_os_below_burn_he
                  else
                     xtra_coef = xtra_coef_os_below_burn_z
                     xtra_dist = xtra_dist_os_below_burn_z
                  end if
                  xtra_coef = xtra_coef*alfa_os + (1-alfa_os)
                  if (xtra_coef > 0 .and. xtra_coef /= 1) then
                     coef = xtra_coef
                     do
                        if (s% mixing_type(k) /= overshoot_mixing) exit
                        if (coef < s% mesh_delta_coeff_factor(k)) then
                        !    if (dbg) write(*,2) 'mesh factor (before): ', &
                        !      k, s% mesh_delta_coeff_factor(k)
                            s% mesh_delta_coeff_factor(k) = coef
                        !    if (dbg) write(*,2) 'mesh factor (after)', &
                        !       k, s% mesh_delta_coeff_factor(k)
                        end if
                        if (k == nz) exit
                        k = k+1
                     end do
                     if (xtra_dist > 0) then
                        Hp = s% Peos(k)/(s% rho(k)*s% grav(k))
                        r_extra = max(0d0, s% r(k) - xtra_dist*Hp)
                        if (dbg) write(*,2) 'extra below overshoot region', &
                           k, s% r(k)/Rsun, Hp/Rsun, r_extra/Rsun
                        do
                           if (s% r(k) < r_extra) exit
                           if (coef < s% mesh_delta_coeff_factor(k)) then
                        !      if (dbg) write(*,2) 'mesh factor (before): ', &
                        !        k, s% mesh_delta_coeff_factor(k)
                              s% mesh_delta_coeff_factor(k) = coef
                        !      if (dbg) write(*,2) 'mesh factor (after)', &
                        !         k, s% mesh_delta_coeff_factor(k)
                           end if
                           if (k == nz) exit
                           k = k+1
                        end do
                     end if
                  end if
                  if (dbg) write(*,2) 'done with extra below overshoot region', k
                  if (dbg) write(*,*)
               end if
            else if (s% mixing_type(k) == convective_mixing) then
               in_convective_region = .true.
               max_eps = eps
               max_eps_loc = k
            end if
            k = k+1
         end do

         ! now go from center to surface doing above convective boundaries
         in_convective_region = (s% mixing_type(nz) == convective_mixing)
         k = nz-1
         max_eps = -1d99
         max_eps_loc = -1
         do while (k >= 1)
            eps = eps_h(k) + eps_he(k) + eps_z(k)
            if (in_convective_region) then
               if (s% mixing_type(k) == convective_mixing) then
                  if (eps > max_eps) then
                     max_eps = eps
                     max_eps_loc = k
                  end if
               else
                  in_convective_region = .false.
                  if (max_eps < 1d0) then
                     xtra_coef = xtra_coef_os_above_nonburn
                     xtra_dist = xtra_dist_os_above_nonburn
                  else if (eps_h(max_eps_loc) > 0.5d0*max_eps) then
                     xtra_coef = xtra_coef_os_above_burn_h
                     xtra_dist = xtra_dist_os_above_burn_h
                  else if (eps_he(max_eps_loc) > 0.5d0*max_eps) then
                     xtra_coef = xtra_coef_os_above_burn_he
                     xtra_dist = xtra_dist_os_above_burn_he
                  else
                     xtra_coef = xtra_coef_os_above_burn_z
                     xtra_dist = xtra_dist_os_above_burn_z
                  end if
                  xtra_coef = xtra_coef*alfa_os + (1-alfa_os)
                  if (dbg) write(*,2) 'xtra_coeff to surf', s% model_number, xtra_coef

                  if (xtra_coef > 0 .and. xtra_coef /= 1) then
                     coef = xtra_coef
                     do
                        if (s% mixing_type(k) /= overshoot_mixing) exit
                        if (coef < s% mesh_delta_coeff_factor(k)) then
                            !if (dbg) write(*,2) 'mesh factor (before): ', &
                            !  k, s% mesh_delta_coeff_factor(k)
                            s% mesh_delta_coeff_factor(k) = coef
                            !if (dbg) write(*,2) 'mesh factor (after)', &
                             !  k, s% mesh_delta_coeff_factor(k)
                        end if
                        if (k == 1) exit
                        k = k-1
                     end do
                     if (xtra_dist > 0) then
                        Hp = s% Peos(k)/(s% rho(k)*s% grav(k))
                        r_extra = min(s% r(1), s% r(k) + xtra_dist*Hp)
                        if (dbg) write(*,2) 'extra above overshoot region', &
                           k, s% r(k)/Rsun, Hp/Rsun, r_extra/Rsun
                        do
                           if (s% r(k) > r_extra) exit
                           if (coef < s% mesh_delta_coeff_factor(k)) then
                              ! if (dbg) write(*,2) 'mesh factor (before): ', &
                                ! k, s% mesh_delta_coeff_factor(k)
                               s% mesh_delta_coeff_factor(k) = coef
                               !if (dbg) write(*,2) 'mesh factor (after)', &
                                !  k, s% mesh_delta_coeff_factor(k)
                           end if
                           if (k == 1) exit
                           k = k-1
                        end do
                     end if
                  end if
                  if (dbg) write(*,2) 'done with extra above overshoot region', k
                  if (dbg) write(*,*)
               end if
            else if (s% mixing_type(k) == convective_mixing) then
               in_convective_region = .true.
               max_eps = eps
               max_eps_loc = k
            end if
            k = k-1
         end do

      end subroutine other_mesh_delta_coeff_factor


      ! Set the composition according to the
      subroutine set_composition(id, Z_ini, ierr)
        integer, intent(in) :: id
        real(dp),intent(in) :: Z_ini
        integer, intent(out) :: ierr
        type (star_info), pointer :: s
        real(dp), parameter :: ratio_h2_to_h1 = 2.7556428657d-5/7.0945477357d-1, &
                             ratio_he3_to_he4 = 8.4641515456d-5/2.7501644504d-1
        real(dp), parameter :: Yp = 0.2453d0, &
                            dY_dZ = 2.193d0
        real(dp) :: Y_ini, X_ini

        call star_ptr(id, s, ierr)
        if (ierr /= 0) return

        ! Set initial fractions according to Galactic enrichtment law
        ! Primordial helium abundance (Aver et al. 2021)
        ! Galactic enrichment ratio. Calibrated by requiring that for solar (Xini, Yini, Zini) = (0.710, 0.276, 0.014), NP+12
        Y_ini = Yp + dY_dZ*Z_ini
        X_ini = 1 - (Z_ini + Y_ini)

        s% initial_y = Y_ini
        s% initial_he3 = Y_ini * ratio_he3_to_he4

        ! What about these? MESA crashes if they are not set. But job and controls both have initial_he3.
        s% job% initial_h1  = X_ini * (1d0 - ratio_h2_to_h1)
        s% job% initial_h2  = X_ini * ratio_h2_to_h1
        s% job% initial_he3 = Y_ini * ratio_he3_to_he4
        s% job% initial_he4 = Y_ini * (1d0 - ratio_he3_to_he4)
        s% job% dump_missing_metals_into_heaviest = .false.
      end subroutine set_composition

      end module run_star_extras
