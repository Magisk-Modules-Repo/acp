#!/system/bin/sh
# Please don't hardcode /magisk/modname/... ; instead, please use $MODDIR/...
# This will make your scripts compatible even if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in late_start service mode
# More info in the main Magisk thread

/data/magisk/sepolicy-inject --live -s mediaserver -t mediaserver_tmpfs -c file -p read,write,execute
/data/magisk/sepolicy-inject --live -s audioserver -t audioserver_tmpfs -c file -p read,write,execute