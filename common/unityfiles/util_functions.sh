##########################################################################################
#
# Unity (Un)Install Utility Functions
# Adapted from topjohnwu's Magisk General Utility Functions
#
# Magisk util_functions is still used and will override any listed here
# They're present for system installs
#
##########################################################################################

toupper() {
  echo "$@" | tr '[:lower:]' '[:upper:]'
}

find_block() {
  for BLOCK in "$@"; do
    DEVICE=`find /dev/block -type l -iname $BLOCK | head -n 1` 2>/dev/null
    if [ ! -z $DEVICE ]; then
      readlink -f $DEVICE
      return 0
    fi
  done
  # Fallback by parsing sysfs uevents
  for uevent in /sys/dev/block/*/uevent; do
    local DEVNAME=`grep_prop DEVNAME $uevent`
    local PARTNAME=`grep_prop PARTNAME $uevent`
    for p in "$@"; do
      if [ "`toupper $p`" = "`toupper $PARTNAME`" ]; then
        echo /dev/block/$DEVNAME
        return 0
      fi
    done
  done
  return 1
}

mount_partitions() {
  # Check A/B slot
  SLOT=`grep_cmdline androidboot.slot_suffix`
  if [ -z $SLOT ]; then
    SLOT=_`grep_cmdline androidboot.slot`
    [ $SLOT = "_" ] && SLOT=
  fi
  [ -z $SLOT ] || ui_print "- Current boot slot: $SLOT"
  ui_print "- Mounting /system, /vendor"
  REALSYS=/system
  [ -f /system/build.prop ] || is_mounted /system || mount -o rw /system 2>/dev/null
  if ! is_mounted /system && ! [ -f /system/build.prop ]; then
    SYSTEMBLOCK=`find_block system$SLOT`
    mount -t ext4 -o rw $SYSTEMBLOCK /system
  fi
  [ -f /system/build.prop ] || is_mounted /system || abort "! Cannot mount /system"
  cat /proc/mounts | grep -E '/dev/root|/system_root' >/dev/null && SYSTEM_ROOT=true || SYSTEM_ROOT=false
  if [ -f /system/init ]; then
    ROOT=/system_root
    REALSYS=/system_root/system
    SYSTEM_ROOT=true
    mkdir /system_root 2>/dev/null
    mount --move /system /system_root
    mount -o bind /system_root/system /system
  fi
  $SYSTEM_ROOT && ui_print "- Device using system_root_image"
  if [ -L /system/vendor ]; then
    # Seperate /vendor partition
    VEN=/vendor
    REALVEN=/vendor
    is_mounted /vendor || mount -o rw /vendor 2>/dev/null
    if ! is_mounted /vendor; then
      VENDORBLOCK=`find_block vendor$SLOT`
      mount -t ext4 -o rw $VENDORBLOCK /vendor
    fi
    is_mounted /vendor || abort "! Cannot mount /vendor"
  else
    VEN=/system/vendor
    REALVEN=$REALSYS/vendor
  fi
}

grep_cmdline() {
  local REGEX="s/^$1=//p"
  sed -E 's/ +/\n/g' /proc/cmdline | sed -n "$REGEX" 2>/dev/null
}

grep_prop() {
  local REGEX="s/^$1=//p"
  shift
  local FILES=$@
  [ -z "$FILES" ] && FILES='/system/build.prop'
  sed -n "$REGEX" $FILES 2>/dev/null | head -n 1
}

find_boot_image() {
  BOOTIMAGE=
  if [ ! -z $SLOT ]; then
    BOOTIMAGE=`find_block boot$SLOT ramdisk$SLOT`
  else
    BOOTIMAGE=`find_block boot ramdisk boot_a kern-a android_boot kernel lnx bootimg`
  fi
  if [ -z $BOOTIMAGE ]; then
    # Lets see what fstabs tells me
    BOOTIMAGE=`grep -v '#' /etc/*fstab* | grep -E '/boot[^a-zA-Z]' | grep -oE '/dev/[a-zA-Z0-9_./-]*' | head -n 1`
  fi
}

flash_boot_image_unity() {
  local COMMAND BLOCK
  # Make sure all blocks are writable
  magisk --unlock-blocks 2>/dev/null
  case "$1" in
    *.gz) COMMAND="gzip -d < '$1'";;
    *)    COMMAND="cat '$1'";;
  esac
  case "$2" in
    /dev/block/*) BLOCK=true;;
    *) BLOCK=false;;
  esac
  if $BOOTSIGNED; then
    ui_print "   Signing boot image..."
    eval $COMMAND | $BOOTSIGNER /boot $1 $AVB/verity.pk8 $AVB/verity.x509.pem boot-new-signed.img
    ui_print "   Flashing new boot image..."
    $BLOCK && dd if=/dev/zero of="$2" 2>/dev/null
    dd if=boot-new-signed.img of="$2"
  elif $BLOCK; then
    ui_print "   Flashing new boot image..."
    eval $COMMAND | cat - /dev/zero 2>/dev/null | dd of="$2" bs=4096 2>/dev/null
  else
    ui_print "   Storing new boot image..."
    eval $COMMAND | dd of="$2" bs=4096 2>/dev/null
  fi
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
  cat /proc/mounts | grep -q " `readlink -f $1` " 2>/dev/null
  return $?
}

api_level_arch_detect() {
  API=`grep_prop ro.build.version.sdk`
  ABI=`grep_prop ro.product.cpu.abi | cut -c-3`
  ABI2=`grep_prop ro.product.cpu.abi2 | cut -c-3`
  ABILONG=`grep_prop ro.product.cpu.abi`
  ARCH=arm
  ARCH32=arm
  IS64BIT=false
  if [ "$ABI" = "x86" ]; then ARCH=x86; ARCH32=x86; fi;
  if [ "$ABI2" = "x86" ]; then ARCH=x86; ARCH32=x86; fi;
  if [ "$ABILONG" = "arm64-v8a" ]; then ARCH=arm64; ARCH32=arm; IS64BIT=true; fi;
  if [ "$ABILONG" = "x86_64" ]; then ARCH=x64; ARCH32=x86; IS64BIT=true; fi;
}

recovery_cleanup() {
  mv /sbin_tmp /sbin 2>/dev/null
  [ -z $OLD_PATH ] || export PATH=$OLD_PATH
  [ -z $OLD_LD_LIB ] || export LD_LIBRARY_PATH=$OLD_LD_LIB
  [ -z $OLD_LD_PRE ] || export LD_PRELOAD=$OLD_LD_PRE
  ui_print "- Unmounting partitions"
  umount -l /system_root 2>/dev/null
  umount -l /system 2>/dev/null
  umount -l /vendor 2>/dev/null
  umount -l /dev/random 2>/dev/null
}

unmount_partitions() {
  [ "$supersuimg" -o -d /su ] && umount /su 2>/dev/null
  umount -l /system_root 2>/dev/null
  umount -l /system 2>/dev/null
  umount -l /vendor 2>/dev/null
}

abort() {
  ui_print "$1"
  unmount_partitions
  exit 1
}

set_perm() {
  chown $2:$3 $1 || return 1
  chmod $4 $1 || return 1
  [ -z $5 ] && chcon 'u:object_r:system_file:s0' $1 || chcon $5 $1 || return 1
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

sysover_partitions() {
  if [ -f /system/init.rc ]; then
    ROOT=/system_root
    REALSYS=/system_root/system
  else
    REALSYS=/system
  fi
  if [ -L /system/vendor ]; then
    VEN=/vendor
    REALVEN=/vendor
  else
    VEN=/system/vendor
    REALVEN=$REALSYS/vendor
  fi
}

supersuimg_mount() {
  supersuimg=$(ls /cache/su.img /data/su.img 2>/dev/null)
  if [ "$supersuimg" ]; then
    if ! is_mounted /su; then
      ui_print "    Mounting /su..."
      [ -d /su ] || mkdir /su
      mount -t ext4 -o rw,noatime $supersuimg /su 2>/dev/null
      for i in 0 1 2 3 4 5 6 7; do
        is_mounted /su && break
        local loop=/dev/block/loop$i
        mknod $loop b 7 $i
        losetup $loop $supersuimg
        mount -t ext4 -o loop $loop /su 2>/dev/null
      done
    fi
  fi
}

require_new_magisk() {
  ui_print "*******************************"
  ui_print " Please install Magisk $(echo $MINMAGISK | sed -r "s/(.{2})(.{1}).*/v\1.\2+\!/") "
  ui_print "*******************************"
  exit 1
}

require_new_api() {
  ui_print "***********************************"
  ui_print "!   Your system API of $API isn't"
  if [ "$1" == "minimum" ]; then
    ui_print "! higher than the $1 API of $MINAPI"
    ui_print "! Please upgrade to a newer version"
    ui_print "!  of android with at least API $MINAPI"
  else
    ui_print "!   lower than the $1 API of $MAXAPI"
    ui_print "! Please downgrade to an older version"
    ui_print "!    of android with at most API $MAXAPI"
  fi
  ui_print "***********************************"
  exit 1
}

cleanup() {
  if $RAMDISK; then
    ui_print "   Repacking ramdisk..."
    cd $RD
    find . | cpio -H newc -o > ../ramdisk.cpio
    cd ..
    ui_print "   Repacking boot image..."
    ./magiskboot --repack "$BOOTIMAGE" || abort "! Unable to repack boot image!"
    $CHROMEOS && sign_chromeos
    ./magiskboot --cleanup
    flash_boot_image_unity new-boot.img "$BOOTIMAGE"
    rm -f new-boot.img
    cd /
  fi
  if $MAGISK; then
    # UNMOUNT MAGISK IMAGE AND SHRINK IF POSSIBLE
    unmount_magisk_img
    $BOOTMODE || recovery_cleanup
    rm -rf $TMPDIR
    # PLEASE LEAVE THIS MESSAGE IN YOUR FLASHABLE ZIP FOR CREDITS :)
    ui_print " "
    ui_print "    *******************************************"
    ui_print "    *      Powered by Magisk (@topjohnwu)     *"
    ui_print "    *******************************************"
  else
    ui_print "   Unmounting partitions..."
    unmount_partitions
    rm -rf $TMPDIR
  fi
  ui_print " "
  ui_print "    *******************************************"
  ui_print "    *    Unity by ahrion & zackptg5 @ XDA     *"
  ui_print "    *******************************************"
  ui_print " "
  exit 0
}

device_check() {
  if [ "$(grep_prop ro.product.device)" == "$1" ] || [ "$(grep_prop ro.build.product)" == "$1" ]; then
    return 0
  else
    return 1
  fi
}

check_bak() {
  case $1 in
    /system/*|/vendor/*) BAK=true; BAKFILE=$INFO;;
    $MOUNTPATH/*|/sbin/.core/img/*) if ! $MAGISK || $SYSOVERRIDE; then 
                                      BAK=true
                                    else
                                      BAK=false
                                    fi
                                    BAKFILE=$INFO;;
    $RD*) BAK=true; BAKFILE=$INFORD;;
    *) BAK=true; BAKFILE=$INFO;;
  esac
  [ -z $2 ] || BAK=$2
}

cp_ch_nb() {
  if [ -z $4 ]; then check_bak $2; else check_bak $2 $4; fi
  if $BAK && [ ! "$(grep "$2$" $BAKFILE 2>/dev/null)" ]; then 
    echo "$2" >> $BAKFILE
  elif [ ! "$(grep "$2$" $BAKFILE 2>/dev/null)" ]; then 
    echo "$2NOBAK" >> $BAKFILE
  fi
  mkdir -p "$(dirname $2)"
  cp -af "$1" "$2"
  if [ -z $3 ]; then
    chmod 0644 "$2"
  else
    chmod $3 "$2"
  fi
  case $2 in
    */vendor/etc/*) chcon u:object_r:vendor_configs_file:s0 $2;;
    */vendor/*.apk) chcon u:object_r:vendor_app_file:s0 $2;;
    */vendor/*) chcon u:object_r:vendor_file:s0 $2;;
    */system/*) chcon u:object_r:system_file:s0 $2;;
  esac
}

cp_ch() {
  check_bak $2
  local EXT 
  case $2 in
    $RD*) EXT="~";;
    *) EXT=".bak";;
  esac
  if [ -f "$2" ] && [ ! -f "$2$EXT" ] && $BAK; then
    cp -af $2 $2$EXT
    echo "$2$EXT" >> $BAKFILE
  fi
  if [ -z $3 ]; then cp_ch_nb $1 $2 0644 $BAK; else cp_ch_nb $1 $2 $3 $BAK; fi
}

patch_script() {
  sed -i "s|<MAGISK>|$MAGISK|" $1
  sed -i "s|<LIBDIR>|$LIBDIR|" $1
  sed -i "s|<SYSOVERRIDE>|$SYSOVERRIDE|" $1
  sed -i "s|<MODID>|$MODID|" $1
  if $MAGISK; then
    if $SYSOVERRIDE; then
      sed -i "s|<INFO>|$INFO|" $1
      sed -i "s|<VEN>|$REALVEN|" $1
    else
      sed -i "s|<VEN>|$VEN|" $1
    fi
    sed -i "s|<ROOT>|\"\"|" $1
    sed -i "s|<SYS>|/system|" $1
    sed -i "s|<SHEBANG>|#!/system/bin/sh|" $1
    sed -i "s|<SEINJECT>|magiskpolicy|" $1
    sed -i "s|\$MOUNTPATH|/sbin/.core/img|g" $1
  else
    if [ ! -z $ROOT ]; then sed -i "s|<ROOT>|$ROOT|" $1; else sed -i "s|<ROOT>|\"\"|" $1; fi
    sed -i "s|<SYS>|$REALSYS|" $1
    sed -i "s|<VEN>|$REALVEN|" $1
    sed -i "s|<SHEBANG>|$SHEBANG|" $1
    sed -i "s|<SEINJECT>|$SEINJECT|" $1
    sed -i "s|\$MOUNTPATH||g" $1
  fi
}

install_script() {
  if $MAGISK; then
    cp_ch_nb $1 $MODPATH/$(basename $1)
    patch_script $MODPATH/$(basename $1)
  else
    cp_ch_nb $1 $MODPATH/$MODID-$(basename $1 | sed 's/.sh$//')$2 0700
    patch_script $MODPATH/$MODID-$(basename $1 | sed 's/.sh$//')$2
  fi
}

prop_process() {
  sed -i "/^#/d" $1
  if $MAGISK; then
    [ -f $PROP ] || mktouch $PROP
  else
    [ -f $PROP ] || mktouch $PROP "$SHEBANG"
    sed -ri "s|^(.*)=(.*)|setprop \1 \2|g" $1
  fi
  while read LINE; do
    echo "$LINE" >> $PROP
  done < $1
  $MAGISK || chmod 0700 $PROP
}

script_type() {
  supersuimg_mount
  SHEBANG="#!/system/bin/sh"; ROOTTYPE="other root or rootless"; MODPATH=/system/etc/init.d; SEINJECT=/sbin/sepolicy-inject
  if [ "$supersuimg" ] || [ -d /su ]; then
    SHEBANG="#!/su/bin/sush"; ROOTTYPE="systemless SuperSU"; MODPATH=/su/su.d; SEINJECT=supolicy
  elif [ -e "$(find /data /cache -name supersu_is_here | head -n1)" ]; then
    SHEBANG="#!/su/bin/sush"; ROOTTYPE="systemless SuperSU"
    MODPATH=$(dirname `find /data /cache -name supersu_is_here | head -n1`)/su.d
    SEINJECT=supolicy
  elif [ -d /system/su ] || [ -f /system/xbin/daemonsu ] || [ -f /system/xbin/sugote ]; then
    MODPATH=/system/su.d; SEINJECT=supolicy; ROOTTYPE="system SuperSU"
  elif [ -f /system/xbin/su ]; then
    if [ "$(grep "SuperSU" /system/xbin/su)" ]; then
      MODPATH=/system/su.d; ROOTTYPE="system SuperSU"; SEINJECT=supolicy
    else
      ROOTTYPE="LineageOS SU"
    fi
  fi
}

set_vars() {
  SYS=/system
  if [ -d /system/priv-app ]; then OLDAPP=false; else OLDAPP=true; fi
  if $BOOTMODE; then
    MOD_VER="/sbin/.core/img/$MODID/module.prop"
    OLD_AML_VER="/sbin/.core/img/audmodlib/module.prop"
  else
    MOD_VER="$MODPATH/module.prop"
    OLD_AML_VER="$MOUNTPATH/audmodlib/module.prop"
  fi
  INFO="$MODPATH/$MODID-files"
  PROP=$MODPATH/system.prop
  if $MAGISK && ! $SYSOVERRIDE; then
    VEN=/system/vendor
    UNITY="$MODPATH"
  else
    UNITY=""
    if [ -d /system/addon.d ]; then
      INFO=/system/addon.d/$MODID-files
    else
      INFO=/system/etc/$MODID-files
    fi
    if $MAGISK && $SYSOVERRIDE; then
      patch_script $INSTALLER/common/unityfiles/modidsysover.sh
      sed -i -e "/# CUSTOM USER SCRIPT/ r $INSTALLER/common/uninstall.sh" -e '/# CUSTOM USER SCRIPT/d' $INSTALLER/common/unityfiles/modidsysover.sh
      cp_ch_nb $INSTALLER/common/unityfiles/modidsysover.sh $MOUNTPATH/.core/post-fs-data.d/$MODID-sysover.sh 0755 false
    else
      # DETERMINE SYSTEM BOOT SCRIPT TYPE
      script_type
      PROP=$MODPATH/$MODID-props.sh
      MOD_VER="/system/etc/$MODID-module.prop"
      OLD_AML_VER="/system/etc/audmodlib-module.prop"
    fi
  fi
  if $DYNAMICOREO && [ $API -ge 26 ]; then
    LIBPATCH="\/vendor"; LIBDIR=$VEN
  else
    LIBPATCH="\/system"; LIBDIR=/system
  fi
}

uninstall_files() {
  local FILE="$1"
  if [ "$1" == "$INFO" ]; then
    $BOOTMODE && [ -f /sbin/.core/img/$MODID/$MODID-files ] && FILE=/sbin/.core/img/$MODID/$MODID-files
    TMP=".bak"
    $MAGISK || [ -f $FILE ] || abort "   ! Mod not detected !"
  elif [ "$1" == "$INFORD" ]; then
    $RAMDISK || continue
    TMP="~"
  else
    return 1
  fi
  if [ -f $FILE ]; then
    while read LINE; do
      LINE=$(echo $LINE | sed -r "s/(.*)NOBAK$/\1/")
      if [ "$(echo -n $LINE | tail -c 4)" == ".bak" ] || [ "$(echo -n $LINE | tail -c 1)" == "~" ]; then
        continue
      elif [ -f "$LINE$TMP" ]; then
        mv -f $LINE$TMP $LINE
      else
        rm -f $LINE
        while true; do
          LINE=$(dirname $LINE)
          if [ "$(ls $LINE)" ]; then
            break 1
          else
            rm -rf $LINE
          fi
        done
      fi
    done < $FILE
    rm -f $FILE
  fi
}

unpack_ramdisk() {
  local PRE POST
  if [ "$1" == "late" ]; then
    PRE="  "; POST="..."
  else
    PRE="-"; POST=""
  fi
  BOOTDIR=$INSTALLER/common/unityfiles/boot
  AVB=$INSTALLER/common/unityfiles/avb
  RD=$BOOTDIR/ramdisk
  INFORD="$RD/$MODID-files"
  BOOTSIGNER="/system/bin/dalvikvm -Xbootclasspath:/system/framework/core-oj.jar:/system/framework/core-libart.jar:/system/framework/conscrypt.jar:/system/framework/bouncycastle.jar -Xnodex2oat -Xnoimage-dex2oat -cp $AVB/BootSignature_Android.jar com.android.verity.BootSignature"
  RAMDISK=true; BOOTSIGNED=false; HIGHCOMP=false; CHROMEOS=false
  mkdir -p $RD
  cp -af $INSTALLER/common/unityfiles/$ARCH32/. $CHROMEDIR $BOOTDIR
  chmod -R 755 $BOOTDIR
  cp -af $BOOTDIR/magiskboot $RD/magiskboot
  find_boot_image
  ui_print " "
  [ -z $BOOTIMAGE ] && abort "   ! Unable to detect target image"
  ui_print "$PRE Checking boot image signature$POST"
  cd $BOOTDIR
  dd if=$BOOTIMAGE of=boot.img
  eval $BOOTSIGNER -verify boot.img 2>&1 | grep "VALID" && BOOTSIGNED=true
  $BOOTSIGNED && ui_print "   Boot image is signed with AVB 1.0"
  rm -f boot.img
  ./magiskinit -x magisk magisk
  ui_print "$PRE Unpacking boot image$POST"
  ./magiskboot --unpack "$BOOTIMAGE"
  case $? in
    1 ) abort "  ! Unable to unpack boot image";;
    2 ) HIGHCOMP=true;;
    3 ) ui_print "   ChromeOS boot image detected"; CHROMEOS=true;;
    4 ) ui_print "   ! Sony ELF32 format detected"; abort "   ! Please use BootBridge from @AdrianDC to flash this mod";;
    5 ) ui_print "   ! Sony ELF64 format detected" abort "   ! Stock kernel cannot be patched, please use a custom kernel";;
  esac
  ui_print "$PRE Checking ramdisk status$POST"
  ./magiskboot --cpio ramdisk.cpio test
  if [ $? -eq 2 ]; then
    HIGHCOMP=true
    ui_print "   ! Insufficient boot partition size detected"
    ui_print "   Enabling high compression mode"
  fi
  cd ramdisk
  ./magiskboot --cpio ../ramdisk.cpio "extract"
  rm -f magiskboot ../ramdisk.cpio
  cd /
  [ "$POST" ] && ui_print " "
}

remove_old_aml() {
  ui_print " "
  ui_print "   ! Old AML Detected! Removing..."
  if $MAGISK; then
    local MODS=$(grep "^fi #.*" $(dirname $OLD_AML_VER)/post-fs-data.sh | sed "s/fi #//g")
    if $BOOTMODE; then local DIR=/sbin/.core/img; else local DIR=$MOUNTPATH; fi
  else
    local MODS=$(sed -n "/^# MOD PATCHES/,/^$/p" $MODPATH/audmodlib-post-fs-data | sed -e "/^# MOD PATCHES/d" -e "/^$/d" -e "s/^#//g")
    if [ -d /system/addon.d ]; then local DIR=/system/addon.d; else local DIR=/system/etc; fi
  fi
  for MOD in ${MODS} audmodlib; do
    if $MAGISK; then local FILE=$DIR/$MOD/$MOD-files; else local FILE=$DIR/$MOD-files; fi
    if [ -f $FILE ]; then
      while read LINE; do
        if [ -f "$LINE.bak" ]; then
          mv -f "$LINE.bak" "$LINE"
        elif [ -f "$LINE.tar" ]; then
          tar -xf "$LINE.tar" -C "${LINE%/*}"
        else
          rm -f "$LINE"
        fi
        if [ ! "$(ls -A "${LINE%/*}")" ]; then
          rm -rf ${LINE%/*}
        fi
      done < $FILE
      rm -f $FILE
    fi
    if $MAGISK; then rm -rf $MOUNTPATH/$MOD /sbin/.core/img/$MOD; else rm -f /system/addon.d/$MODID.sh; fi
  done
}
