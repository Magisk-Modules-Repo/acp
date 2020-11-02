# Functions
patch_xml() {
  if [ "$(xmlstarlet sel -t -m "$2" -c . $1)" ]; then
    xmlstarlet ed -L -u "$2/@samplingRates" -v "48000" $1
  else
    local NP=$(echo "$2" | sed -r "s|(^.*)/.*$|\1|")
    local SNP=$(echo "$2" | sed -r "s|(^.*)\[.*$|\1|")
    local SN=$(echo "$2" | sed -r "s|^.*/.*/(.*)\[.*$|\1|")
    xmlstarlet ed -L -s "$NP" -t elem -n "$SN-acp" -i "$SNP-acp" -t attr -n "name" -v "" -i "$SNP-acp" -t attr -n "format" -v "AUDIO_FORMAT_PCM_16_BIT" -i "$SNP-acp" -t attr -n "samplingRates" -v "48000" -i "$SNP-acp" -t attr -n "channelMasks" -v "AUDIO_CHANNEL_OUT_STEREO" $1
    xmlstarlet ed -L -r "$SNP-acp" -v "$SN" $1
  fi
}

osp_detect_notification() {
  case $1 in
    *.conf) local SPACES=$(sed -n "/^output_session_processing {/,/^}/ {/^ *notification {/p}" $1 | sed -r "s/( *).*/\1/")
            local EFFECTS=$(sed -n "/^output_session_processing {/,/^}/ {/^$SPACES\notification {/,/^$SPACES}/p}" $1 | grep -E "^$SPACES +[A-Za-z]+" | sed -r "s/( *.*) .*/\1/g")
            for EFFECT in ${EFFECTS}; do
              SPACES=$(sed -n "/^effects {/,/^}/ {/^ *$EFFECT {/p}" $1 | sed -r "s/( *).*/\1/")
              sed -i "/^effects {/,/^}/ {/^$SPACES$EFFECT {/,/^$SPACES}/d}" $1
            done;;
     *.xml) local EFFECTS=$(sed -n "/^ *<postprocess>$/,/^ *<\/postprocess>$/ {/^ *<stream type=\"notification\">$/,/^ *<\/stream>$/ {/<stream type=\"notification\">/d; /<\/stream>/d; s/<apply effect=\"//g; s/\"\/>//g; p}}" $1)
            for EFFECT in ${EFFECTS}; do
              sed -i "/^\( *\)<apply effect=\"$EFFECT\"\/>/d" $1
            done;;
  esac
}

# Variables
POLS="$(find /system /vendor -type f -name "*audio_*policy*.conf" -o -name "*audio_*policy*.xml")"
UPCS="$(find /system /vendor -type f -name "usb_audio_policy_configuration.xml")"
APS="$(find /system /vendor -type f -name "*audio_*policy*.conf")"
CFGS="$(find /system /vendor -type f -name "*audio_effects*.conf" -o -name "*audio_effects*.xml")"
if [ -d "$NVBASE/modules/nhr" ]; then
  ui_print " "
  ui_print "! Old Notification Helper Remover detected! Removing..."
  touch $NVBASE/modules/nhr/remove
fi
if [ -d "$NVBASE/modules/upp" ]; then
  ui_print " "
  ui_print "! Old USB Policy Patcher detected! Removing..."
  touch $NVBASE/modules/upp/remove
fi

# Tell user aml is needed if applicable
FILES=$(find $NVBASE/modules/*/system $MODULEROOT/*/system -type f -name "usb_audio_policy_configuration.xml" -o -name "*audio_*policy*.conf" -o -name "*audio_effects*.conf" -o -name "*audio_effects*.xml" 2>/dev/null)
if [ ! -z "$FILES" ] && [ ! "$(echo $FILES | grep '/aml/')" ]; then
  ui_print " "
  ui_print "   ! Conflicting audio mod found!"
  ui_print "   ! You will need to install !"
  ui_print "   ! Audio Modification Library !"
  sleep 3
fi

# Check for devices that need lib workaround
if device_check -m "google" || device_check -m "Essential Products" || device_check "mata" || device_check "jasmine" || device_check "star2lte" || device_check "z2_row"; then
  LIBWA=true
fi

PATCH=false; REMV=false; USB=false; NOTIF=false; VOLU=false
ui_print " "
ui_print "- Patch audio_policy?"
ui_print "  (Original acp logic - deep_buffer removal and stuff)"
ui_print "  Vol+ = yes, Vol- = no"
if chooseport; then
  ui_print " "
  ui_print " - Select Patch Method"
  ui_print "   Patch flags or remove sections?:"
  ui_print "   Vol Up = Patch (new logic)"
  ui_print "   Vol Down = Remove (old logic)"
  ui_print "   Only select Remove if patch doesn't work for you"
  if chooseport; then
    PATCH=true
  else
    REMV=true
  fi  
fi

ui_print " "
ui_print "- Remove notification_helper?"
ui_print "  Vol+ = yes, Vol- = no"
if chooseport; then
  ui_print " "
  ui_print " - Select Fix Method"
  ui_print "   Remove Notification Helper Effect or Volume Listener Library?:"
  ui_print "   Vol Up = Remove notification_helper effect"
  ui_print "   Vol Down = Remove volume listener library"
  ui_print "   Only select Remove library if removing effect doesn't work for you"
  if chooseport; then
    NOTIF=true
  else
    VOLU=true
  fi
fi  

ui_print " "
ui_print "- Would you like patch usb policy for usb dacs? -"
ui_print "  Vol+ = yes, Vol- = no"
chooseport && USB=true

if [ -z $LIBWA ]; then
  ui_print " "
  ui_print "- Use lib workaround?"
  ui_print " "
  ui_print "   Only choose yes if you're having issues"
  ui_print "   Vol+ = yes, Vol- = no (recommended)"
  if chooseport; then
    LIBWA=true
  else
    LIBWA=false
  fi
fi

# Lib fix for pixel 2's, 3's, essential phone, and others
if $LIBWA; then
  ui_print " "
  ui_print "   Applying lib workaround..."
  if [ -f $ORIGDIR/system/lib/libstdc++.so ] && [ ! -f $ORIGDIR/vendor/lib/libstdc++.so ]; then
    cp_ch $ORIGDIR/system/lib/libstdc++.so $MODPATH/system/vendor/lib/libstdc++.so
  elif [ -f $ORIGDIR/vendor/lib/libstdc++.so ] && [ ! -f $ORIGDIR/system/lib/libstdc++.so ]; then
    cp_ch $ORIGDIR/vendor/lib/libstdc++.so $MODPATH/system/lib/libstdc++.so
  fi
fi

# Add variables to aml script
for i in PATCH REMV USB NOTIF; do
  sed -i "s|$i=.*|$i=$(eval echo \$$i)|" $MODPATH/.aml.sh
done
cp_ch $MODPATH/common/addon/External-Tools/tools/$ARCH32/sed $MODPATH/tools/sed

ui_print " "
ui_print "   Patching existing audio policy files..."
if $PATCH; then
  ui_print "   Using patch logic"
  for OFILE in ${POLS}; do
    FILE="$MODPATH$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
    cp_ch $ORIGDIR$OFILE $FILE
    case $FILE in
      *.xml) sed -ri "/<mixPort name=\"(deep_buffer)|(low_latency)\"/,/<\/mixPort> *$/ s|flags=\"[^\"]*|flags=\"AUDIO_OUTPUT_FLAG_NONE|" $FILE
             sed -i "/<mixPort name=\"raw\"/,/<\/mixPort> *$/ s|flags=\"[^\"]*|flags=\"AUDIO_OUTPUT_FLAG_FAST|" $FILE
             sed -i "/<mixPort name=\"primary-out\"/,/<\/mixPort> *$/ s/|AUDIO_OUTPUT_FLAG_DEEP_BUFFER//g" $FILE;;
      *.conf) sed -ri "/^ *(deep_buffer)|(low_latency) \{/,/}/ s|flags .*|flags AUDIO_OUTPUT_FLAG_NONE|" $FILE
              sed -i "/^ *raw {/,/}/ s|flags .*|flags AUDIO_OUTPUT_FLAG_PRIMARY|" $FILE
              sed -i "/^ *primary {/,/}/ s/|AUDIO_OUTPUT_FLAG_DEEP_BUFFER//g" $FILE;;
    esac
  done
elif $REMV; then
  ui_print "   Using remove logic"
  for FLAG in "deep_buffer" "raw" "low_latency"; do
    if [ -f $ORIGDIR/vendor/etc/audio_output_policy.conf ] && [ -f $ORIGDIR/system/etc/audio_policy_configuration.xml ]; then
      [ -f $MODPATH/system/etc/audio_policy_configuration.xml ] || cp_ch $ORIGDIR/system/etc/audio_policy_configuration.xml $MODPATH/system/etc/audio_policy_configuration.xml
      for BUFFER in "Earpiece" "Speaker" "Wired Headset" "Wired Headphones" "Line" "HDMI" "Proxy" "FM" "BT SCO All" "USB Device Out" "Telephony Tx" "voice_rx" "primary input" "surround_sound" "record_24" "BT A2DP Out" "BT A2DP Headphones" "BT A2DP Speaker"; do
        sed -i "/$BUFFER/ s/$FLAG,//g" $MODPATH/system/etc/audio_policy_configuration.xml
      done
    elif [ ! -f $ORIGDIR/vendor/etc/audio_output_policy.conf ] && [ -f $ORIGDIR/system/etc/audio_policy_configuration.xml ]; then
      [ -f $MODPATH/system/etc/audio_policy_configuration.xml ] || cp_ch $ORIGDIR/system/etc/audio_policy_configuration.xml $MODPATH/system/etc/audio_policy_configuration.xml
      sed -ri "s/$FLAG,|,$FLAG//g" $MODPATH/system/etc/audio_policy_configuration.xml
    elif [ -f $ORIGDIR/vendor/etc/audio/audio_policy_configuration.xml ]; then
      [ -f $MODPATH/system/vendor/etc/audio/audio_policy_configuration.xml ] || cp_ch $ORIGDIR/vendor/etc/audio/audio_policy_configuration.xml $MODPATH/system/vendor/etc/audio/audio_policy_configuration.xml
      sed -ri "s/$FLAG,|,$FLAG//g" $MODPATH/system/vendor/etc/audio/audio_policy_configuration.xml
    else
      for OFILE in ${POLS}; do
        FILE="$MODPATH$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
        [ -f $FILE ] || cp_ch $ORIGDIR$OFILE $FILE
        case $FILE in
          *.conf) sed -i "/$FLAG {/,/}/d" $FILE;;
          *.xml) sed -ri "s/$FLAG,|,$FLAG//g" $FILE;;
        esac
      done
    fi
  done
fi

if $NOTIF; then
  ui_print " "
  ui_print "   Patching existing audio effects configs..."
  for OFILE in ${CFGS}; do
    FILE="$MODPATH$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
    cp_ch $ORIGDIR$OFILE $FILE
    osp_detect_notification $FILE
  done
fi

if $VOLU; then
  ui_print " "
  ui_print "   Removing volume listener library..."
  ui_print "   Note that AML is NOT needed for this"
  if $MAGISK; then
    for FILE in $(find $ORIGDIR/vendor/lib* -type f -name "libvolumelistener.so" 2>/dev/null); do
      mktouch $(echo $FILE | sed "s|$ORIGDIR/vendor|$MODPATH/system/vendor|")
    done
  else
    mv -f $FILE $FILE.bak
    echo -e "$FILE\n$FILE.bak" >> $INFO
  fi
  sleep 2
fi

if $USB; then
  ui_print " "
  ui_print "   Patching usb policy files..."
  if [ "$UPCS" ]; then
    cp_ch $MODPATH/common/addon/External-Tools/tools/$ARCH32/xmlstarlet $MODPATH/tools/xmlstarlet
    for OFILE in ${UPCS}; do
      FILE="$MODPATH$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
      cp_ch $ORIGDIR$OFILE $FILE
      grep -iE " name=\"usb[ _]+.* output\"" $FILE | sed -r "s/.*ame=\"([A-Za-z_ ]*)\".*/\1/" | while read i; do
        patch_xml $FILE "/module/mixPorts/mixPort[@name=\"$i\"]/profile[@name=\"\"]"
      done
      grep -iE "tagName=\"usb[ _]+.* out\"" $FILE | sed -r "s/.*ame=\"([A-Za-z_ ]*)\".*/\1/" | while read i; do
        patch_xml $FILE "/module/devicePorts/devicePort[@tagName=\"$i\"]/profile[@name=\"\"]"
      done
    done
  else
    for OFILE in ${APS}; do
      FILE="$MODPATH$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
      cp_ch $ORIGDIR$OFILE $FILE
      SPACES=$(sed -n "/^ *usb {/p" $FILE | sed -r "s/^( *).*/\1/")
      sed -i "/^$SPACES\usb {/,/^$SPACES}/ s/\(^ *\)sampling_rates .*/\1sampling_rates 48000/g" $FILE
    done
  fi
fi
