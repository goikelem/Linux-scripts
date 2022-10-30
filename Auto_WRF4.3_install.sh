#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
# The script executed in the root privilege 
# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to execute Auto_WRF4.3_install.sh"
    exit 1
fi
# the step by step manual guide is found in this link https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compilation_tutorial.php#STEP2 
# Install compilers and libraries.
sudo apt-get update
sudo apt-get install -y build-essential csh gfortran m4 curl csh gzip wget perl mpich libhdf5-mpich-dev libpng-dev netcdf-bin libnetcdff-dev

dir_path=$(pwd)
# The model installed in "/root/Build_WRF", path if you need to install in the home  "/home/user" path 
# install the compilers  and Libraries by copy line 12 and 13 to the terminal. And Exit the super user 
# comment line 2 to the line 13. 
Build_WRF=$dir_path/Build_WRF

mkdir -p $Build_WRF

echo "WRF will be compiled in $Build_WRF"


# TODO Check GCC version

mkdir -p $Build_WRF/test
cd $Build_WRF/test

# Test fortran compiler
if [ ! -f "Fortran_C_tests.tar" ]; then
wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/Fortran_C_tests.tar
tar -xf Fortran_C_tests.tar
fi

gfortran TEST_1_fortran_only_fixed.f
./a.out > a.out.log
if grep -q "SUCCESS" a.out.log
then
	echo "TEST_1_fortran_only_fixed.f test SUCCESS"
else
	echo "Error: test TEST_1_fortran_only_fixed.f!"
	exit 1
fi
rm -f a.out a.out.log

gfortran TEST_2_fortran_only_free.f90
./a.out > a.out.log
if grep -q "SUCCESS" a.out.log
then
        echo "TEST_2_fortran_only_free.f90 test SUCCESS"
else
        echo "Error: test TEST_2_fortran_only_free.f90!"
        exit 1
fi
rm -f a.out a.out.log

gcc TEST_3_c_only.c
./a.out > a.out.log
if grep -q "SUCCESS" a.out.log
then
        echo "TEST_3_c_only.c test SUCCESS"
else
        echo "Error: test TEST_3_c_only.c!"
        exit 1
fi
rm -f a.out a.out.log

gcc -c -m64 TEST_4_fortran+c_c.c
gfortran -c -m64 TEST_4_fortran+c_f.f90
gfortran -m64 TEST_4_fortran+c_f.o TEST_4_fortran+c_c.o
./a.out > a.out.log
if grep -q "SUCCESS" a.out.log
then
        echo "TEST_4_fortran+c_c.o test SUCCESS"
else
        echo "Error: TEST_4_fortran+c_c.o!"
        exit 1
fi
rm -f a.out a.out.log

./TEST_csh.csh > a.out.log
if grep -q "SUCCESS" a.out.log
then
        echo "TEST_csh.csh test SUCCESS"
else
        echo "Error: TEST_csh.csh!"
        exit 1
fi
rm -f a.out.log


./TEST_perl.pl > a.out.log
if grep -q "SUCCESS" a.out.log
then
        echo "TEST_perl.pl test SUCCESS"
else
        echo "Error: TEST_perl.pl!"
        exit 1
fi
rm -f a.out.log


./TEST_sh.sh > a.out.log
if grep -q "SUCCESS" a.out.log
then
        echo "TEST_sh.sh test SUCCESS"
else
        echo "Error: TEST_sh.sh!"
        exit 1
fi
rm -f a.out.log

echo "All Compile Tests Passwd!!!"

# Building Libraries
cd $Build_WRF

mkdir -p LIBRARIES
LIBRARIES_DIR=$Build_WRF/LIBRARIES
cd $LIBRARIES_DIR
## Downloads libraries
if [ ! -f "mpich-4.0.2.tar.gz" ]; then
wget https://src.fedoraproject.org/lookaside/pkgs/mpich/mpich-4.0.2.tar.gz
fi
if [ ! -f "netcdf-4.8.1.tar.gz" ]; then
wget https://src.fedoraproject.org/lookaside/pkgs/netcdf/netcdf-4.8.1.tar.gz
fi
if [ ! -f "jasper-3.0.5.tar.gz" ]; then
wget https://ftp.osuosl.org/pub/blfs/conglomeration/jasper/jasper-3.0.5.tar.gz
fi
if [ ! -f "libpng-1.6.37.tar.xz" ]; then
wget https://ftp.osuosl.org/pub/blfs/conglomeration/libpng/libpng-1.6.37.tar.xz
fi
if [ ! -f "zlib-1.2.12.tar.gz" ]; then
wget https://src.fedoraproject.org/repo/pkgs/zlib/zlib-1.2.12.tar.gz
fi

## install NetCDF
export DIR=$LIBRARIES_DIR
export CC=gcc
export CXX=g++
export FC=gfortran
export FCFLAGS=-m64
export F77=gfortran
export FFLAGS=-m64

tar zxvf netcdf-4.8.1.tar.gz
cd netcdf-4.8.1
./configure --prefix=$DIR/netcdf --disable-dap --disable-netcdf-4 --disable-shared
make
make install
export PATH=$DIR/netcdf/bin:$PATH
export NETCDF=$DIR/netcdf
cd ..

## install MPICH
tar xzvf mpich-4.0.2.tar.gz
cd mpich-4.0.2
./configure --prefix=$DIR/mpich
make
make install
export PATH=$DIR/mpich/bin:$PATH
cd ..

## install zlib
export LDFLAGS=-L$DIR/grib2/lib
export CPPFLAGS=-I$DIR/grib2/include
tar xzvf zlib-1.2.12.tar.gz
cd zlib-1.2.12
./configure --prefix=$DIR/grib2
make
make install
cd ..

## install libpng
tar xvf libpng-1.6.37.tar.xz
cd libpng-1.6.37
./configure --prefix=$DIR/grib2
make
make install
cd ..

## install JasPer
tar xzvf jasper-3.0.5.tar.gz
cd jasper-3.0.5
./configure --prefix=$DIR/grib2
make
make install
cd ..


# Library Compatibility Tests
cd $Build_WRF/test
if [ ! -f "Fortran_C_NETCDF_MPI_tests.tar" ]; then
wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/Fortran_C_NETCDF_MPI_tests.tar
fi
tar -xf Fortran_C_NETCDF_MPI_tests.tar
## Test Fortran + C + NetCDF
cp ${NETCDF}/include/netcdf.inc .
gfortran -c 01_fortran+c+netcdf_f.f
gcc -c 01_fortran+c+netcdf_c.c
gfortran 01_fortran+c+netcdf_f.o 01_fortran+c+netcdf_c.o -L${NETCDF}/lib -lnetcdff -lnetcdf
./a.out > a.out.log
if grep -q "SUCCESS" a.out.log
then
        echo "Fortran + C + NetCDF test SUCCESS"
else
        echo "Error: test Fortran + C + NetCDF!"
        exit 1
fi
rm -f a.out a.out.log

## Test Fortran + C + NetCDF + MPI
cp ${NETCDF}/include/netcdf.inc .
mpif90 -c 02_fortran+c+netcdf+mpi_f.f
mpicc -c 02_fortran+c+netcdf+mpi_c.c
mpif90 02_fortran+c+netcdf+mpi_f.o 02_fortran+c+netcdf+mpi_c.o -L${NETCDF}/lib -lnetcdff -lnetcdf
mpirun ./a.out > a.out.log
if grep -q "SUCCESS" a.out.log
then
        echo "Fortran + C + NetCDF + MPI test SUCCESS"
else
        echo "Error: test Fortran + C + NetCDF + MPI!"
        exit 1
fi
rm -f a.out a.out.log

# Building WRFV4

cd $Build_WRF
if [ ! -f "v4.3.3.tar.gz" ]; then
wget https://github.com/wrf-model/WRF/archive/v4.3.3.tar.gz
fi
mv v4.3.3.tar.gz WRFV4.3.3.tar.gz
tar -zxvf WRFV4.3.3.tar.gz
cd WRF-4.3.3
sed -i 's#  export USENETCDF=$USENETCDF.*#  export USENETCDF="-lnetcdf"#' configure
sed -i 's#  export USENETCDFF=$USENETCDFF.*#  export USENETCDFF="-lnetcdff"#' configure
cd arch
cp Config.pl Config.pl_backup
sed -i '420s/.*/  $response = 34 ;/' Config.pl
sed -i '695s/.*/  $response = 1 ;/' Config.pl
cd ..
./configure
gfortversion=$(gfortran -dumpversion | cut -c1)
if [ "$gfortversion" -lt 8 ] && [ "$gfortversion" -ge 6 ]; then
sed -i '/-DBUILD_RRTMG_FAST=1/d' configure.wrf
fi
./compile em_real > log.compile_wrf
ls -ls main/*.exe
if [ ! -f "main/wrf.exe" ]; then
	echo "WRF INSTALLED FAILURE."
	exit 1
else
	echo "WRF INSTALLED SUCCESS!"
fi

# Building WPS
cd $Build_WRF
if [ ! -f "v4.3.1.tar.gz" ]; then
wget https://github.com/wrf-model/WPS/archive/v4.3.1.tar.gz
fi
mv v4.3.1.tar.gz WPSV4.3.1.tar.gz
tar zxvf WPSV4.3.1.tar.gz
mv WPS-4.3.1 WPS
cd WPS
cd arch
cp Config.pl Config.pl_backup
sed -i '141s/.*/  $response = 3 ;/' Config.pl
cd ..
./clean
sed -i '133s/.*/    NETCDFF="-lnetcdff"/' configure
sed -i "165s/.*/standard_wrf_dirs=\"WRF-4.3.3 WRF WRF-4.0.3 WRF-4.0.2 WRF-4.0.1 WRF-4.0 WRFV3\"/" configure
./configure
logsave compile.log ./compile
sed -i "s# geog_data_path.*# geog_data_path = '../WPS_GEOG/'#" namelist.wps
cd arch
cp Config.pl_backup Config.pl
cd ..
cd ..
export JASPERLIB=$DIR/grib2/lib
export JASPERINC=$DIR/grib2/include
echo 1 | ./configure
./compile > log.compile
ls -ls *.exe
if [ ! -f "geogrid.exe" ]; then
	echo "WPS INSTALLED FAILURE."
	exit 1
else
	echo "WPS INSTALLED SUCCESS!"
fi

# Static Geography Data
cd $Build_WRF
if [ ! -f "geog_high_res_mandatory.tar.gz" ]; then
        wget http://www2.mmm.ucar.edu/wrf/src/wps_files/geog_high_res_mandatory.tar.gz
fi
        tar -zxvf geog_high_res_mandatory.tar.gz
        mv geog_high_res_mandatory WPS_GEOG
cd $Build_WRF/WPS
cp namelist.wps namelist.wps.bak
sed -i "s#/glade/p/work/wrfhelp#$Build_WRF#g" namelist.wps
# next is domain configuration
