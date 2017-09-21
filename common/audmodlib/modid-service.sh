#!/system/bin/sh
# This script will be executed in late_start service mode
# More info in the main Magisk thread
SH=${0%/*}
MODID=<MODID>

# DETERMINE IF PIXEL (A/B OTA) DEVICE
ABDeviceCheck=$(cat /proc/cmdline | grep slot_suffix | wc -l)
if [ "$ABDeviceCheck" -gt 0 ]; then
  isABDevice=true
  if [ -d "/system_root" ]; then
	SYS=/system_root/system
  else
	SYS=/system/system
  fi
else
  isABDevice=false
  SYS=/system
fi

if [ $isABDevice == true ] || [ ! -d "$SYS/vendor" ]; then
  VEN=/vendor
else
  VEN=$SYS/vendor
fi

test -d /magisk/audmodlib$SYS && { MAGISK=true; AMLPATH=/magisk/audmodlib; } || { MAGISK=false; AMLPATH=""; }

# CUSTOM USER SCRIPT
