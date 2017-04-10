#!/system/bin/sh
# This script will be executed in late_start service mode
# More info in the main Magisk thread

#### v INSERT YOUR CONFIG.SH MODID v ####
MODID=udbr
#### ^ INSERT YOUR CONFIG.SH MODID ^ ####

########## v DO NOT REMOVE v ##########
rm -rf /cache/magisk/audmodlib

if [ ! -d /magisk/$MODID ]; then
  AUDMODLIBPATH=/magisk/audmodlib

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
  ########## ^ DO NOT REMOVE ^ ##########

  #### v INSERT YOUR REMOVE PATCH OR RESTORE v ####
  # RESTORE BACKED UP CONFIGS
  if [ -f $A2DP_AUD_POL.bak ] || [ -f $AUD_POL.bak ] || [ -f $AUD_POL_CONF.bak ] || [ -f $AUD_POL_VOL.bak ] || [ -f $SUB_AUD_POL.bak ] || [ -f $USB_AUD_POL.bak ] || [ -f $V_AUD_OUT_POL.bak ] || [ -f $V_AUD_POL.bak ]; then
    for RESTORE in $A2DP_AUD_POL $AUD_POL $AUD_POL_CONF $AUD_POL_VOL $SUB_AUD_POL $USB_AUD_POL $V_AUD_OUT_POL $V_AUD_POL; do
      if [ -f $RESTORE.bak ]; then
        cp -f $AUDMODLIBPATH$RESTORE.bak $AUDMODLIBPATH$RESTORE
      fi
    done
  fi
  #### ^ INSERT YOUR REMOVE PATCH OR RESTORE ^ ####

  rm -f /magisk/.core/service.d/$MODID.sh
  reboot
fi
