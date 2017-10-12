##########################################################################################
#
# Magisk General Utility Functions
# by topjohnwu
#
# Used everywhere in Magisk
#
##########################################################################################

MAGISK_VER="14.2"
MAGISK_VER_CODE=1420
SCRIPT_VERSION=$MAGISK_VER_CODE

get_outfd() {
  readlink /proc/$$/fd/$OUTFD 2>/dev/null | grep /tmp >/dev/null
  if [ "$?" -eq "0" ]; then
    OUTFD=0

    for FD in `ls /proc/$$/fd`; do
      readlink /proc/$$/fd/$FD 2>/dev/null | grep pipe >/dev/null
      if [ "$?" -eq "0" ]; then
        ps | grep " 3 $FD " | grep -v grep >/dev/null
        if [ "$?" -eq "0" ]; then
          OUTFD=$FD
          break
        fi
      fi
    done
  fi
}

ui_print() {
  $BOOTMODE && echo "$1" || echo -e "ui_print $1\nui_print" >> /proc/self/fd/$OUTFD
}

mount_partitions() {
  # Check A/B slot
  [ -f /data/magisk.img -o -f /cache/magisk.img -o -d /magisk ] && WRITE=ro || WRITE=rw
  SYS=/system
  REALSYS=/system
  SLOT=`getprop ro.boot.slot_suffix`
  [ -z $SLOT ] || ui_print "- A/B partition detected, current slot: $SLOT"
  ui_print "- Mounting filesystems -"
  ui_print "   Mounting /system, /vendor"
  is_mounted /system || [ -f /system/build.prop ] || mount -o $WRITE /system 2>/dev/null
  if ! is_mounted /system && ! [ -f /system/build.prop ]; then
    SYSTEMBLOCK=`find /dev/block -iname system$SLOT | head -n 1`
    mount -t ext4 -o $WRITE $SYSTEMBLOCK /system
	test "$WRITE" == "rw" && REALSYS=/system/system
  fi
  is_mounted /system || [ -f /system/build.prop ] || abort "! Cannot mount /system"
  cat /proc/mounts | grep -E '/dev/root|/system_root' >/dev/null && SKIP_INITRAMFS=true || SKIP_INITRAMFS=false
  if [ -f /system/init.rc ]; then
    SKIP_INITRAMFS=true
    mkdir /system_root 2>/dev/null
    mount --move /system /system_root
    mount -o bind /system_root/system /system
	test "$WRITE" == "rw" && { ROOT=/system_root; REALSYS=/system_root/system; }
  fi
  $SKIP_INITRAMFS && ui_print "   ! Device skip_initramfs detected"
  if [ -L /system/vendor ]; then
    # Seperate /vendor partition
    [ -f /data/magisk.img -o -f /cache/magisk.img -o -d /magisk ] && VEN=/system/vendor || VEN=/vendor
    is_mounted /vendor || mount -o $WRITE /vendor 2>/dev/null
    if ! is_mounted /vendor; then
      VENDORBLOCK=`find /dev/block -iname vendor$SLOT | head -n 1`
      mount -t ext4 -o $WRITE $VENDORBLOCK /vendor
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

getvar() {
  local VARNAME=$1
  local VALUE=$(eval echo \$$VARNAME)
  [ ! -z $VALUE ] && return
  for DIR in /dev /data /cache /system; do
    VALUE=`grep_prop $VARNAME $DIR/.magisk`
    [ ! -z $VALUE ] && break;
  done
  eval $VARNAME=\$VALUE
}

resolve_link() {
  RESOLVED="$1"
  while RESOLVE=`readlink $RESOLVED`; do
    RESOLVED=$RESOLVE
  done
  echo $RESOLVED
}

find_boot_image() {
  if [ -z "$BOOTIMAGE" ]; then
    if [ ! -z $SLOT ]; then
      BOOTIMAGE=`find /dev/block -iname boot$SLOT | head -n 1` 2>/dev/null
    else
      for BLOCK in boot_a kern-a android_boot kernel boot lnx bootimg; do
        BOOTIMAGE=`find /dev/block -iname $BLOCK | head -n 1` 2>/dev/null
        [ ! -z $BOOTIMAGE ] && break
      done
    fi
  fi
  # Recovery fallback
  if [ -z "$BOOTIMAGE" ]; then
    for FSTAB in /etc/*fstab*; do
      BOOTIMAGE=`grep -v '#' $FSTAB | grep -E '/boot[^a-zA-Z]' | grep -oE '/dev/[a-zA-Z0-9_./-]*'`
      [ ! -z $BOOTIMAGE ] && break
    done
  fi
  BOOTIMAGE=`resolve_link $BOOTIMAGE`
}

migrate_boot_backup() {
  # Update the broken boot backup
  if [ -f /data/stock_boot_.img.gz ]; then
    $MAGISKBIN/magiskboot --decompress /data/stock_boot_.img.gz
    mv /data/stock_boot_.img /data/stock_boot.img
  fi
  # Update our previous backup to new format if exists
  if [ -f /data/stock_boot.img ]; then
    ui_print "- Migrating boot image backup"
    SHA1=`$MAGISKBIN/magiskboot --sha1 /data/stock_boot.img 2>/dev/null`
    STOCKDUMP=/data/stock_boot_${SHA1}.img
    mv /data/stock_boot.img $STOCKDUMP
    $MAGISKBIN/magiskboot --compress $STOCKDUMP
  fi
  mv /data/magisk/stock_boot* /data 2>/dev/null
}

flash_boot_image() {
  # Make sure all blocks are writable
  $MAGISKBIN/magisk --unlock-blocks
  case "$1" in
    *.gz) COMMAND="gzip -d < \"$1\"";;
    *)    COMMAND="cat \"$1\"";;
  esac
  case "$2" in
    /dev/block/*)
      ui_print "- Flashing new boot image"
      eval $COMMAND | cat - /dev/zero | dd of="$2" bs=4096 >/dev/null 2>&1
      ;;
    *)
      ui_print "- Storing new boot image"
      eval $COMMAND | dd of="$2" bs=4096 >/dev/null 2>&1
      ;;
  esac
}

sign_chromeos() {
  ui_print "- Signing ChromeOS boot image"

  echo > empty
  ./chromeos/futility vbutil_kernel --pack new-boot.img.signed \
  --keyblock ./chromeos/kernel.keyblock --signprivate ./chromeos/kernel_data_key.vbprivk \
  --version 1 --vmlinuz new-boot.img --config empty --arch arm --bootloader empty --flags 0x1

  rm -f empty new-boot.img
  mv new-boot.img.signed new-boot.img
}

is_mounted() {
  if [ ! -z "$2" ]; then
    cat /proc/mounts | grep $1 | grep $2, >/dev/null
  else
    cat /proc/mounts | grep $1 >/dev/null
  fi
  return $?
}

remove_system_su() {
  if [ -f /system/bin/su -o -f /system/xbin/su ] && [ ! -f /su/bin/su ]; then
    ui_print "! System installed root detected, mount rw :("
    mount -o rw,remount /system
    # SuperSU
    if [ -e /system/bin/.ext/.su ]; then
      mv -f /system/bin/app_process32_original /system/bin/app_process32 2>/dev/null
      mv -f /system/bin/app_process64_original /system/bin/app_process64 2>/dev/null
      mv -f /system/bin/install-recovery_original.sh /system/bin/install-recovery.sh 2>/dev/null
      cd /system/bin
      if [ -e app_process64 ]; then
        ln -sf app_process64 app_process
      else
        ln -sf app_process32 app_process
      fi
    fi
    rm -rf /system/.pin /system/bin/.ext /system/etc/.installed_su_daemon /system/etc/.has_su_daemon \
    /system/xbin/daemonsu /system/xbin/su /system/xbin/sugote /system/xbin/sugote-mksh /system/xbin/supolicy \
    /system/bin/app_process_init /system/bin/su /cache/su /system/lib/libsupol.so /system/lib64/libsupol.so \
    /system/su.d /system/etc/install-recovery.sh /system/etc/init.d/99SuperSUDaemon /cache/install-recovery.sh \
    /system/.supersu /cache/.supersu /data/.supersu \
    /system/app/Superuser.apk /system/app/SuperSU /cache/Superuser.apk  2>/dev/null
  fi
}

api_level_arch_detect() {
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

boot_actions() {
  if [ ! -d /dev/magisk/mirror/bin ]; then
    mkdir -p /dev/magisk/mirror/bin
    mount -o bind $MAGISKBIN /dev/magisk/mirror/bin
  fi
  MAGISKBIN=/dev/magisk/mirror/bin
}

recovery_actions() {
  # TWRP bug fix
  mount -o bind /dev/urandom /dev/random
  # Preserve environment varibles
  OLD_PATH=$PATH
  OLD_LD_PATH=$LD_LIBRARY_PATH
  if [ ! -d $TMPDIR/bin ]; then
    # Add busybox to PATH
    mkdir -p $TMPDIR/bin
    ln -s $MAGISKBIN/busybox $TMPDIR/bin/busybox
    $MAGISKBIN/busybox --install -s $TMPDIR/bin
    export PATH=$TMPDIR/bin:$PATH
  fi
  # Temporarily block out all custom recovery binaries/libs
  mv /sbin /sbin_tmp
  # Add all possible library paths
  $IS64BIT && export LD_LIBRARY_PATH=/system/lib64:/system/vendor/lib64 || export LD_LIBRARY_PATH=/system/lib:/system/vendor/lib
}

recovery_cleanup() {
  mv /sbin_tmp /sbin 2>/dev/null
  export LD_LIBRARY_PATH=$OLD_LD_PATH
  [ -z $OLD_PATH ] || export PATH=$OLD_PATH
  ui_print "   Unmounting partitions..."
  umount -l /system_root 2>/dev/null
  umount -l /system 2>/dev/null
  umount -l /vendor 2>/dev/null
  umount -l /dev/random 2>/dev/null
}

abort() {
  ui_print "$1"
  $BOOTMODE || recovery_cleanup
  exit 1
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

request_size_check() {
  reqSizeM=`du -s $1 | cut -f1`
  reqSizeM=$((reqSizeM / 1024 + 1))
}

request_zip_size_check() {
  reqSizeM=`unzip -l "$1" | tail -n 1 | awk '{ print int($1 / 1048567 + 1) }'`
}

image_size_check() {
  SIZE="`$MAGISKBIN/magisk --imgsize $IMG`"
  curUsedM=`echo "$SIZE" | cut -d" " -f1`
  curSizeM=`echo "$SIZE" | cut -d" " -f2`
  curFreeM=$((curSizeM - curUsedM))
}

supersu_is_mounted() {
  case `mount` in
    *" $1 "*) echo 1;;
    *) echo 0;;
  esac
}

supersuimg_mount() {
  supersuimg=$(ls /cache/su.img /data/su.img 2>/dev/null)
  if [ "$supersuimg" ]; then
    if [ "$(supersu_is_mounted /su)" == 0 ]; then
      ui_print "   Mounting /su..."
      test ! -e /su && mkdir /su
      mount -t ext4 -o rw,noatime $supersuimg /su 2>/dev/null
      for i in 0 1 2 3 4 5 6 7; do
        test "$(supersu_is_mounted /su)" == 1 && break
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
             test -f "$SYS/app/$FILE.apk" && $WPAPP_PRFX $UNITY$SYS/app/$FILE.apk || { test -f "$SYS/app/$FILE/$FILE.apk" && $WPAPP_PRFX $UNITY$SYS/app/$FILE/$FILE.apk; }
           else
             test -f "SYS/priv-app/$FILE/$FILE.apk" && $WPAPP_PRFX $UNITY$SYS/priv-app/$FILE/$FILE.apk
           fi;;
    "file") test "$MAGISK" == true && mktouch $FILE || sys_wipe_ch $FILE;;
  esac
}

cp_ch() {
  mkdir -p "${2%/*}"
  chmod 0755 "${2%/*}"
  cp -af "$1" "$2"
  test -z $3 && chmod 0644 "$2" || chmod "$3" "$2"
  restorecon "$2"
}

sys_cpbak_ch() {
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
  test ! -z $XML_PRFX && sed -i "s|<XML_PRFX>|$XML_PATH|" $1 || sed -i "/<XML_PRFX>/d" $1
  if [ "$MAGISK" == false ]; then
    sed -i "s|<EXT>|$EXT|" $1
	sed -i "s|<SEINJECT>|$SEINJECT|" $1
	sed -i "/<AMLPATH>/d" $1
	sed -i "s|$MOUNTPATH||g" $1
  else
	sed -i "s|<EXT>|.sh|" $1
	sed -i "s|<SEINJECT>|magiskpolicy|" $1
	sed -i "s|<AMLPATH>|$AMLPATH|" $1
	sed -i "s|$MOUNTPATH|/magisk|g" $1
  fi
}

add_to_info() {
  test ! "$(grep "$1" $2)" && echo "$1" >> $2
}

custom_app_install() {
  $OLDAPP && $CP_PRFX $INSTALLER/custom/$1/$1.apk $UNITY$SYS/app/$1.apk || $CP_PRFX $INSTALLER/custom/$1/$1.apk $UNITY$SYS/priv-app/$1/$1.apk
}
