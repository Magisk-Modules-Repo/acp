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
  rm /cache/$MODID.log
  rm -f /magisk/.core/post-fs-data.d/$MODID.sh
  #### ^ INSERT YOUR REMOVE PATCH OR RESTORE ^ ####
else
  # DETERMINE IF PIXEL (AB) DEVICE
  ABDeviceCheck=$(cat /proc/cmdline | grep slot_suffix | wc -l)
  if [ $ABDeviceCheck -gt 0 ]; then
    isABDevice=true
    SLOT=$(for i in `cat /proc/cmdline`; do echo $i | grep slot_suffix | awk -F "=" '{print $2}';done)
    SYSTEM=/system/system
    VENDOR=/vendor
  else
    isABDevice=false
    SYSTEM=/system
    VENDOR=$SYSTEM/VENDOR
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

  if [ -f "/data/magisk.img" ]; then
    SEINJECT=/data/magisk/sepolicy-inject
    SH=/magisk/.core/post-fs-data.d
  elif [ "$supersuimg" ] || [ -d /su ]; then
    SEINJECT=/su/bin/supolicy
    SH=/su.d
  elif [ -d $SYSTEM/su ] || [ -f $SYSTEM/xbin/daemonsu ] || [ -f $SYSTEM/xbin/su ] || [ -f $SYSTEM/xbin/sugote ]; then
    SEINJECT=$SYSTEM/xbin/supolicy
    SH=$SYSTEM/su.d
  elif [ -d $SYSTEM/etc/init.d ]; then
    SEINJECT=$SYSTEM/xbin/supolicy
    SH=$SYSTEM/etc/init.d
  fi
  
  if [ -d $SYSTEM/priv-app ]; then
    CONTEXT=priv_app
  else
    CONTEXT=system_app
  fi

  $SEINJECT --live "permissive $CONTEXT property_socket" \
  "permissive untrusted_app property_socket" \
  "allow audioserver audioserver_tmpfs file { read write execute }" \
  "allow audioserver system_file file { execmod }" \
  "allow mediaserver mediaserver_tmpfs file { read write execute }" \
  "allow mediaserver system_file file { execmod }" \
  "allow $CONTEXT init unix_stream_socket { connectto }" \
  "allow $CONTEXT property_socket sock_file { getattr open read write execute }" \
  "allow untrusted_app property_socket sock_file { getattr open read write execute }"

  LOG_FILE=/cache/$MODID.log
  if [ -e /cache/$MODID.log ]; then
    rm /cache/$MODID.log
  fi

  echo "$SH/$MODID$EXT has run successfully $(date +"%m-%d-%Y %H:%M:%S")" | tee -a $LOG_FILE;
fi