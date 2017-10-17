# AnyKernel2 Ramdisk Mod Script
# osm0sis @ xda-developers

# VARIABLES FROM MAIN INSTALLER
AK2=<INSTALLER>/common/unity-audmodlib/ak2
SEINJECT=<SEINJECT>
BOOTMODE=<BOOTMODE>
ACTION=<ACTION>
ABILONG=<ABILONG>

# DETERMINE THE LOCATION OF THE BOOT PARTITION
if [ -e /dev/block/platform/*/by-name/boot ]; then
block=/dev/block/platform/*/by-name/boot
elif [ -e /dev/block/platform/*/*/by-name/boot ]; then
block=/dev/block/platform/*/*/by-name/boot
fi
# FORCE EXPANSION OF THE PATH SO WE CAN USE IT
block=`echo -n $block`
# ENABLES DETECTION OF THE SUFFIX FOR THE ACTIVE BOOT PARTITION ON SLOT-BASED DEVICES
is_slot_device=0

# import patching functions/variables - see for reference
. $AK2/tools/ak2-core.sh

## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
chmod -R 750 $ramdisk/*
chown -R root:root $ramdisk/*

## AnyKernel install
dump_boot

# begin ramdisk changes

remove_section_mod() {
  sed -i "/${2//\//\\/}/,/^$/d" $1
}

# restore_file <file>
restore_file() { test -f $1~ && mv -f $1~ $1; }

cp_ch() {
  cp -af "$1" "$2"
  chmod 0755 "$2"
  restorecon "$2"
}

if [ "$ACTION" == "Install" ]; then
  ui_print "    Patching init files..."
  
  touch /system/etc/unity-initd
  
  # remove old broken init.d
  test -f /system/bin/sysinit && { backup_file /system/bin/sysinit; sed -i -e '\|<FILES>| a\ $SYS/bin/sysinit~' -e '\|<FILES2>| a\ rm -f $SYS/bin/sysinit' $INSTALLER/system/addon.d/unity-init.sh; }
  test -f /system/xbin/sysinit && { backup_file /system/xbin/sysinit; sed -i -e '\|<FILES>| a\ $SYS/xbin/sysinit~' -e '\|<FILES2>| a\ rm -f $SYS/xbin/sysinit' $INSTALLER/system/addon.d/unity-init.sh; }
  test -f /system/bin/sepolicy-inject && { backup_file /system/bin/sepolicy-inject; sed -i -e '\|<FILES>| a\ $SYS/bin/sepolicy-inject~' -e '\|<FILES2>| a\ rm -f $SYS/bin/sepolicy-inject' $INSTALLER/system/addon.d/unity-init.sh; }
  test -f /system/xbin/sepolicy-inject && { backup_file /system/xbin/sepolicy-inject; sed -i -e '\|<FILES>| a\ $SYS/xbin/sepolicy-inject~' -e '\|<FILES2>| a\ rm -f $SYS/xbin/sepolicy-inject' $INSTALLER/system/addon.d/unity-init.sh; }
  sed -i -e "s|<BLOCK>|$block|" -e "/<FILES>/d" -e "/<FILES2>/d" $INSTALLER/system/addon.d/unity-initd.sh
  test -d /system/addon.d && cp_ch $INSTALLER/system/addon.d/unity-initd.sh /system/addon.d/unity-initd.sh
  for FILE in init*.rc; do
    backup_file $FILE
    remove_section_mod $FILE "# Run sysinit"
    remove_line $FILE "start sysinit"
    remove_section_mod $FILE "# sysinit"
    remove_section_mod $FILE "service sysinit"
    remove_section_mod $FILE "# init.d"
    remove_section_mod $FILE "service userinit"
  done
  
  # add new init.d
  append_file init.rc "# init.d" init
  cp_ch $patch/sysinit sbin/sysinit
  
  case $ABILONG in
    arm64*) cp_ch /tmp/anykernel/tools/setools-android/arm64-v8a/sepolicy-inject $SEINJECT;;
    armeabi-v7a*) cp_ch /tmp/anykernel/tools/setools-android/armeabi-v7a/sepolicy-inject $SEINJECT;;
    arm*) cp_ch /tmp/anykernel/tools/setools-android/armeabi/sepolicy-inject $SEINJECT;;
    x86_64*) cp_ch /tmp/anykernel/tools/setools-android/x86_64/sepolicy-inject $SEINJECT;;
    x86*) cp_ch /tmp/anykernel/tools/setools-android/x86/sepolicy-inject $SEINJECT;;
    mips64*) cp_ch /tmp/anykernel/tools/setools-android/mips64/sepolicy-inject $SEINJECT;;
    mips*) cp_ch /tmp/anykernel/tools/setools-android/mips/sepolicy-inject $SEINJECT;;
    *) ui_print "   ! CPU Type not supported for sepolicy patching!"; abort "   ! Restore your boot img and add initd support to kernel another way !";;
  esac
  
  # SEPOLICY PATCHES BY CosmicDan @xda-developers
  ui_print "    Injecting sepolicy with init.d permissions..."
  
  backup_file sepolicy
  $SEINJECT -z sysinit -P sepolicy
  $SEINJECT -Z sysinit -P sepolicy
  $SEINJECT -s init -t sysinit -c process -p transition -P sepolicy
  $SEINJECT -s init -t sysinit -c process -p rlimitinh -P sepolicy
  $SEINJECT -s init -t sysinit -c process -p siginh -P sepolicy
  $SEINJECT -s init -t sysinit -c process -p noatsecure -P sepolicy
  $SEINJECT -s sysinit -t sysinit -c dir -p search,read -P sepolicy
  $SEINJECT -s sysinit -t sysinit -c file -p read,write,open -P sepolicy
  $SEINJECT -s sysinit -t sysinit -c unix_dgram_socket -p create,connect,write,setopt -P sepolicy
  $SEINJECT -s sysinit -t sysinit -c lnk_file -p read -P sepolicy
  $SEINJECT -s sysinit -t sysinit -c process -p fork,sigchld -P sepolicy
  $SEINJECT -s sysinit -t sysinit -c capability -p dac_override -P sepolicy
  $SEINJECT -s sysinit -t system_file -c file -p entrypoint,execute_no_trans -P sepolicy
  $SEINJECT -s sysinit -t devpts -c chr_file -p read,write,open,getattr,ioctl -P sepolicy
  $SEINJECT -s sysinit -t rootfs -c file -p execute,read,open,execute_no_trans,getattr -P sepolicy
  $SEINJECT -s sysinit -t shell_exec -c file -p execute,read,open,execute_no_trans,getattr -P sepolicy
  $SEINJECT -s sysinit -t zygote_exec -c file -p execute,read,open,execute_no_trans,getattr -P sepolicy
  $SEINJECT -s sysinit -t toolbox_exec -c file -p getattr,open,read,ioctl,lock,getattr,execute,execute_no_trans,entrypoint -P sepolicy

else
  rm -f sbin/sysinit
  rm -f $SEINJECT
  restore_file /system/bin/sysinit
  restore_file /system/xbin/sysinit
  restore_file /system/bin/sepolicy-inject
  restore_file /system/xbin/sepolicy-inject
  # restore all .rc files
  for FILE in init*.rc; do
    restore_file $FILE
  done
  restore_file sepolicy
  rm -f /system/addon.d/unity-initd.sh
  rm -f /system/etc/unity-initd
fi

# end ramdisk changes

write_boot

## end install

