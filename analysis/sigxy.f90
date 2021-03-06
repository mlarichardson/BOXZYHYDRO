program sdxy
 implicit none

 integer,parameter::pre=8
 integer::nx=92,ny=80,nz=80,ix,iy,iz,idown,icheck=1234
 real(pre)::ds=0.02d0,dz=0.02d0

 character*72:: filename,input!="../celldump.00003750 "
 real(pre)::deltax,deltaz,h,lhex,dx,dy,xmin,xmax,ymin,ymax,zmin,zmax,pi,vol,dist,val,xx,yy,mass
 real(pre)::phase,area,val2,time
 real(pre),dimension(:),allocatable::x,y,z,rho,p,vx,vy,vz,phi,sort
 real(pre),dimension(:),allocatable::XIM,YIM,sig
 integer,dimension(:),allocatable::indx_sort,boundary
 real(pre),dimension(:,:),allocatable::image
 character junk

 type units
  real(pre)::length,time,mass,density
  real(pre)::rgas,eps,kelvin,vel
 end type

 integer::ioerr,ipix,jpix,nentry,ihead,iter,idx,ientry,isearch,ixs,jump,idx1
 integer::nentryxy,seed
 logical::binary=.false.
 
 type(units)::scl 

 xmax=45.
 xmin=-45.
 ymax=45.
 ymin=-45.
 

 pi=acos(-1d0)
 deltax=0.02
 deltaz=0.02
 area=1.5d0*deltax**2*tan(pi/6d0)
 vol=area*deltaz
 h=4*deltax

 call getarg(1,filename)
 idx1=iargc()
 if(idx1/=2)then
   print *,"Please give filename on command line and binary option [.true. or .false.]"
   stop
 endif
 call getarg(2,input)
 read(input,"(L)")binary

 if (binary)then

   open(unit=100,file=trim(filename),form="UNFORMATTED")
   read(100)ihead
   if (.not.ihead==icheck)then
     print *, "Corrupted file or wrong endian.  Header flag fail."
     stop
   endif
   read(100)time,ihead
   read(100)scl
   ioerr=0
   do while (ioerr>-1)
     read(100,iostat=ioerr)
     nentry=nentry+1
   enddo
   nentry=nentry-1
   print *, "#Found ",nentry," entries for step ",ihead
   print *, "#Scalings",scl
   rewind(100)
 else
   open(unit=100,file=trim(filename))
   ioerr=0
   ihead=1
   nentry=0
   do while (ioerr>-1)
     if(ihead<3)then
        read(100,"(A1)")junk
        ihead=ihead+1
     endif
     read(100,"(A1)",iostat=ioerr)
     nentry=nentry+1
   enddo
   nentry=nentry-1
   print *, "#Found ",nentry," entries and ", ihead, " header entries"
   rewind(100)
 endif
 
 allocate(x(nentry))
 allocate(sort(nentry))
 allocate(y(nentry))
 allocate(z(nentry))
 allocate(rho(nentry))
 allocate(p(nentry))
 allocate(vx(nentry))
 allocate(vy(nentry))
 allocate(vz(nentry))
 allocate(phi(nentry))
 allocate(boundary(nentry))
 allocate(indx_sort(nentry))

 if(nentry/=ny*nx*nz)then
   print *, 'ordering off. check dimensions and entry ',nx*ny*nz,nentry," diff ",nx*ny*nz-nentry
   stop
 endif
 
 if(binary)then
   read(100)ihead
   read(100)time,ihead
   read(100)scl
   xmin=0.;xmax=0.;ymin=0.;ymax=0.;zmin=0.;zmax=0.
   iter=0
   do iz=1,nz
   do ix=1,nx
   do iy=1,ny
     iter=iter+1
     read(100)x(iter),y(iter),z(iter),rho(iter),p(iter),&
        vx(iter),vy(iter),vz(iter),phi(iter),boundary(iter)
     indx_sort(iter)=iter
     sort(iter)=x(iter)
     if(xmax<x(iter))xmax=x(iter)
     if(xmin>x(iter))xmin=x(iter)
     if(ymax<y(iter))ymax=y(iter)
     if(ymin>y(iter))ymin=y(iter)
     if(zmax<z(iter))zmax=z(iter)
     if(zmin>z(iter))zmin=z(iter)
   enddo
   enddo
   enddo
 else
   do iter=1,ihead-1
     read(100,"(A1)")junk
   enddo
   xmin=0.;xmax=0.;ymin=0.;ymax=0.;zmin=0.;zmax=0.
   iter=0
   do iz=1,nz
   do ix=1,nx
   do iy=1,ny
     iter=iter+1
     read(100,"(9(1pe16.8e3,1X),I2)")x(iter),y(iter),z(iter),rho(iter),p(iter),&
        vx(iter),vy(iter),vz(iter),phi(iter),boundary(iter)
     indx_sort(iter)=iter
     sort(iter)=x(iter)
     if(xmax<x(iter))xmax=x(iter)
     if(xmin>x(iter))xmin=x(iter)
     if(ymax<y(iter))ymax=y(iter)
     if(ymin>y(iter))ymin=y(iter)
     if(zmax<z(iter))zmax=z(iter)
     if(zmin>z(iter))zmin=z(iter)
   enddo
   enddo
   enddo
 endif
 close(100)

 nentryxy=nentry/nz

 allocate(XIM(nx))
 allocate(YIM(ny))
 allocate(sig(nentryxy))
 allocate(image(nx,ny))

 dx=ds*cos(pi/6d0)
 dy=ds
 !dz=(zmax-zmin)/dble(nz)
 
 print *, '#nrntry, nentryxy, nx ny nz, nx ny, ', nentry, nentryxy, nx*ny*nz, nx*ny

 iter=0
 sig=0d0
! do idx=1,nz 
idx=nz/2
iter=(idx-1)*nx*ny
   print *, '# level  ',idx, ' clear.'
   do ixs=1,nentryxy
     iter=iter+1
     sig(ixs)=sig(ixs)+rho(iter)
   enddo
! enddo 

 print *,"#", xmin,xmax,ymin,ymax,zmin,zmax
 do iter=1,nx
  XIM(iter)=( dble(iter-1) *dx -(dble(nx)/2d0-0.5d0)*dx)
 enddo
 do iter=1,ny
  YIM(iter)=( dble(iter-1) *dy -(dble(ny)/2d0-0.5d0)*dy)
 enddo

 do ipix=1,nx
  do jpix=1,ny
    ientry=(ipix-1)*ny+jpix
    idown =(ipix-1)*ny+max(1,jpix-1)
    if(mod(ipix,2)==0)then
       val=sig(ientry)
       val2=sig(idown)
       val = val + (val2-val)*.5d0
    else
       val=sig(ientry)
    endif
    print *, XIM(ipix),YIM(jpix),val
 enddo
enddo
 
 deallocate(x,y,z,rho,p,vx,vy,vz,phi,boundary)

 contains

 real(pre) function kernel(d)
   implicit none
   real(pre)::q,d
   q=d/h
  if (q<1.)then
    kernel=1.+(-1.5*q+.75*q*q)*q
  else if (q<2.)then
    kernel=.25*(2.-q)**3
  else
    kernel=0.
  endif
  kernel=kernel*10./(7.*pi*h**2)
  return
 end function

end program

SUBROUTINE quick_sort(list, order, n)
  
  ! Quick sort routine from:
  ! Brainerd, W.S., Goldberg, C.H. & Adams, J.C. (1990) "Programmer's Guide to
  ! Fortran 90", McGraw-Hill  ISBN 0-07-000248-7, pages 149-150.
  ! Modified by Alan Miller to include an associated integer array which gives
  ! the positions of the elements in the original order.
  
  IMPLICIT NONE
  INTEGER :: n
  integer,parameter::pre=8
  REAL(pre), DIMENSION (1:n), INTENT(INOUT)  :: list
  INTEGER, DIMENSION (1:n), INTENT(OUT)  :: order
  
  ! Local variable
  INTEGER :: i
  
  DO i = 1, n
     order(i) = i
  END DO
  
  CALL quick_sort_1(1, n)
  
CONTAINS
  
  RECURSIVE SUBROUTINE quick_sort_1(left_end, right_end)
    
    INTEGER, INTENT(IN) :: left_end, right_end
    
    !     Local variables
    INTEGER             :: i, j, itemp
    REAL(pre)              :: reference, temp
    INTEGER, PARAMETER  :: max_simple_sort_size = 6
    
    IF (right_end < left_end + max_simple_sort_size) THEN
       ! Use interchange sort for small lists
       CALL interchange_sort(left_end, right_end)
       
    ELSE
       ! Use partition ("quick") sort
       reference = list((left_end + right_end)/2)
       i = left_end - 1; j = right_end + 1
       
       DO
          ! Scan list from left end until element >= reference is found
          DO
             i = i + 1
             IF (list(i) >= reference) EXIT
          END DO
          ! Scan list from right end until element <= reference is found
          DO
             j = j - 1
             IF (list(j) <= reference) EXIT
          END DO
          
          
          IF (i < j) THEN
             ! Swap two out-of-order elements
             temp = list(i); list(i) = list(j); list(j) = temp
             itemp = order(i); order(i) = order(j); order(j) = itemp
          ELSE IF (i == j) THEN
             i = i + 1
             EXIT
          ELSE
             EXIT
          END IF
       END DO
       
       IF (left_end < j) CALL quick_sort_1(left_end, j)
       IF (i < right_end) CALL quick_sort_1(i, right_end)
    END IF
    
  END SUBROUTINE quick_sort_1
  
  
  SUBROUTINE interchange_sort(left_end, right_end)
    
    INTEGER, INTENT(IN) :: left_end, right_end
    
    !     Local variables
    INTEGER             :: i, j, itemp
    REAL(pre)              :: temp
    
    DO i = left_end, right_end - 1
       DO j = i+1, right_end
          IF (list(i) > list(j)) THEN
             temp = list(i); list(i) = list(j); list(j) = temp
             itemp = order(i); order(i) = order(j); order(j) = itemp
          END IF
       END DO
    END DO
    
  END SUBROUTINE interchange_sort
  
END SUBROUTINE quick_sort

