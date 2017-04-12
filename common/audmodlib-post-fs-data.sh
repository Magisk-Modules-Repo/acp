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
  rm /cache/$MODID-post-fs-data.log
  rm -f /magisk/.core/post-fs-data.d/$MODID.sh
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
    SH=/magisk/.core/post-fs-data.d
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

  $SEINJECT --live "allow audioserver audioserver_tmpfs file { read write execute }" \
  "allow audioserver system_file file { execmod }" \
  "allow mediaserver mediaserver_tmpfs file { read write execute }" \
  "allow mediaserver system_file file { execmod }" \
  "allow $SOURCE init unix_stream_socket { connectto }" \
  "allow $SOURCE property_socket sock_file { getattr open read write execute }"

  if [ ! $MAGISK == true ]; then
    $SEINJECT --live "permissive $SOURCE property_socket"
  fi

  LOG_FILE=/cache/$MODID-post-fs-data.log
  if [ -e /cache/$MODID-post-fs-data.log ]; then
    rm /cache/$MODID-post-fs-data.log
  fi

  echo "$SH/$MODID-post-fs-data$EXT has run successfully $(date +"%m-%d-%Y %H:%M:%S")" | tee -a $LOG_FILE;
fi