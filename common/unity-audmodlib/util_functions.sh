##########################################################################################
#
# General Utility Functions
# Based on util_functions script v1456 by topjohnwu
# Modified by ahrion and zackptg5
#
##########################################################################################

resolve_link() {
  RESOLVED="$1"
  while RESOLVE=`readlink $RESOLVED`; do
    RESOLVED=$RESOLVE
  done
  echo $RESOLVED
}
 
is_mounted() {
  TARGET="`resolve_link $1`"
  cat /proc/mounts | grep " $TARGET " >/dev/null
  return $?
}

mount_partitions_system() {
  # Check A/B slot
  SLOT=`getprop ro.boot.slot_suffix`
  if [ -z $SLOT ]; then
    SLOT=_`getprop ro.boot.slot`
    [ $SLOT = "_" ] && SLOT=
  fi
  [ -z $SLOT ] || ui_print "- A/B partition detected, current slot: $SLOT"
  ui_print "- Mounting /system, /vendor"
  REALSYS=/system
  is_mounted /system || [ -f /system/build.prop ] || mount -o rw /system 2>/dev/null
  if ! is_mounted /system && ! [ -f /system/build.prop ]; then
    SYSTEMBLOCK=`find /dev/block -iname system$SLOT | head -n 1`
    mount -t ext4 -o rw $SYSTEMBLOCK /system
	REALSYS=/system/system
  fi
  is_mounted /system || [ -f /system/build.prop ] || abort "! Cannot mount /system"
  cat /proc/mounts | grep -E '/dev/root|/system_root' >/dev/null && SKIP_INITRAMFS=true || SKIP_INITRAMFS=false
  if [ -f /system/init.rc ]; then
    SKIP_INITRAMFS=true
    mkdir /system_root 2>/dev/null
    mount --move /system /system_root
    mount -o bind /system_root/system /system
	ROOT=/system_root
	REALSYS=/system_root/system
  fi
  $SKIP_INITRAMFS && ui_print "- Device skip_initramfs detected"
  if [ -L /system/vendor ]; then
    # Seperate /vendor partition
    VEN=/vendor
    is_mounted /vendor || mount -o rw /vendor 2>/dev/null
    if ! is_mounted /vendor; then
      VENDORBLOCK=`find /dev/block -iname vendor$SLOT | head -n 1`
      mount -t ext4 -o rw $VENDORBLOCK /vendor
    fi
    is_mounted /vendor || abort "! Cannot mount /vendor"
  else
    VEN=/system/vendor
  fi
}

grep_prop() {
  REGEX="s/^$1=//p"
  shift
  FILES=$@
  [ -z "$FILES" ] && FILES='/system/build.prop'
  sed -n "$REGEX" $FILES 2>/dev/null | head -n 1
}

api_level_arch_detect_mod() {
  API=`grep_prop ro.build.version.sdk`
  ABI=`grep_prop ro.product.cpu.abi | cut -c-3`
  ABI2=`grep_prop ro.product.cpu.abi2 | cut -c-3`
  ABILONG=`grep_prop ro.product.cpu.abi`
  MIUIVER=`grep_prop ro.miui.ui.version.name`
  ARCH=arm
  DRVARCH=NEON
  IS64BIT=false
  if [ "$ABI" = "x86" ]; then ARCH=x86; DRVARCH=X86; fi;
  if [ "$ABI2" = "x86" ]; then ARCH=x86; DRVARCH=X86; fi;
  if [ "$ABILONG" = "arm64-v8a" ]; then ARCH=arm64; IS64BIT=true; fi;
  if [ "$ABILONG" = "x86_64" ]; then ARCH=x64; IS64BIT=true; DRVARCH=X86; fi;
}

set_perm() {
  chown $2:$3 $1 || exit 1
  chmod $4 $1 || exit 1
  [ -z $5 ] && chcon 'u:object_r:system_file:s0' $1 || chcon $5 $1
}

set_perm_recursive() {
  find $1 -type d 2>/dev/null | while read dir; do
    set_perm $dir $2 $3 $4 $6
  done
  find $1 -type f -o -type l 2>/dev/null | while read file; do
    set_perm $file $2 $3 $5 $6
  done
}

mktouch() {
  mkdir -p ${1%/*} 2>/dev/null
  [ -z $2 ] && touch $1 || echo $2 > $1
  chmod 644 $1
}

supersuimg_mount() {
  supersuimg=$(ls /cache/su.img /data/su.img 2>/dev/null)
  if [ "$supersuimg" ]; then
    if ! is_mounted /su; then
      ui_print "   Mounting /su..."
      test ! -e /su && mkdir /su
      mount -t ext4 -o rw,noatime $supersuimg /su 2>/dev/null
      for i in 0 1 2 3 4 5 6 7; do
        is_mounted /su && break
        loop=/dev/block/loop$i
        mknod $loop b 7 $i
        losetup $loop $supersuimg
        mount -t ext4 -o loop $loop /su 2>/dev/null
      done
    fi
  fi
}

require_new_magisk() {
  ui_print "***********************************"
  ui_print "! $MAGISKBIN isn't setup properly!"
  ui_print "!  Please install Magisk v14.0+!"
  ui_print "***********************************"
  exit 1
}

require_new_api() {
  ui_print "***********************************"
  ui_print "!   Your system API of $API doesn't"
  ui_print "!    meet the $1 API of $MINAPI"
  if [ "$1" == "minimum" ]; then
    ui_print "! Please upgrade to a newer version"
    ui_print "!  of android with at least API $MINAPI"
  else
    ui_print "! Please downgrade to an older version"
    ui_print "!  of android with at most API $MINAPI"
  fi
  ui_print "***********************************"
  exit 1
}

action_complete() {
  if [ "$MAGISK" == false ]; then
    ui_print "   Unmounting partitions..."
    test "$supersuimg" -o -d /su && umount /su
	umount -l /system_root 2>/dev/null
    umount -l /system 2>/dev/null
    umount -l /vendor 2>/dev/null
  fi
  ui_print " "
  test "$ACTION" == "Install" && ui_print "    --------- INSTALLATION SUCCESSFUL ---------" || ui_print "    --------- RESTORATION SUCCESSFUL ---------"
  ui_print " "
  test "$ACTION" == "Install" && ui_print "    Unity Installer by ahrion & zackptg5 @ XDA" || ui_print "    Unity Uninstaller by ahrion & zackptg5 @ XDA"
}

sys_wipe_ch() {
  TPARTMOD=false
  cat $INFO | {
  while read LINE; do
    test "$1" == "$(eval echo $LINE)" && { TPARTMOD=true; sed -i "/$1/d" $INFO; }
  done
  if [ -f "$1" ] && [ ! -f "$1.bak" ] && [ "$TPARTMOD" != true ]; then
    mv -f "$1" "$1.bak"
    echo "$1.bak" >> $INFO
  else
    rm -f "$1"
  fi
  }
}

sys_wipefol_ch() {
  if [ -d "$1" ] && [ ! -f "$1.tar" ]; then
    tar -cf "$1.tar" "$1"
    test ! -f $INFO && echo "$1.tar" >> $INFO || { test ! "$(grep "$1.tar" $INFO)" && echo "$1.tar" >> $INFO; }
  else
    rm -rf "$1"
  fi
}

wipe_ch() {
  case $1 in
    FOL*) test "$(echo "$1" | cut -c 4-9)" == "/data/" && TYPE="foldata" || TYPE="fol"; FILE=$(echo "$1" | cut -c4-);;
    /data/*) TYPE="data"; FILE=$1;;
    APP*) TYPE="app"; FILE=$(echo "$1" | cut -c4-);;
    *) TYPE="file"; FILE=$1;;
  esac
  case $TYPE in
    "foldata") sys_wipefol_ch $FILE;;
    "fol") test "$MAGISK" == true && mktouch $FILE/.replace || sys_wipefol_ch $FILE;;
    "data") sys_wipe_ch $FILE;;
    "app") if $OLDAPP; then
             test -f "/system/app/$FILE.apk" && $WPAPP_PRFX $UNITY/system/app/$FILE.apk || { test -f "/system/app/$FILE/$FILE.apk" && $WPAPP_PRFX $UNITY/system/app/$FILE/$FILE.apk; }
           else
             test -f "/system/priv-app/$FILE/$FILE.apk" && $WPAPP_PRFX $UNITY/system/priv-app/$FILE/$FILE.apk
           fi;;
    "file") test "$MAGISK" == true && mktouch $FILE || sys_wipe_ch $FILE;;
  esac
}

cp_ch() {
  mkdir -p "${2%/*}"
  chmod 0755 "${2%/*}"
  cp -af "$1" "$2"
  test -z $3 && chmod 0644 "$2" || chmod "$3" "$2"
}

sys_cp_ch() {
  if [ -f "$2" ] && [ ! -f "$2.bak" ]; then
    cp -f "$2" "$2.bak"
    echo "$2.bak" >> $INFO
  fi
  test ! "$(grep "$2" $INFO)" && echo "$2" >> $INFO
  cp_ch $1 $2 $3
}

sys_rm_ch() {
  if [ -f "$1.bak" ]; then
    mv -f "$1.bak" "$1"
  elif [ -f "$1.tar" ]; then
    tar -xf "$1.tar" -C "${1%/*}"
  else
    rm -f "$1"
  fi
  if [ ! "$(ls -A "${1%/*}")" ]; then
    rm -rf ${1%/*}
  fi
}

patch_script() {
  sed -i "s|<MAGISK>|$MAGISK|" $1
  sed -i "s|<VEN>|$VEN|" $1
  sed -i "s|<SYS>|$REALSYS|" $1
  test ! -z $ROOT && sed -i "s|<ROOT>|$ROOT|" $1 || sed -i "/<ROOT>/d" $1
  test ! -z $XML_PATH && sed -i "s|<XML_PRFX>|$XML_PATH|" $1 || sed -i "/<XML_PRFX>/d" $1
  if [ "$MAGISK" == false ]; then
    sed -i "s|<SHEBANG>|$SHEBANG|" $1
	sed -i "s|<SEINJECT>|$SEINJECT|" $1
	sed -i "/<AMLPATH>/d" $1
	sed -i "s|$MOUNTPATH||g" $1
  else
    sed -i "s|<SHEBANG>|#!/system/bin/sh|" $1
	sed -i "s|<SEINJECT>|magiskpolicy|" $1
	sed -i "s|<AMLPATH>|$AMLPATH|" $1
	sed -i "s|$MOUNTPATH|$BOOTPATH|g" $1
  fi
}

add_to_info() {
  test ! "$(grep "$1" $2)" && echo "$1" >> $2
}

custom_app_install() {
  $OLDAPP && $CP_PRFX $INSTALLER/custom/$1/$1.apk $UNITY/system/app/$1.apk || $CP_PRFX $INSTALLER/custom/$1/$1.apk $UNITY/system/priv-app/$1/$1.apk
}

info_uninstall() {
  if [ -f $1 ]; then
    test "$1" != "$AMLINFO" && ui_print "   Removing/restoring files..."
    cat $1 | while read LINE; do
      sys_rm_ch $LINE
    done
    rm -f $1
  else
    test "$MAGISK" == false && ui_print "   ! Mod not detected. Removing scripts..." || ui_print "   Removing/restoring files..."
  fi
}

remove_aml() {
  ui_print " "
  ui_print "   ! No more audmodlib modules detected !"
  ui_print "   ! Removing Audio Modification Library !"
  test "$MAGISK" == true && { rm -rf $AMLPATH; rm -rf $BOOTPATH/audmodlib; } || { info_uninstall $AMLINFO; rm -f /system/addon.d/audmodlib.sh; }
}
