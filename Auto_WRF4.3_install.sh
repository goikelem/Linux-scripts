
#!/bin/bash

# Set up environment paths
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

# Check if the script is being run as root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script."
    exit 1
fi

# Define working directory
dir_path=$(pwd)
Build_WRF=$dir_path/Build_WRF
mkdir -p $Build_WRF
echo "WRF will be compiled in $Build_WRF"

# Install necessary dependencies
apt-get update
apt-get install -y build-essential csh gfortran m4 curl csh gzip wget perl mpich libhdf5-mpich-dev libpng-dev netcdf-bin libnetcdff-dev || {
    echo "Error: Failed to install dependencies."
    exit 1
}

# Function to download a file with retry logic
download_file() {
    local url=$1
    local filename=$2
    local retries=3
    local count=0

    while [ $count -lt $retries ]; do
        wget $url -O $filename && return 0
        ((count++))
        echo "Download attempt $count failed, retrying..."
        sleep 5
    done
    echo "Error: Failed to download $filename after $retries attempts."
    exit 1
}

# Test the Fortran, C, and other compilers
mkdir -p $Build_WRF/test
cd $Build_WRF/test

# Download and run test files
download_file "https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/Fortran_C_tests.tar" "Fortran_C_tests.tar"
tar -xf Fortran_C_tests.tar

# Test Fortran and C compilers
for test_file in TEST_1_fortran_only_fixed.f TEST_2_fortran_only_free.f90 TEST_3_c_only.c TEST_4_fortran+c_c.c; do
    if ! gfortran $test_file || ! gcc $test_file; then
        echo "Error: $test_file compilation failed!"
        exit 1
    fi
    ./a.out > a.out.log
    if grep -q "SUCCESS" a.out.log; then
        echo "$test_file test SUCCESS"
    else
        echo "Error: $test_file test failed!"
        exit 1
    fi
    rm -f a.out a.out.log
done

# Test other scripts
for script in TEST_csh.csh TEST_perl.pl TEST_sh.sh; do
    ./$script > a.out.log
    if grep -q "SUCCESS" a.out.log; then
        echo "$script test SUCCESS"
    else
        echo "Error: $script test failed!"
        exit 1
    fi
    rm -f a.out.log
done

echo "All compile tests passed!"

# Build libraries (NetCDF, MPICH, zlib, libpng, jasper)
cd $Build_WRF

mkdir -p LIBRARIES
LIBRARIES_DIR=$Build_WRF/LIBRARIES
cd $LIBRARIES_DIR

# Download and install libraries
download_file "https://src.fedoraproject.org/lookaside/pkgs/mpich/mpich-4.0.2.tar.gz" "mpich-4.0.2.tar.gz"
download_file "https://src.fedoraproject.org/lookaside/pkgs/netcdf/netcdf-4.8.1.tar.gz" "netcdf-4.8.1.tar.gz"
download_file "https://ftp.osuosl.org/pub/blfs/conglomeration/jasper/jasper-3.0.5.tar.gz" "jasper-3.0.5.tar.gz"
download_file "https://ftp.osuosl.org/pub/blfs/conglomeration/libpng/libpng-1.6.37.tar.xz" "libpng-1.6.37.tar.xz"
download_file "https://src.fedoraproject.org/repo/pkgs/zlib/zlib-1.2.12.tar.gz" "zlib-1.2.12.tar.gz"

# Install NetCDF
export DIR=$LIBRARIES_DIR
export CC=gcc
export CXX=g++
export FC=gfortran
export FCFLAGS=-m64
export F77=gfortran
export FFLAGS=-m64

tar zxvf netcdf-4.8.1.tar.gz
cd netcdf-4.8.1
./configure --prefix=$DIR/netcdf --disable-dap --disable-netcdf-4 --disable-shared || { echo "Error: NetCDF configure failed"; exit 1; }
make || { echo "Error: NetCDF make failed"; exit 1; }
make install || { echo "Error: NetCDF make install failed"; exit 1; }
export PATH=$DIR/netcdf/bin:$PATH
export NETCDF=$DIR/netcdf
cd ..

# Install MPICH
tar xzvf mpich-4.0.2.tar.gz
cd mpich-4.0.2
./configure --prefix=$DIR/mpich || { echo "Error: MPICH configure failed"; exit 1; }
make || { echo "Error: MPICH make failed"; exit 1; }
make install || { echo "Error: MPICH make install failed"; exit 1; }
export PATH=$DIR/mpich/bin:$PATH
cd ..

# Install zlib
export LDFLAGS=-L$DIR/grib2/lib
export CPPFLAGS=-I$DIR/grib2/include
tar xzvf zlib-1.2.12.tar.gz
cd zlib-1.2.12
./configure --prefix=$DIR/grib2 || { echo "Error: zlib configure failed"; exit 1; }
make || { echo "Error: zlib make failed"; exit 1; }
make install || { echo "Error: zlib make install failed"; exit 1; }
cd ..

# Install libpng
tar xvf libpng-1.6.37.tar.xz
cd libpng-1.6.37
./configure --prefix=$DIR/grib2 || { echo "Error: libpng configure failed"; exit 1; }
make || { echo "Error: libpng make failed"; exit 1; }
make install || { echo "Error: libpng make install failed"; exit 1; }
cd ..

# Install JasPer
tar xzvf jasper-3.0.5.tar.gz
cd jasper-3.0.5
./configure --prefix=$DIR/grib2 || { echo "Error: JasPer configure failed"; exit 1; }
make || { echo "Error: JasPer make failed"; exit 1; }
make install || { echo "Error: JasPer make install failed"; exit 1; }
cd ..

echo "All libraries installed successfully."

# Build WRF
cd $Build_WRF
download_file "https://github.com/wrf-model/WRF/archive/v4.3.3.tar.gz" "WRFV4.3.3.tar.gz"
mv v4.3.3.tar.gz WRFV4.3.3.tar.gz
tar -zxvf WRFV4.3.3.tar.gz
cd WRF-4.3.3

# Configure WRF
sed -i 's#  export USENETCDF=$USENETCDF.*#  export USENETCDF="-lnetcdf"#' configure
sed -i 's#  export USENETCDFF=$USENETCDFF.*#  export USENETCDFF="-lnetcdff"#' configure

gfortran_version=$(gfortran -dumpversion | cut -d'.' -f1)
if [ "$gfortran_version" -lt 8 ] && [ "$gfortran_version" -ge 6 ]; then
    sed -i '/-DBUILD_RRTMG_FAST=1/d' configure.wrf
fi

./configure || { echo "WRF configure failed"; exit 1; }
./compile em_real > log.compile_wrf || { echo "WRF compile failed"; exit 1; }

if [ ! -f "main/wrf.exe" ]; then
    echo "Error: WRF compilation failed. wrf.exe not found"
    exit 1
else
    echo "WRF installed successfully!"
fi

# Build WPS
cd $Build_WRF
download_file "https://github.com/wrf-model/WPS/archive/v4.3.1.tar.gz" "WPSV4.3.1.tar.gz"
mv v4.3.1.tar.gz WPSV4.3.1.tar.gz
tar -zxvf WPSV4.3.1.tar.gz
mv WPS-4.3.1 WPS
cd WPS

# Configure and compile WPS
cd arch
cp Config.pl Config.pl_backup
sed -i '141s/.*/  $response = 3 ;/' Config.pl
cd ..
./clean
sed -i '133s/.*/    NETCDFF="-lnetcdff"/' configure
sed -i "165s/.*/standard_wrf_dirs=\"WRF-4.3.3 WRF WRF-4.0.3 WRF-4.0.2 WRF-4.0.1 WRF-4.0 WRFV3\"/" configure
./
