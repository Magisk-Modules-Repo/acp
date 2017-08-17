#!/sbin/sh
# 
# /system/addon.d/udbr.sh
#

. /tmp/backuptool.functions

#### v INSERT YOUR CONFIG.SH MODID v ####
MODID=udbr
AUDMODLIBID=audmodlib
#### ^ INSERT YOUR CONFIG.SH MODID ^ ####

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

if [ $isABDevice == true ] || [ ! -d $SYS/vendor ]; then
  VEN=/vendor
else
  VEN=$SYS/vendor
fi

### FILE LOCATIONS ###
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
      backup_file $S/$FILE
    done
  ;;
  restore)
    list_files | while read FILE REPLACEMENT; do
      R=""
      [ -n "$REPLACEMENT" ] && R="$S/$REPLACEMENT"
      [ -f "$C/$S/$FILE" ] && restore_file $S/$FILE $R
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
    #### v INSERT YOUR BACKUP FUNCTIONS v ####
    # BACKUP CONFIGS
    for BACKUP in $A2DP_AUD_POL $AUD_POL $AUD_POL_CONF $AUD_POL_VOL $SUB_AUD_POL $USB_AUD_POL $V_AUD_OUT_POL $V_AUD_POL; do
      if [ -f $BACKUP ]; then
        cp -f $BACKUP $BACKUP.bak
      fi
    done
	#### ^ INSERT YOUR BACKUP FUNCTIONS ^ ####

    #### v INSERT YOUR FILE PATCHES v ####
    # REMOVE DEEP_BUFFER LINES
    if [ -f $V_AUD_OUT_POL ] && [ -f $AUD_POL_CONF ]; then
      # REMOVE DEEP_BUFFER
      sed -i '/Speaker/{n;s/deep_buffer,//;}' $AUD_POL_CONF
    elif [ ! -f $V_AUD_OUT_POL ] && [ -f $AUD_POL_CONF ]; then
      # REMOVE DEEP_BUFFER
      sed -i 's/deep_buffer,//g' $AUD_POL_CONF
      sed -i 's/,deep_buffer//g' $AUD_POL_CONF
    else
      for CFG in $A2DP_AUD_POL $AUD_POL $AUD_POL_CONF $AUD_POL_VOL $SUB_AUD_POL $USB_AUD_POL $V_AUD_OUT_POL $V_AUD_POL; do
        if [ -f $CFG ]; then
          # REMOVE DEEP_BUFFER
          sed -i '/deep_buffer {/,/}/d' $CFG
        fi
      done
    fi
    #### ^ INSERT YOUR FILE PATCHES ^ ####
  ;;
esac
