##########################################################################################
#
# Unity Config Script
# by topjohnwu, modified by Zackptg5
#
##########################################################################################

##########################################################################################
# Installation Message - Don't change this
##########################################################################################

print_modname() {
  ui_print " "
  ui_print "    *******************************************"
  ui_print "    *<name>*"
  ui_print "    *******************************************"
  ui_print "    *<version>*"
  ui_print "    *<author>*"
  ui_print "    *******************************************"
  ui_print " "
}

##########################################################################################
# Defines
##########################################################################################

# Uncomment and change 'MINAPI' and 'MAXAPI' to the minimum and maxium android version for your mod (note that unity's minapi is 21 (lollipop) due to bash)
# Uncomment DYNAMICOREO if you want libs installed to vendor for oreo+ and system for anything older
# Uncomment SYSOVERRIDE if you want the mod to always be installed to system (even on magisk) - note that this can still be set to true by the user by adding 'sysover' to the zipname
# Uncomment DEBUG if you want full debug logs (saved to /sdcard in magisk manager and the zip directory in twrp) - note that this can still be set to true by the user by adding 'debug' to the zipname
#MINAPI=21
#MAXAPI=25
#SYSOVERRIDE=true
#DYNAMICOREO=true
#DEBUG=true

# Things that ONLY run during an upgrade (occurs after unity_custom) - you probably won't need this
# A use for this would be to back up app data before it's wiped if your module includes an app
# NOTE: the normal upgrade process is just an uninstall followed by an install
unity_upgrade() {
  : # Remove this if adding to this function
}

# Custom Variables - Keep everything within this function
unity_custom() {
  if $BOOTMODE; then
    POLS="$(find /system /vendor -type f -name "*audio_*policy*.conf" -o -name "*audio_*policy*.xml")"
  else  
    POLS="$(find -L /system -type f -name "*audio_*policy*.conf" -o -name "*audio_*policy*.xml")"
  fi
  # Remove old udbr
  if [ -f "$(echo $MOD_VER | sed "s/$MODID/Udb_Remover/g")" ]; then
    ui_print " "
    ui_print "! Old Udbr detected! Removing..."
    INFO=$(echo $INFO | sed "s/$MODID/Udb_Remover/g")
    MODPATH=$(echo $MODPATH | sed "s/$MODID/Udb_Remover/g")
    MODID="Udb_Remover"
    unity_uninstall
    MODID=`grep_prop id $INSTALLER/module.prop`
    INFO=$(echo $INFO | sed "s/Udb_Remover/$MODID/g")
    MODPATH=$MOUNTPATH/$MODID
  fi
}

# Custom Functions for Install AND Uninstall - You can put them here


##########################################################################################
# Replace list
##########################################################################################

# List all directories you want to directly replace in the system
# By default Magisk will merge your files with the original system
# Directories listed here however, will be directly mounted to the correspond directory in the system

# You don't need to remove the example below, these values will be overwritten by your own list
# This is an example
REPLACE="
/system/app/Youtube
/system/priv-app/SystemUI
/system/priv-app/Settings
/system/framework
"

# Construct your own list here, it will overwrite the example
# !DO NOT! remove this if you don't need to replace anything, leave it empty as it is now
REPLACE="
"

##########################################################################################
# Permissions
##########################################################################################

set_permissions() {
  : # Remove this if adding to this function

  # Note that all files/folders have the $UNITY prefix - keep this prefix on all of your files/folders
  # Also note the lack of '/' between variables - preceding slashes are already included in the variables
  # Use $VEN for vendor (Do not use /system$VEN, the $VEN is set to proper vendor path already - could be /vendor, /system/vendor, etc.)

  # Some examples:
  
  # For directories (includes files in them):
  # set_perm_recursive  <dirname>                <owner> <group> <dirpermission> <filepermission> <contexts> (default: u:object_r:system_file:s0)
  
  # set_perm_recursive $UNITY/system/lib 0 0 0755 0644
  # set_perm_recursive $UNITY$VEN/lib/soundfx 0 0 0755 0644

  # For files (not in directories taken care of above)
  # set_perm  <filename>                         <owner> <group> <permission> <contexts> (default: u:object_r:system_file:s0)
  
  # set_perm $UNITY/system/lib/libart.so 0 0 0644
}
