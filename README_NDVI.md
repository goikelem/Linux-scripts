# Linux-scripts
 
**this Linux bash script is used to download NDVI data** 

## to run the command on the linux terminal:
`./NDVI_bash.sh`
the other way is 
```bash
./NDVI_bsh.sh```


# NDVI Data Download and Processing Script

This script automates the process of downloading NDVI data from the Copernicus Land Monitoring Service and processes it using the Climate Data Operators (CDO) tool.

## Prerequisites

- **wget**: Command-line tool for downloading files from the web.
- **cdo**: Climate Data Operators, a tool for manipulating and analyzing climate data.
- **Bash**: The script is written in Bash, so it requires a Unix-like environment (Linux, macOS).

## Usage

1. **Clone or Copy the Script**:
   - Save the script as `download_ndvi.sh` in your preferred directory.

2. **Modify the Script**:
   - Replace `your_password` in the `wget` command with your actual password for the Copernicus data portal.
   - Ensure the directories in the script (`BASE_DIR` and others) are set according to your local environment.

3. **Run the Script**:
   ```bash
   bash download_ndvi.sh
