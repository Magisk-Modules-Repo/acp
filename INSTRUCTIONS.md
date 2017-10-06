To create your own unity/audmodlib mod, all of the files you need to modify are located in the common folder of this zip (other than the README.md and config.sh)
NOTE: MAKE SURE YOU LEAVE A BLANK LINE AT THE END OF EACH FILE
Further instructions are contained in each file

1. Add your mod info to module.prop
2. Place your files in their respective directories in the system folder (where they will be installed to)
 2a. For apps, place in system/app/APPNAME/APPNAME.apk
 2b. For vendor, just create the vendor folder in the system folder
3. Place your files in their respective directories in the data folder (where they will be installed to)\
 3a. Note that these files will always be installed to /data regardless of root method
4. Place any files that need conditionals (only installed in some circumstances) in the custom folder (can be placed however you want)
 4a. Place apps in custom/APPNAME/APPNAME.apk
5. Add your min android version and other variables to common/unity-uservariables.sh (more instructions are in the file)
 5a. Note the Audmodlib variable in this file. Uncomment it if you're making an audio module
6. Add any scripts you want run at boot (post-fs-data mode in magisk) to common/unity-scripts.sh
7. Modify the service.sh in common as you would with any other magisk module (most everything should be a late start, not post-fs-data)
 7a. If service is going to be used, set it's value to true in config.sh (THESE WILL BE INSTALLED AS REGULAR BOOT SCRIPTS IF NOT A MAGISK INSTALL)
8. Add any build props you want added into the unity-props.prop
9. Add any build props you want removed into the unity-props-remove.prop
10. Add any possibly conflicting files you want removed/wiped before install into the unity-file-wipe.sh
11. Add any config/policy/mixer patches you want added into the aml-patches.sh (audio module only)
 11a. Any patching of xml files with xmlstarlet should go into aml-xml-patches.sh
12. Add the removal of your patches into the aml-patches-remove.sh (audio module only)
 12a. Any removal patching of xml files with xmlstarlet should go into aml-xml-patches-rem.sh
13. Add any other config/policy/mixer patches you want removed/wiped (may conflict with your patches) before install into the aml-patches-wipe.sh (audio module only)
 13a. Any wipe patching of xml files with xmlstarlet should go into aml-xml-patches-wipe.sh
14. Add any custom permissions needed into config.sh (this will apply to both magisk and system installs) (default permissions is 755 for folders and 644 for files)
 14a. DON'T MODIFY ANY OTHER PARTS OF CONFIG.SH (this is different from normal magisk modules)
15. Add any custom install/uninstall logic to unity-customrules1.sh (follow the instructions inside)
 15a. This is where you would put your stuff for any custom files and whatever else isn't taken care of already

*NOTE FOR PATCHING: patches for audio_effects need to be put into both system/etc/audio_effects (CONFIG_FILE) and /vendor/etc/audio_effects (V_CONFIG_FILE)
*NOTE FOR XMLSTARLET: you may need to have the command write to a temporary files and then replace the original file with the temporary one for it to work
________________________________________________________________________________________________________________________________________________________________________

TIMEOFEXEC VALUES - when the customrules file will execute in the (un)installer script

0=File will not be run (default)
1=unity_mod_wipe
2=unity_mod_copy
3=aml_mod_patch
4=unity_uninstall

*HINT: If you have props you want set under certain conditions, have that customrule's TIMEOFEXEC=2. Example: unity_prop_copy $INSTALLER/common/customprops.prop
If you have props you want removed under certain conditions, have that customrule's TIMEOFEXEC=1. Example: unity_prop_remove $INSTALLER/common/customprops.prop
________________________________________________________________________________________________________________________________________________________________________

LIST OF VARIABLES AND FUNCTIONS USED BY INSTALLER - DON'T MAKE ANY VARIABLES OR FUNCTIONS WITH THESE NAMES

USABLE VARIABLES - You may need to call these variables for various stuff

INSTALLER              (Working directory of installer (origin of files to be installed)
SYS                    (Location of system folder)
VEN                    (Location of vendor folder)
MODID                  ('id' from module.prop unless overridden in uservariables)
AMLID                  (Equaled to 'audmodlib')
AMLPATH                (Install path for audio modification library files)
CONFIG_FILE            ($SYS/etc/audio_effects.conf)
HTC_CONFIG_FILE        ($SYS/etc/htc_audio_effects.conf)
OTHER_V_FILE           ($SYS/etc/audio_effects_vendor.conf)
OFFLOAD_CONFIG         ($SYS/etc/audio_effects_offload.conf)
V_CONFIG_FILE          ($VEN/etc/audio_effects.conf)
A2DP_AUD_POL           ($SYS/etc/a2dp_audio_policy_configuration.xml)
AUD_POL                ($SYS/etc/audio_policy.conf)
AUD_POL_CONF           ($SYS/etc/audio_policy_configuration.xml)
AUD_POL_VOL            ($SYS/etc/audio_policy_volumes.xml)
SUB_AUD_POL            ($SYS/etc/r_submix_audio_policy_configuration.xml)
USB_AUD_POL            ($SYS/etc/usb_audio_policy_configuration.xml)
V_AUD_OUT_POL          ($VEN/etc/audio_output_policy.conf)
V_AUD_POL              ($VEN/etc/audio_policy.conf)
MIX_PATH               ($SYS/etc/mixer_paths.xml)
MIX_PATH_DTP           ($SYS/etc/mixer_paths_dtp.xml)
MIX_PATH_i2s           ($SYS/etc/mixer_paths_i2s.xml)
MIX_PATH_TASH          ($SYS/etc/mixer_paths_tasha.xml)
STRIGG_MIX_PATH        ($SYS/sound_trigger_mixer_paths.xml)
STRIGG_MIX_PATH_9330   ($SYS/sound_trigger_mixer_paths_wcd9330.xml)
V_MIX_PATH             ($VEN/etc/mixer_paths.xml)
INFO                   (System installs only - corresponds to a file that will save the list of installed files and is how aml knows what needs removed during uninstall)
AMLINFO                (System installs only - same as INFO but for audio modification library files)
MAGISK                 (Set to 'true' if magisk is detected, 'false' otherwise - Useful for unity-scripts if you want parts to only run with/without magisk installs)
MK_PRFX                (Contains the proper mkdir command regardless of install method. Always use this instead of a manual mkdir command)
MK_SFFX                (Contains proper permissions for mkdir command regardless of install method. Always put this at end of any mkdir command)
CP_PRFX                (Contains the proper copy command regardless of install method. Always use this instead of a manual cp command)
CP_SFFX                (Contains proper permissions for cp command regardless of install method. Always put this at end of any cp command)
WP_PRFX                (Backs up and removes specified file/folder. Ex: wipe_ch /data/app/com.audlabs.viperfx-1)
XML_PRFX               (Location of xmlstarlet binary for patching xml files - use for patching xml files)
UNITY                  (Conatins proper location for mod regardless of install method - MODPATH for magisk installs)
EXT                    (Only applicable to unity-scripts. The extension for script files in $SH)
SH                     (Only applicable to unity-scripts. The directory in which the script is running)
SEINJECT               (Only applicable to unity-scripts Command for sepolicy setting, dynamically set depending on root method)
API                    (Taken from build.prop. Equal to the API version of the rom installed)
ABI                    (Taken from build.prop. Equal to the ABI number of the device)
ABI2                   (Taken from build.prop. Equal to the ABI2 number of the device)
ABILONG                (Taken from build.prop. Equal to the ABI version of the device))
MIUIVER                (Taken from build.prop. Equal to MIUI version of the rom)
ARCH                   (Equal to the cpu type of the device - equal to 'arm', 'arm64', or 'x86')
DRVARCH                (Set to 'NEON' if non x86 device, set to 'x86' otherwise)
IS64BIT                (Set to 'true' if 64 bit capable device is detected, set to 'false' otherwise)

USABLE FUNCTIONS - You may need to call these variables for various stuff

custom_app_install     (Installs apps to the proper directory - app or priv-app. Ex: custom_app_install ViPER4AndroidFX)
unity_prop_remove      (Removes all props in specified file from a common aml prop file. Ex: unity_prop_remove $INSTALLER/common/props.prop)
unity_prop_copy        (Adds all props in specified file to a common aml prop file. Ex: unity_prop_copy $INSTALLER/common/props.props)
ui_print               (Prints out message. Ex: ui_print "Audmodlib is awesome")
abort                  (Prints message, unmounts partitions, and exits installer with error code of 1. Ex: abort "!Error! Exiting installer!")
mktouch                (Creates an empty file and the directories for that file. Ex: mktouch $SYS/etc/exlib.so)
set_perm               (Only applicable to config.sh - see file for examples. Sets the permissions of the file)
set_perm_recursive     (Only applicable to config.sh - see file for examples. Sets the permissions of the folder and all files in it recurssively)

NOT USABLE VARIABLES - You'll have no need to use these, they're just listed for reference

BOOTMODE
OUTFD
ZIP
ABDeviceCheck
isABDevice
ACTION
SYSOVER
TMPDIR
MOUNTPATH
IMG
MAGISKBIN
supersuimg
TPARTMOD
VAR
NEW
SPECCHARS
CHARS
SPACES
TOTSPACE
WPAPP_PRFX
INPUT_FILE_WIPE
INPUT_PATCHES
INPUT_PATCHES_REM
INPUT_PATCHES_WIPE
INPUT_PROPS
INPUT_PROPS_REM
INPUT_VAR
INPUT_RULES
INPUT_SCRIPT
CP_PRFXAML
FILE
loop
SPACE
WRITE
FIL
NUMOFCUSTRULES
MODPATH
AUDMODLIB
TFILES
TVFILES
MOD_VER
AMLSCRIPT
APPTXT
OLDAPP
AMLPROP
NEWDIR
OLDPROP
PROP
PRESENT
LINE
MINAPI
MIN_VER
UPGRADE
MAGISK_VER_CODE
newSizeM
MAGISKLOOP
MOD
MODIDS
LOG_FILE
FD
REGEX
FILES
VARNAME
VALUES
DIR
BLOCK
BOOTIMAGE
FSTAB
SHA1
STOCKDUMP
OLD_PATH
OLD_LD_PATH
LD_LIBRARY_PATH
reqSizeM
SIZE
curUsedM
curSizeM
curFreeM

NOT USABLE FUNCTIONS - You'll have no need to use these, they're just listed for reference

supersu_is_mounted
supersuimg_mount
mod_exist
action_complete
magisk_install
system_install
aml_script_patch
custom_app_wipe
app_install_logic
script_install_logic
unity_mod_wipe
unity_mod_copy
unity_uninstall
aml_mod
aml_mod_patch
get_outfd
grep_prop
get_var
find_boot_image
migrate_boot_backup
sign_chromeos
is_mounted
patch_util_functions
remove_system_su
api_level_arch_detect
boot_actions
recovery_actions
recovery_cleanup
request_size_check
request_zip_size_check
image_size_check
require_new_magisk
require_new_api
sys_mk_ch
sys_cp_ch
sys_cpbak_ch
sys_rm_ch
sys_wipe_ch
sys_wipefol_ch
wipe_ch
xml_install
magisk_procedure_extras
standard_procedure
