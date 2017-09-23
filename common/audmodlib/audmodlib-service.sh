#!/system/bin/sh
# This script will be executed in late_start service mode
# More info in the main Magisk thread
SH=${0%/*}
LOG_FILE=/cache/audmodlib-service.log
MODIDS=""

# DETERMINE IF PIXEL (A/B OTA) DEVICE
ABDeviceCheck=$(cat /proc/cmdline | grep slot_suffix | wc -l)
if [ "$ABDeviceCheck" -gt 0 ]; then
  isABDevice=true
  if [ -d "/system_root" ]; then
	SYS=/system_root/system
  else
	SYS=/system/system
  fi
else
  isABDevice=false
  SYS=/system
fi

if [ $isABDevice == true ] || [ ! -d "$SYS/vendor" ]; then
  VEN=/vendor
else
  VEN=$SYS/vendor
fi

supersuimg=$(ls /cache/su.img /data/su.img 2>/dev/null);

supersu_is_mounted() {
case `mount` in
  *" $1 "*) echo 1;;
  *) echo 0;;
esac
}

if [ "$supersuimg" ]; then
  if [ "$(supersu_is_mounted /su)" == 0 ]; then
    test ! -e /su && mkdir /su
    mount -t ext4 -o rw,noatime $supersuimg /su 2>/dev/null
    for i in 0 1 2 3 4 5 6 7; do
	  test "$(supersu_is_mounted /su)" == 1 && break
	  loop=/dev/block/loop$i
	  mknod $loop b 7 $i
	  losetup $loop $supersuimg
	  mount -t ext4 -o loop $loop /su; 2>/dev/null
    done
  fi
fi

# AUDIO EFFECTS
CONFIG_FILE=$SYS/etc/audio_effects.conf
HTC_CONFIG_FILE=$SYS/etc/htc_audio_effects.conf
OTHER_V_FILE=$SYS/etc/audio_effects_vendor.conf
OFFLOAD_CONFIG=$SYS/etc/audio_effects_offload.conf
V_CONFIG_FILE=$VEN/etc/audio_effects.conf
# AUDIO POLICY
A2DP_AUD_POL=$SYS/etc/a2dp_audio_policy_configuration.xml
AUD_POL=$SYS/etc/audio_policy.conf
AUD_POL_CONF=$SYS/etc/audio_policy_configuration.xml
AUD_POL_VOL=$SYS/etc/audio_policy_volumes.xml
SUB_AUD_POL=$SYS/etc/r_submix_audio_policy_configuration.xml
USB_AUD_POL=$SYS/etc/usb_audio_policy_configuration.xml
V_AUD_OUT_POL=$VEN/etc/audio_output_policy.conf
V_AUD_POL=$VEN/etc/audio_policy.conf
# MIXER PATHS
MIX_PATH=$SYS/etc/mixer_paths.xml
MIX_PATH_DTP=$SYS/etc/mixer_paths_dtp.xml
MIX_PATH_i2s=$SYS/etc/mixer_paths_i2s.xml
MIX_PATH_TASH=$SYS/etc/mixer_paths_tasha.xml
STRIGG_MIX_PATH=$SYS/sound_trigger_mixer_paths.xml
STRIGG_MIX_PATH_9330=$SYS/sound_trigger_mixer_paths_wcd9330.xml
V_MIX_PATH=$VEN/etc/mixer_paths.xml

# DETERMINE ROOT BOOT SCRIPT TYPE
EXT=".sh"
AMLPATH=""
MAGISK=false
if [ -f /data/magisk.img ] || [ -f /cache/magisk.img ] || [ -d /magisk ]; then
  MAGISK=true
  SEINJECT=magiskpolicy
  test -d /magisk/audmodlib$SYS && { MAGISK=true; AMLPATH=/magisk/audmodlib; }
elif [ "$supersuimg" ] || [ -d /su ]; then
  SEINJECT=/su/bin/supolicy
elif [ -d $SYS/su ] || [ -f $SYS/xbin/daemonsu ] || [ -f $SYS/xbin/sugote ]; then
  SEINJECT=$SYS/xbin/supolicy
elif [ -f $SYS/xbin/su ]; then
  if [ "$(cat $SYS/xbin/su | grep SuperSU)" ]; then
    SEINJECT=$SYS/xbin/supolicy
  else
    SEINJECT=/sepolicy
    EXT=""
  fi
else
  SEINJECT=/sepolicy
  EXT=""
fi

test -d $SYS/priv-app && SOURCE=priv_app || SOURCE=system_app

$SEINJECT --live "allow audioserver audioserver_tmpfs file { read write execute }" \
"allow audioserver system_file file { execmod }" \
"allow mediaserver mediaserver_tmpfs file { read write execute }" \
"allow mediaserver system_file file { execmod }" \
"allow $SOURCE init unix_stream_socket { connectto }" \
"allow $SOURCE property_socket sock_file { getattr open read write execute }"

$SEINJECT --live "permissive $SOURCE audio_prop"

# MOD PATCHES

for MOD in ${MODIDS}; do
  sed -i "/magisk\/${MOD}/,/fi #${MOD}/d" $SH/service$EXT
done

test -f "$LOG_FILE" && rm -f $LOG_FILE

echo "Audmodlib service script ($SH/service$EXT) has run successfully $(date +"%m-%d-%Y %H:%M:%S")" | tee -a $LOG_FILE
