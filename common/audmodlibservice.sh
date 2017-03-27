#!/system/bin/sh
# Please don't hardcode /magisk/modname/... ; instead, please use $MODDIR/...
# This will make your scripts compatible even if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in late_start service mode
# More info in the main Magisk thread

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

$SEINJECT --live "allow mediaserver mediaserver_tmpfs file { read write execute }" \
"allow audioserver audioserver_tmpfs file { read write execute }"
