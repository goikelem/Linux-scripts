#!/bin/bash

# Configuration (Customize these)
BASE_DIR="/home/goitomk"
WRF_VERSION="v4.5.1"  # Replace with desired version
WPS_VERSION="v4.5"      # Replace with desired version
NETCDF_VERSION_C="4.9.2"
NETCDF_VERSION_FORTRAN="4.6.1"
COMPILER_CHOICE=1 # 1 for gfortran, 2 for pgf90, 3 for ifort

# Derived variables (Do not modify)
WRF_BUILD="$BASE_DIR/WRF_Build"
WRF_DIR="$BASE_DIR/WRF"
WPS_DIR="$BASE_DIR/WPS"
LIBRARIES="$BASE_DIR/LIBRARIES"
GEOG_DATA_DIR="$WRF_BUILD/geo_em.d01"
NETCDF_C_DIR="$WRF_BUILD/netcdf-c-$NETCDF_VERSION_C"
NETCDF_FORTRAN_DIR="$WRF_BUILD/netcdf-fortran-$NETCDF_VERSION_FORTRAN"

# Functions for better organization and error handling
download_and_extract() {
  local url="$1"
  local filename="$2"
  local extract_dir="$3"
  if [ ! -d "$extract_dir" ]; then
    wget "$url" -O "$filename"
    tar -xzf "$filename"
    rm "$filename"
  fi
}

compile_code() {
  local source_dir="$1"
  local compile_log="$2"
  make clean # Clean before compiling
  make >& "$compile_log"
  if [[ $? -ne 0 ]]; then
    echo "Compilation failed in $source_dir. Check $compile_log"
    exit 1
  fi
}

configure_code() {
    local source_dir="$1"
    ./configure
    if [[ $? -ne 0 ]]; then
        echo "Configuration failed in $source_dir"
        exit 1
    fi
}

# Create directories
mkdir -p "$WRF_BUILD" "$WRF_DIR" "$WPS_DIR" "$LIBRARIES"

# Install system dependencies (Ubuntu/Debian example)
sudo apt-get update
sudo apt-get install -y build-essential gfortran gcc g++ libpng-dev libjpeg-dev zlib1g-dev bison flex libnetcdf-dev libnetcdff-dev libmpich-dev libjasper-dev libhdf5-dev

# Download source code
cd "$WRF_BUILD"

download_and_extract "https://github.com/wrf-model/WRF/archive/refs/tags/$WRF_VERSION.tar.gz" "WRF.tar.gz" "WRF"
download_and_extract "https://github.com/wrf-model/WPS/archive/refs/tags/$WPS_VERSION.tar.gz" "WPS.tar.gz" "WPS"

# Download and extract geographical data
download_and_extract "http://www2.mmm.ucar.edu/wrf/users/download/geo_em.d01.tar.gz" "geo_em.d01.tar.gz" "$GEOG_DATA_DIR"

#Download NetCDF source and compile if the LIBRARIES directory is empty
if [ ! -d "$LIBRARIES/lib" ] || [ ! -d "$LIBRARIES/include" ]; then
    download_and_extract "https://downloads.unidata.ucar.edu/netcdf/netcdf-c-$NETCDF_VERSION_C.tar.gz" "netcdf-c.tar.gz" "$NETCDF_C_DIR"
    download_and_extract "https://downloads.unidata.ucar.edu/netcdf/netcdf-fortran-$NETCDF_VERSION_FORTRAN.tar.gz" "netcdf-fortran.tar.gz" "$NETCDF_FORTRAN_DIR"
    cd "$NETCDF_C_DIR"
    ./configure --prefix="$LIBRARIES"
    compile_code "$NETCDF_C_DIR" "compile_netcdf_c.log"
    cd "$NETCDF_FORTRAN_DIR"
    ./configure --prefix="$LIBRARIES" --enable-netcdf-4 --with-netcdf="$LIBRARIES"
    compile_code "$NETCDF_FORTRAN_DIR" "compile_netcdf_fortran.log"
fi

# Set environment variables (add to .bashrc and source it)
echo "export NETCDF=$LIBRARIES" >> ~/.bashrc
echo "export PATH=\$PATH:$WRF_DIR/external/io_grib1" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$LIBRARIES/lib" >> ~/.bashrc
echo "export WRF_DIR=$WRF_DIR" >> ~/.bashrc
echo "export WPS_DIR=$WPS_DIR" >> ~/.bashrc
source ~/.bashrc

# Compile WRF
cd "$WRF_DIR"
if [ ! -f "main/wrf.exe" ]; then
    configure_code "$WRF_DIR"
    # Choose your compiler option interactively
    sed -i "s/DM_FC = -DFSEEKO_OK -DDM_PARALLEL/DM_FC = -DDM_PARALLEL/" configure.wrf
    ./compile em_real >& compile_wrf.log
    if [[ $? -ne 0 ]]; then
        echo "WRF compilation failed. Check compile_wrf.log"
        exit 1
    fi
fi

# Compile WPS
cd "$WPS_DIR"
if [ ! -f "geogrid.exe" ]; then
    configure_code "$WPS_DIR"
    compile_code "$WPS_DIR" "compile_wps.log"
    if [[ $? -ne 0 ]]; then
        echo "WPS compilation failed. Check compile_wps.log"
        exit 1
    fi
fi

# Configure namelist.wps
if ! grep -q "geog_data_path = '$GEOG_DATA_DIR'" "$WPS_DIR/namelist.wps"; then
    sed -i "s/geog_data_path.*=.*/geog_data_path = '$GEOG_DATA_DIR'/" "$WPS_DIR/namelist.wps"
fi

echo "WRF and WPS setup complete."