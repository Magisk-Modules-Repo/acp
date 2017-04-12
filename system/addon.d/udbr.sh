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
  SYSTEM=/system/system
  VENDOR=/vendor
else
  isABDevice=false
  SYSTEM=/system
  VENDOR=/system/vendor
fi

### FILE LOCATIONS ###
# AUDIO EFFECTS
CONFIG_FILE=$SYSTEM/etc/audio_effects.conf
HTC_CONFIG_FILE=$SYSTEM/etc/htc_audio_effects.conf
OTHER_V_FILE=$SYSTEM/etc/audio_effects_vendor.conf
OFFLOAD_CONFIG=$SYSTEM/etc/audio_effects_offload.conf
V_CONFIG_FILE=$VENDOR/etc/audio_effects.conf
# AUDIO POLICY
A2DP_AUD_POL=$SYSTEM/etc/a2dp_audio_policy_configuration.xml
AUD_POL=$SYSTEM/etc/audio_policy.conf
AUD_POL_CONF=$SYSTEM/etc/audio_policy_configuration.xml
AUD_POL_VOL=$SYSTEM/etc/audio_policy_volumes.xml
SUB_AUD_POL=$SYSTEM/etc/r_submix_audio_policy_configuration.xml
USB_AUD_POL=$SYSTEM/etc/usb_audio_policy_configuration.xml
V_AUD_OUT_POL=$VENDOR/etc/audio_output_policy.conf
V_AUD_POL=$VENDOR/etc/audio_policy.conf
# MIXER PATHS
MIX_PATH=$SYSTEM/etc/mixer_paths.xml
MIX_PATH_TASH=$SYSTEM/etc/mixer_paths_tasha.xml
STRIGG_MIX_PATH=$SYSTEM/sound_trigger_mixer_paths.xml
STRIGG_MIX_PATH_9330=$SYSTEM/sound_trigger_mixer_paths_wcd9330.xml
V_MIX_PATH=$VENDOR/etc/mixer_paths.xml

########## v DO NOT REMOVE v ##########
if [ -d $SYSTEM/priv-app ]; then
  APPDIR=priv-app
else
  APPDIR=app
fi
########## ^ DO NOT REMOVE ^ ##########

#### v INSERT MORE APPS IF MORE EXIST v ####
if [ "$API" -ge "21" ]; then
  APPTXT="   Installing apps for Lollipop and above..."
  APP1PATH=$APPDIR/$APP1
  APP2PATH=$APPDIR/$APP2
else
  APPTXT="   Installing apps for Lollipop and below..."
  APP1PATH=$APPDIR
  APP2PATH=$APPDIR
fi
#### ^ INSERT MORE APPS IF MORE EXIST ^ ####

list_files() {
cat <<EOF
addon.d/$AUDMODLIBID.sh
etc/init.d/$AUDMODLIBID
su.d/$AUDMODLIBID.sh
su/su.d/$AUDMODLIBID.sh
EOF
}

case "$1" in
  backup)
    list_files | while read FILE DUMMY; do
      backup_file $S/$FILE
    done
  ;;
  restore)+
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
