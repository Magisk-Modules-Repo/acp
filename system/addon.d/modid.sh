#!/sbin/sh
#
. /tmp/backuptool.functions
MODID=<MODID>
AMLID=audmodlib

# DETERMINE IF PIXEL (A/B OTA) DEVICE
ABDeviceCheck=$(cat /proc/cmdline | grep slot_suffix | wc -l)
if [ "$ABDeviceCheck" -gt 0 ]; then
  isABDevice=true
  if [ -d "/system_root" ]; then
    ROOT=/system_root
    SYS=$ROOT/system
  else
    ROOT=""
    SYS=$ROOT/system/system
  fi
else
  isABDevice=false
  ROOT=""
  SYS=$ROOT/system
fi
test -L /system/vendor && VEN=/vendor || VEN=/system/vendor

# DETERMINE SCRIPTS LOCATIONS
if [ -d "/data/adb/su/bin" ]; then
  SH=/data/adb/su/su.d
elif [ -d "/data/supersu_install/bin" ]; then
  SH=/data/supersu_install/su.d
elif [ -d "/cache/supersu_install/bin" ]; then
  SH=/cache/supersu_install/su.d
elif [ "$supersuimg" ] || [ -d /su ]; then
  SH=/su/su.d
elif [ -d $SYS/su ] || [ -f $SYS/xbin/daemonsu ] || [ -f $SYS/xbin/sugote ]; then
  SH=$SYS/su.d
elif [ -f $SYS/xbin/su ]; then
  if [ "$(grep "SuperSU" $SYS/xbin/su)" ]; then
    SH=$SYS/su.d
  else
    SH=$SYS/etc/init.d
  fi
else
  SH=$SYS/etc/init.d
fi

### FILE LOCATIONS ###
# XMLSTARLET
if [ "${SH%/*}" != "$SYS/etc" ]; then
  XML_PRFX=$AMLPATH${SH%/*}/xbin/xmlstarlet
else
  XML_PRFX=$AMLPATH$SYS/xbin/xmlstarlet
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
MIX_PATH_TASH=$SYS/etc/mixer_paths_tasha.xml
STRIGG_MIX_PATH=$SYS/sound_trigger_mixer_paths.xml
STRIGG_MIX_PATH_9330=$SYS/sound_trigger_mixer_paths_wcd9330.xml
V_MIX_PATH=$VEN/etc/mixer_paths.xml

list_files() {
cat <<EOF
$(cat /tmp/addon.d/$MODID-files)
EOF
}

case "$1" in
  backup)
    list_files | while read FILE DUMMY; do
      backup_file $FILE
    done
  ;;
  restore)
    list_files | while read FILE REPLACEMENT; do
      R=""
      [ -n "$REPLACEMENT" ] && R="$REPLACEMENT"
      [ -f "$C/$FILE" ] && restore_file $FILE $R
    done
  ;;
  pre-backup)
    # Stub
  ;;
  post-backup)
    # Stub
  ;;
  pre-restore)
    # Stub
  ;;
  post-restore)
    <PATCHES>
  ;;
esac
