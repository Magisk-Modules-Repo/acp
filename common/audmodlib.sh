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
  rm /cache/audmodlib_run.log
  #### ^ INSERT YOUR REMOVE PATCH OR RESTORE ^ ####

  rm -f /magisk/.core/post-fs-data.d/$MODID.sh
else
  SLOT=$(getprop ro.boot.slot_suffix 2>/tmp/null)
  if [ "$SLOT" ]; then
    SYSTEM=/system/system
  else
    SYSTEM=/system
  fi

  if [ ! -d "$SYSTEM/vendor" ] || [ -L "$SYSTEM/vendor" ]; then
    VENDOR=/vendor
  elif [ -d "$SYSTEM/vendor" ] || [ -L "/vendor" ]; then
    VENDOR=$SYSTEM/vendor
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
  elif [ "$supersuimg" ] || [ -d /su ]; then
    SEINJECT=/su/bin/supolicy
  elif [ -d $SYSTEM/su ] || [ -f $SYSTEM/xbin/daemonsu ] || [ -f $SYSTEM/xbin/su ] || [ -f $SYSTEM/xbin/sugote ]; then
    SEINJECT=$SYSTEM/xbin/supolicy
  elif [ -d $SYSTEM/etc/init.d ]; then
    SEINJECT=$SYSTEM/xbin/supolicy
  fi

  LOG_FILE=/cache/audmodlib_run.log;
  $SEINJECT --live "permissive priv_app audioserver" \
  "permissive system_app audioserver" \
  "permissive priv_app mediaserver" \
  "permissive system_app mediaserver" \
  "permissive priv_app property_socket" \
  "permissive system_app property_socket" \
  "allow audioserver audioserver_tmpfs file { open read write execute }" \
  "allow mediaserver mediaserver_tmpfs file { open read write execute }" \
  "allow priv_app init unix_stream_socket { connectto }" \
  "allow system_app init unix_stream_socket { connectto }" \
  "allow priv_app property_socket sock_file { getattr open read write execute }" \
  "allow system_app property_socket sock_file { getattr open read write execute }"
  
  if [ -e /cache/audmodlib_run.log ]; then
    rm /cache/audmodlib_run.log
  fi

  echo "post-fs-data(.d) audmodlib.sh has run successfully $(date +"%m-%d-%Y %H:%M:%S")" | tee -a $LOG_FILE;
fi