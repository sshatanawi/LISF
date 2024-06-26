!-----------------------BEGIN NOTICE -- DO NOT EDIT-----------------------
! NASA Goddard Space Flight Center
! Land Information System Framework (LISF)
! Version 7.5
!
! Copyright (c) 2024 United States Government as represented by the
! Administrator of the National Aeronautics and Space Administration.
! All Rights Reserved.
!-------------------------END NOTICE -- DO NOT EDIT-----------------------
!BOP
! !ROUTINE: noahmp36_qc_snowobs
! \label{noahmp36_qc_snowobs}
!
! !REVISION HISTORY:
! 25Feb2008: Sujay Kumar: Initial Specification
!
! !INTERFACE:
subroutine noahmp36_qc_snowobs(n,k,OBS_State)
! !USES:
  use ESMF
  use LIS_coreMod
  use LIS_logMod,  only : LIS_verify
  use LIS_constantsMod, only : LIS_CONST_TKFRZ
  use LIS_DAobservationsMod
  use noahmp36_lsmMod

  implicit none
! !ARGUMENTS: 
  integer, intent(in)      :: n
  integer, intent(in)      :: k
  type(ESMF_State)         :: OBS_State
!
! !DESCRIPTION:
!
!  This subroutine performs any model-based QC of the observation 
!  prior to data assimilation. Here the snow observations
!  are flagged when LSM indicates that (1) rain is falling (2)
!  ground is fully or partially covered with snow. 
!  
!  The arguments are: 
!  \begin{description}
!  \item[n] index of the nest \newline
!  \item[OBS\_State] ESMF state container for observations \newline
!  \end{description}
!
!EOP
  type(ESMF_Field)         :: obs_snow_field

  real, pointer            :: snowobs(:)
  integer                  :: t
  integer                  :: gid
  integer                  :: status
  real                     :: stc1(LIS_rc%npatch(n,LIS_rc%lsm_index))
  real                     :: vegt(LIS_rc%npatch(n,LIS_rc%lsm_index))
  real                     :: fveg_obs(LIS_rc%obs_ngrid(k))
  real                     :: tv_obs(LIS_rc%obs_ngrid(k))
  real                     :: stc1_obs(LIS_rc%obs_ngrid(k))
  real                     :: vegt_obs(LIS_rc%obs_ngrid(k))

  call ESMF_StateGet(OBS_State,"Observation01",obs_snow_field,&
       rc=status)
  call LIS_verify(status,&
       "ESMF_StateGet failed in noahmp36_qc_soilmobs")
  call ESMF_FieldGet(obs_snow_field,localDE=0,farrayPtr=snowobs,rc=status)
  call LIS_verify(status,&
       "ESMF_FieldGet failed in noahmp36_qc_soilmobs")
  
  do t=1, LIS_rc%npatch(n,LIS_rc%lsm_index)

     stc1(t) = noahmp36_struc(n)%noahmp36(t)%sstc(1)
     vegt(t) = LIS_surface(n,1)%tile(t)%vegt
  enddo

  call LIS_convertPatchSpaceToObsSpace(n,k,&       
       LIS_rc%lsm_index, &
       noahmp36_struc(n)%noahmp36(:)%tv,&
       tv_obs)
  call LIS_convertPatchSpaceToObsSpace(n,k,&       
       LIS_rc%lsm_index, &
       noahmp36_struc(n)%noahmp36(:)%fveg,&
       fveg_obs)

  call LIS_convertPatchSpaceToObsSpace(n,k,&
       LIS_rc%lsm_index, &
       stc1,&
       stc1_obs)
  call LIS_convertPatchSpaceToObsSpace(n,k,&
       LIS_rc%lsm_index, &
       vegt,&
       vegt_obs)


  do t=1,LIS_rc%obs_ngrid(k)
     if(snowobs(t).ne.LIS_rc%udef) then 
        if(fveg_obs(t).gt.0.7) then 
           snowobs(t) = LIS_rc%udef        
        elseif(vegt_obs(t).le.4) then !forest types
           snowobs(t) = LIS_rc%udef
!assume that snow will not form at 5 deg. celcius or higher ground temp. 
       elseif(tv_obs(t).ge.278.15) then 
           snowobs(t) = LIS_rc%udef
       elseif(stc1_obs(t).ge.278.15) then 
           snowobs(t) = LIS_rc%udef
        endif
     endif
  enddo

end subroutine noahmp36_qc_snowobs

