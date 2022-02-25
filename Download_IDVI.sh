#!/bin/bash
# download NDVI copernicus data 
#
DT=`date +%Y`
for mm in {01..12..1}; do
for DK in 10, 20, 29, 28, 30, 31; do 
#
cd /home/${USER}/DATA/NDVI
#
wget -r --reject "index.html*" --user=goitomk --password="puthereyour password" https://land.copernicus.vgt.vito.be/PDF/datapool/Vegetation/Indicators/NDVI_300m_V2/${DT}/${mm}/${DK}/?coord=22.50,-12.60,51.52,23.27
# put your password with out double quotes  e.g password=password
cd /home/${USER}/DATA/NDVI/land.copernicus.vgt.vito.be/PDF/datapool/Vegetation/Indicators/NDVI_300m_V2/${DT}/${mm}/${DK}/NDVI300_${DT}${mm}${DK}0000_GLOBE_OLCI_V2.0.1
# 
sleep 2
done 
done 
rm -rf /home/${USER}/DATA/NDVI/land.copernicus.vgt.vito.be/PDF/image
# 
rm -rf *.xml
# rm -rf *.tiff 
# 
cdo sellonlatbox,20,52,-12,24 c_gls_NDVI300_202109110000_GLOBE_OLCI_V2.0.1.nc NDVI_${DT}${mm}${DK}_EA_OLCI.nc