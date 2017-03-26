#!/system/bin/sh
# This script will be executed in post-fs-data mode
# More info in the main Magisk thread

#### v INSERT YOUR CONFIG.SH MODID v ####
MODID=audmodlib
#### ^ INSERT YOUR CONFIG.SH MODID ^ ####

########## v DO NOT REMOVE v ##########
rm -rf /cache/magisk/audmodlib

if [ ! -d /magisk/$MODID ]; then
  ########## ^ DO NOT REMOVE ^ ##########

  #### v INSERT YOUR REMOVE PATCH OR RESTORE v ####
  #### ^ INSERT YOUR REMOVE PATCH OR RESTORE ^ ####

  rm -f /magisk/.core/post-fs-data.d/$MODID.sh
fi
