#!/system/bin/sh
# This script will be executed in late_start service mode
# More info in the main Magisk thread

#### v INSERT YOUR CONFIG.SH MODID v ####
MODID=audmodlib
#### ^ INSERT YOUR CONFIG.SH MODID ^ ####

########## v DO NOT REMOVE v ##########
rm -rf /cache/magisk/audmodlib

if [ ! -d /magisk/$MODID ]; then
  ########## ^ DO NOT REMOVE ^ ##########

  #### v INSERT YOUR REMOVE PATCH OR RESTORE v ####
  rm /cache/$MODID-service.log
  rm -f /magisk/.core/service.d/$MODID.sh
  #### ^ INSERT YOUR REMOVE PATCH OR RESTORE ^ ####
else
  # DETERMINE IF PIXEL (A/B OTA) DEVICE
  ABDeviceCheck=$(cat /proc/cmdline | grep slot_suffix | wc -l)
  if [ "$ABDeviceCheck" -gt 0 ]; then
    isABDevice=true
    SYSTEM=/system/system
    VENDOR=/vendor
  else
    isABDevice=false
    SYSTEM=/system
    VENDOR=/system/vendor
  fi

  supersuimg=$(ls /cache/su.img /data/su.img 2>/dev/null);

  supersu_is_mounted() {
    case `mount` in
      *" $1 "*) echo 1;;
      *) echo 0;;
    esac;
  }

  if [ "$supersuimg" ]; then
    if [ "$(supersu_is_mounted /su)" == 0 ]; then
      test ! -e /su && mkdir /su;
      mount -t ext4 -o rw,noatime $supersuimg /su 2>/dev/null
      for i in 0 1 2 3 4 5 6 7; do
        test "$(supersu_is_mounted /su)" == 1 && break;
        loop=/dev/block/loop$i;
        mknod $loop b 7 $i;
        losetup $loop $supersuimg;
        mount -t ext4 -o loop $loop /su; 2>/dev/null
      done;
    fi;
  fi;

  # DETERMINE ROOT BOOT SCRIPT TYPE
  EXT=".sh"
  if [ -f /data/magisk.img ] || [ -d /magisk ]; then
    MAGISK=true
    SEINJECT=/data/magisk/sepolicy-inject
    SH=/magisk/.core/service.d
  elif [ "$supersuimg" ] || [ -d /su ]; then
    SEINJECT=/su/bin/supolicy
    SH=/su/su.d
  elif [ -d $SYSTEM/su ] || [ -f $SYSTEM/xbin/daemonsu ] || [ -f $SYSTEM/xbin/su ] || [ -f $SYSTEM/xbin/sugote ]; then
    SEINJECT=$SYSTEM/xbin/supolicy
    SH=$SYSTEM/su.d
  elif [ -d $SYSTEM/etc/init.d ]; then
    SEINJECT=$SYSTEM/xbin/supolicy
    SH=$SYSTEM/etc/init.d
    EXT=""
  fi
  
  if [ -d $SYSTEM/priv-app ]; then
    SOURCE=priv_app
  else
    SOURCE=system_app
  fi

  $SEINJECT --live "permissive $SOURCE audio_prop"

  LOG_FILE=/cache/$MODID-service.log
  if [ -e /cache/$MODID-service.log ]; then
    rm /cache/$MODID-service.log
  fi

  echo "$SH/$MODID-service$EXT has run successfully $(date +"%m-%d-%Y %H:%M:%S")" | tee -a $LOG_FILE;
fi