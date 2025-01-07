#!/bin/bash
# Download and process NDVI Copernicus data

# Set the current year
DT=$(date +%Y)

# Base directory for data
BASE_DIR="/home/${USER}/DATA/NDVI"
COPERNICUS_URL="https://land.copernicus.vgt.vito.be/PDF/datapool/Vegetation/Indicators/NDVI_300m_V2"

# Loop through months and dekads (10-day periods)
for mm in {01..12}; do
  for DK in 10 20 29 28 30 31; do
    # Navigate to the base directory
    cd "${BASE_DIR}" || exit

    # Construct the download URL and destination directory
    DOWNLOAD_URL="${COPERNICUS_URL}/${DT}/${mm}/${DK}/?coord=22.50,-12.60,51.52,23.27"
    DEST_DIR="${BASE_DIR}/land.copernicus.vgt.vito.be/PDF/datapool/Vegetation/Indicators/NDVI_300m_V2/${DT}/${mm}/${DK}/NDVI300_${DT}${mm}${DK}0000_GLOBE_OLCI_V2.0.1"

    # Download data using wget
    wget -r --reject "index.html*" --user=goitomk --password="your_password" "${DOWNLOAD_URL}"

    # Change to the destination directory
    cd "${DEST_DIR}" || exit

    # Pause for 2 seconds
    sleep 2
  done
done

# Clean up unnecessary files
rm -rf "${BASE_DIR}/land.copernicus.vgt.vito.be/PDF/image"
rm -rf "${BASE_DIR}"/*.xml

# Process the data with cdo (adjust the file names and parameters as necessary)
cdo sellonlatbox,20,52,-12,24 "c_gls_NDVI300_202109110000_GLOBE_OLCI_V2.0.1.nc" "NDVI_${DT}${mm}${DK}_EA_OLCI.nc"
