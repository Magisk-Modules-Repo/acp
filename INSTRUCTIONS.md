To create your own audmodlib mod, all of the files you need to modify are located in the common folder of this zip
NOTE: MAKE SURE YOU LEAVE A BLANK LINE AT THE END OF EACH FILE
Instructions are contained in each file

1. Place your files in their respective directories in the system folder
2. Modify config.sh as you would with any other magisk module
3. Modify the post-fs-data.sh and service.sh files in common as you would with any other magisk module (DO NOT USE system.prop, see steps 3-4 for instructions on props)
4. Add any build props you want added into the unity-props.prop
5. Add any build props you want removed into the unity-props-remove.prop
6. Add any files you want installed into the unity-files.sh
7. Add any files you want removed into the unity-file-remove.sh
8. Add any config/policy/mixer patches you want added into the unity-patches.sh
9. Add these config/policy/mixer patches into the unity-patches-remove.sh as well for the uninstall process
10. Add any config/policy/mixer patches you want wiped in the beginning on system installs in the unity-patches-wipe.sh
11. If your files include any apps/apks, follow the instructions in the unity-uservariables.sh
12. If adding any custom variables, add them to the unity-uservariables.sh
13. Rename the .sh file in common folder to your MODID-service and modify it as instructed in the file

________________________________________________________________________________________________________________________________________________________________________

AUDMODLIB VARIABLES (for reference)

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
# APP VARIABLE (each apk file in your file list will be a new app number, path will be dynamic based on device software)
APP1=
APPPATH1=
APP2=
APPPATH2=
# SYSTEM AND VENDOR VARIABLES
$SYS=
$VEN=
**$SYS and $VEN are dynamic variables for system and vendor depending on device
# OTHER DYNAMIC VARIABLES
INSTALLER=
MODID=
MAGISK=
MK_PRFX=
CP_PRFX=
RM_PRFX=
RMFOL_PRFX=
RMFOL_SFFX=
UNITY=
MK_SFFX=
CP_SFFX=
UNITYPATCH=
**These are set dynamically based on device some examples of use:

$CP_PRFX $INSTALLER/system/app/example.apk $UNITY$SYS/$APPPATH1/$APP1$CP_SFFX
$MK_SFFX $UNITY$SYS/$APPPATH1/$APP1$MK_SFFX

________________________________________________________________________________________________________________________________________________________________________

TIMEOFEXEC VALUES - when the customrules file will execute in the (un)installer script

0=File will not be run (default)
1=unity_prop_removal
2=unity_prop_copy
3=unity_mod_wipe
4=unity_mod_directory
5=unity_mod_copy
6=unity_mod_patch
7=unity_uninstall

*HINT: unity_prop_copy is called from the unity_mod_copy function. So if you have props you want set under certain conditions, have that customrules' TIMEOFEXEC=5