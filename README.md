# prtg-sensor-last-yum-update
PRTG Sensor - SSH Script - Yum update status - Days since last yum update

# How To Use?

## Install sensor on Linux server

1. Login to your Linux server
2. Create directory /var/prtg/scripts
3. Put sensor sh-script in this directory
4. Make executable chmod +x sh-script
5. Optional: Test it by executing the script

## Add sensor to PRTG

1. Login to your Paessler PRTG Network Monitor
2. Add your Linux server as new device if needed and setup "Credentials for Linux/Solaris/MAC OS (SSH/WBEM) Systems"
3. Click "Add Sensor"
4. Choose "SSH Script"
5. Choose the right sh-script in the dropdown box under Sensor Settings > Script
6. Optional: Set Warning or Error limit in days under "Edit Channel Settings" > "Enable Limits" > "Upper Warning Limit" AND "Upper Error Limit"
7. Ready!

# Known issues
There is a problem with yum-outstanding-security-updates-check.sh in that it won't work on CentOS. I'm currently reworking this to a new format to support CentOS but this will have a dependency of centos-package-cron (https://github.com/wied03/centos-package-cron)

# Compatibility
This sensor is tested with Linux Centos 6.x and 7.x
