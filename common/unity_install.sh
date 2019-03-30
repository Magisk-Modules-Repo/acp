patch_xml() {
  if [ "$(xmlstarlet sel -t -m "$2" -c . $1)" ]; then
    [ "$(xmlstarlet sel -t -m "$2" -c . $1 | sed -r "s/.*samplingRates=\"([0-9]*)\".*/\1/")" == "48000" ] && return
    xmlstarlet ed -L -i "$2" -t elem -n "$MODID" $1
    local LN=$(sed -n "/<$MODID\/>/=" $1)
    for i in ${LN}; do
      sed -i "$i d" $1
      sed -i "$i p" $1
      sed -ri "${i}s/(^ *)(.*)/\1<!--$MODID\2$MODID-->/" $1
      sed -i "$((i+1))s/$/<!--$MODID-->/" $1
    done
    xmlstarlet ed -L -u "$2/@samplingRates" -v "48000" $1
  else
    local NP=$(echo "$2" | sed -r "s|(^.*)/.*$|\1|")
    local SNP=$(echo "$2" | sed -r "s|(^.*)\[.*$|\1|")
    local SN=$(echo "$2" | sed -r "s|^.*/.*/(.*)\[.*$|\1|")
    xmlstarlet ed -L -s "$NP" -t elem -n "$SN-$MODID" -i "$SNP-$MODID" -t attr -n "name" -v "" -i "$SNP-$MODID" -t attr -n "format" -v "AUDIO_FORMAT_PCM_16_BIT" -i "$SNP-$MODID" -t attr -n "samplingRates" -v "48000" -i "$SNP-$MODID" -t attr -n "channelMasks" -v "AUDIO_CHANNEL_OUT_STEREO" $1
    xmlstarlet ed -L -r "$SNP-$MODID" -v "$SN" $1
    xmlstarlet ed -L -i "$2" -t elem -n "$MODID" $1
    local LN=$(sed -n "/<$MODID\/>/=" $1)
    for i in ${LN}; do
      sed -i "$i d" $1
      sed -ri "${i}s/$/<!--$MODID-->/" $1
    done 
  fi
  local LN=$(sed -n "/^ *<!--$MODID-->$/=" $1 | tac)
  for i in ${LN}; do
    sed -i "$i d" $1
    sed -ri "$((i-1))s/$/<!--$MODID-->/" $1
  done 
}

osp_detect_notification() {
  case $1 in
    *.conf) local SPACES=$(sed -n "/^output_session_processing {/,/^}/ {/^ *notification {/p}" $1 | sed -r "s/( *).*/\1/")
            local EFFECTS=$(sed -n "/^output_session_processing {/,/^}/ {/^$SPACES\notification {/,/^$SPACES}/p}" $1 | grep -E "^$SPACES +[A-Za-z]+" | sed -r "s/( *.*) .*/\1/g")
            for EFFECT in ${EFFECTS}; do
              SPACES=$(sed -n "/^effects {/,/^}/ {/^ *$EFFECT {/p}" $1 | sed -r "s/( *).*/\1/")
              sed -i "/^effects {/,/^}/ {/^$SPACES$EFFECT {/,/^$SPACES}/ s/^/#$MODID/g}" $1
            done;;
     *.xml) local EFFECTS=$(sed -n "/^ *<postprocess>$/,/^ *<\/postprocess>$/ {/^ *<stream type=\"notification\">$/,/^ *<\/stream>$/ {/<stream type=\"notification\">/d; /<\/stream>/d; s/<apply effect=\"//g; s/\"\/>//g; p}}" $1)
            for EFFECT in ${EFFECTS}; do
              sed -ri "s/^( *)<apply effect=\"$EFFECT\"\/>/\1<\!--$MODID<apply effect=\"$EFFECT\"\/>-->/" $1
            done;;
  esac
}

# Check if FLAGS are even present. If not, do removal since there's nothing to patch
PATCH=false
for FILE in ${POLS}; do
  case $FILE in
    *.xml) [ "$(grep 'flags="AUDIO_OUTPUT_FLAG' $FILE)" ] && { PATCH=true; break; };;
    *.conf) [ "$(grep 'flags AUDIO_OUTPUT_FLAG' $FILE)" ] && { PATCH=true; break; };;
  esac
done
# Get Rem/Pat from zipname
if $PATCH; then
  OIFS=$IFS; IFS=\|
  case $(echo $(basename $ZIPFILE) | tr '[:upper:]' '[:lower:]') in
    *nrem*) PATCH=true;;
    *rem*) REMV=true;;
  esac
  IFS=$OIFS
else
  ui_print " "
  ui_print "! No flags detected in policy files!"
  ui_print "! Using removal logic!"
fi
OIFS=$IFS; IFS=\|
case $(echo $(basename $ZIPFILE) | tr '[:upper:]' '[:lower:]') in
  *lib*) LIBWA=true;;
  *nlib*) LIBWA=false;;
  *notif*) NOTIF=true;;
  *volum*) VOLU=true;;
  *usb*) USB=true;;
esac
IFS=$OIFS

# Tell user aml is needed if applicable
if $MAGISK && ! $SYSOVER; then
  if $BOOTMODE; then LOC="$MOUNTEDROOT/*/system $MODULEROOT/*/system"; else LOC="$MODULEROOT/*/system"; fi
  FILES=$(find $LOC -type f -name "usb_audio_policy_configuration.xml" -o -name "*audio_*policy*.conf" -o -name "*audio_effects*.conf" -o -name "*audio_effects*.xml" 2>/dev/null)
  if [ ! -z "$FILES" ] && [ ! "$(echo $FILES | grep '/aml/')" ]; then
    ui_print " "
    ui_print "   ! Conflicting audio mod found!"
    ui_print "   ! You will need to install !"
    ui_print "   ! Audio Modification Library !"
    sleep 3
  fi
fi

# Check for devices that need lib workaround
if device_check "walleye" || device_check "taimen" || device_check "crosshatch" || device_check "blueline" || device_check "mata" || device_check "jasmine" || device_check "star2lte" || device_check "z2_row"; then
  LIBWA=true
fi

ui_print " "
if [ -z $PATCH ] || [ -z $REMV ]; then
  ui_print "  Do you want to skip audio_policy patching? (Original acp before became 3in1 module)"
  ui_print "  Vol+ = yes, Vol- = no"
  if $VKSEL; then
    PATCH=false
    REMV=false
  else
    ui_print "- Select Patch Method -"
    ui_print "   Patch flags or remove sections?:"
    ui_print "   Vol Up = Patch (new logic)"
    ui_print "   Vol Down = Remove (old logic)"
    ui_print "   Only select Remove if patch doesn't work for you"
    if $VKSEL; then
      PATCH=true
      REMV=false
    else
      PATCH=false
      REMV=true
    fi  
  fi
else
  ui_print "   Patching method specified in zipname!"
fi

ui_print " "
if [ -z $NOTIF ]; then
  ui_print "  Would you like to skip notification_helper remover?"
  ui_print "  Vol+ = yes, Vol- = no"
  if $VKSEL; then
    NOTIF=false
    VOLU=false
  else
    ui_print "- Select Fix Method -"
    ui_print "   Remove Notification Helper Effect or Volume Listener Library?:"
    ui_print "   Vol Up = Remove notification_helper effect"
    ui_print "   Vol Down = Remove volume listener library"
    ui_print "   Only select Remove library if removing effect doesn't work for you"
    if $VKSEL; then
      NOTIF=true
      VOLU=false
    else
      NOTIF=false
      VOLU=true
    fi
  fi  
else
  ui_print "   Fix method specified in zipname!"
fi

ui_print " "
if [ -z $USB ]; then
  ui_print "  Would you like to skip usb policy patching for usb dacs?"
  ui_print "  Vol+ = yes, Vol- = no"
  if $VKSEL; then
    USB=false
  else
    USB=true
  fi 
else
  ui_print "   USB specified in zipname!"
fi

ui_print " "
if [ -z $LIBWA ]; then
  ui_print " "
  ui_print " - Use lib workaround? -"
  ui_print " "
  ui_print "   Only choose yes if you're having issues"
  ui_print "   Vol+ = yes, Vol- = no (recommended)"
  if $VKSEL; then
    LIBWA=true
  else
    LIBWA=false
  fi
else
  ui_print "   Lib workaround option specified in zipname!"
fi

# Lib fix for pixel 2's, 3's, and essential phone
if $LIBWA; then
  ui_print "   Applying lib workaround..."
  if [ -f $ORIGDIR/system/lib/libstdc++.so ] && [ ! -f $ORIGVEN/lib/libstdc++.so ]; then
    cp_ch $ORIGDIR/system/lib/libstdc++.so $UNITY$VEN/lib/libstdc++.so
  elif [ -f $ORIGVEN/lib/libstdc++.so ] && [ ! -f $ORIGDIR/system/lib/libstdc++.so ]; then
    cp_ch $ORIGVEN/lib/libstdc++.so $UNITY/system/lib/libstdc++.so
  fi
fi

ui_print "   Patching existing audio policy files..."
if $PATCH; then
sed -i "s|PATCH=false|PATCH=true|" $TMPDIR/common/aml.sh
sed -i "s|patch=false|patch=true|" $TMPDIR/module.prop
  ui_print "   Using patch logic"
  for OFILE in ${POLS}; do
    FILE="$UNITY$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
    cp_ch -i $ORIGDIR$OFILE $FILE
    case $FILE in
      *.xml) for MIX in "deep_buffer" "raw" "low_latency" "primary-out"; do
               sed -ri "/<mixPort name=\"$MIX\"/,/<\/mixPort> *$/ {/flags=\"[^\"]*/p; s|( *)(.*flags=\"[^\"]*.*)|\1<!--\2$MODID-->|; s|-->$MODID-->|$MODID-->|}" $FILE
               if [ "$MIX" == "deep_buffer" -o $MIX == "low_latency" ]; then
                 sed -ri "/<mixPort name=\"$MIX\"/,/<\/mixPort> *$/ {/<!--/! {s|flags=\"[^\"]*|flags=\"AUDIO_OUTPUT_FLAG_NONE|}}" $FILE
               elif [ "$MIX" == "raw" ]; then
                 sed -i "/<mixPort name=\"$MIX\"/,/<\/mixPort> *$/ {/<!--/! {s|flags=\"[^\"]*|flags=\"AUDIO_OUTPUT_FLAG_FAST|}}" $FILE
               else
                 sed -i "/<mixPort name=\"$MIX\"/,/<\/mixPort> *$/ {/<!--/! {s/|AUDIO_OUTPUT_FLAG_DEEP_BUFFER//; s/AUDIO_OUTPUT_FLAG_DEEP_BUFFER|//}}" $FILE
               fi
             done;;
      *.conf) for MIX in "deep_buffer" "raw" "low_latency" "primary"; do
                sed -ri "/^ *$MIX \{/,/}/ {/flags .*$/p; s|( *flags .*$)|#$MODID\1|}" $FILE
                if [ "$MIX" == "deep_buffer" -o $MIX == "low_latency" ]; then
                  sed -i "/^ *$MIX {/,/}/ {/^ *flags .*$/ s|flags .*|flags AUDIO_OUTPUT_FLAG_NONE|}" $FILE
                elif [ "$MIX" == "raw" ]; then
                  sed -i "/^ *$MIX {/,/}/ {/^ *flags .*$/ s|flags .*|flags AUDIO_OUTPUT_FLAG_FAST|}" $FILE
                else
                  sed -i "/^ *$MIX {/,/}/ {/^ *flags .*$/ s/|AUDIO_OUTPUT_FLAG_DEEP_BUFFER//; s/AUDIO_OUTPUT_FLAG_DEEP_BUFFER|//}" $FILE
                fi
              done;;
    esac
  done
fi
if $REMV; then
sed -i "s|REMV=false|REMV=true|" $TMPDIR/common/aml.sh
sed -i "s|remv=false|remv=true|" $TMPDIR/module.prop
  ui_print "   Using remove logic"
  FIRST=true
  for FLAG in "deep_buffer" "raw" "low_latency"; do
    if [ -f $VEN/etc/audio_output_policy.conf ] && [ -f /system/etc/audio_policy_configuration.xml ]; then
      $FIRST && cp_ch -i $ORIGDIR/system/etc/audio_policy_configuration.xml $UNITY/system/etc/audio_policy_configuration.xml
      for BUFFER in "Earpiece" "Speaker" "Wired Headset" "Wired Headphones" "Line" "HDMI" "Proxy" "FM" "BT SCO All" "USB Device Out" "Telephony Tx" "voice_rx" "primary input" "surround_sound" "record_24" "BT A2DP Out" "BT A2DP Headphones" "BT A2DP Speaker"; do
        if [ "$(sed -n "/$BUFFER/ {n;/$FLAG,/ p}" $UNITY/system/etc/audio_policy_configuration.xml)" ] && [ ! "$(sed -n "/$BUFFER/ {n;n;/$FLAG,/p}" $UNITY/system/etc/audio_policy_configuration.xml)" ]; then
          $FIRST && { sed -i "/$BUFFER/ {n;/$FLAG,/ p}" $UNITY/system/etc/audio_policy_configuration.xml;
                      sed -ri "/$BUFFER/ {n;n;/$FLAG,/ s/( *)(.*)/\1<!--\2$MODID-->/}" $UNITY/system/etc/audio_policy_configuration.xml; }
          sed -i "/$BUFFER/{n;s/$FLAG,//;}" $UNITY/system/etc/audio_policy_configuration.xml
        fi
      done
    elif [ ! -f $VEN/etc/audio_output_policy.conf ] && [ -f /system/etc/audio_policy_configuration.xml ]; then
      $FIRST && { cp_ch -i $ORIGDIR/system/etc/audio_policy_configuration.xml $UNITY/system/etc/audio_policy_configuration.xml;
                  sed -ri "/($FLAG,|,$FLAG)/p" $UNITY/system/etc/audio_policy_configuration.xml;
                  sed -ri "/($FLAG,|,$FLAG)/{n;s/( *)(.*)$FLAG(.*)/\1<!--\2$FLAG\3$MODID-->/}" $UNITY/system/etc/audio_policy_configuration.xml; }
      sed -i "/<!--/!{/$FLAG,/ s/$FLAG,//g}" $UNITY/system/etc/audio_policy_configuration.xml
      sed -i "/<!--/!{/,$FLAG/ s/,$FLAG//g}" $UNITY/system/etc/audio_policy_configuration.xml
    elif [ -f $VEN/etc/audio/audio_policy_configuration.xml ]; then
      $FIRST && { cp_ch -i $ORIGDIR$VEN/etc/audio/audio_policy_configuration.xml $UNITY$VEN/etc/audio/audio_policy_configuration.xml;
                  sed -ri "/($FLAG,|,$FLAG)/p" $UNITY$VEN/etc/audio/audio_policy_configuration.xml;
                  sed -ri "/($FLAG,|,$FLAG)/{n;s/( *)(.*)$FLAG(.*)/\1<!--\2$FLAG\3$MODID-->/}" $UNITY$VEN/etc/audio/audio_policy_configuration.xml; }
      sed -i "/<!--/!{/$FLAG,/ s/$FLAG,//g}" $UNITY$VEN/etc/audio/audio_policy_configuration.xml
      sed -i "/<!--/!{/,$FLAG/ s/,$FLAG//g}" $UNITY$VEN/etc/audio/audio_policy_configuration.xml
    else
      for OFILE in ${POLS}; do
        FILE="$UNITY$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
        $FIRST && cp_ch -i $ORIGDIR$OFILE $FILE
        case $FILE in
          *.conf) if [ ! "$(grep "#$MODID *$FLAG" $FILE)" ] && [ "$(grep "^ *$FLAG" $FILE)" ]; then
                    sed -i "/$FLAG {/,/}/ s/^/#$MODID/" $FILE
                  fi;;
          *.xml) if [ ! "$(grep "<!--.*$FLAG" $FILE)" ]; then
                   sed -i "/$FLAG {/,/}/ s/$FLAG {/<!--$FLAG {/g; s/}/}$MODID-->/g" $FILE
                 fi
                $FIRST && { sed -ri "/($FLAG,|,$FLAG)/p" $FILE;
                            sed -ri "/($FLAG,|,$FLAG)/{n;s/( *)(.*)$FLAG(.*)/\1<!--\2$FLAG\3$MODID-->/}" $FILE; }
                sed -i "/<!--/!{/$FLAG,/ s/$FLAG,//g}" $FILE
                sed -i "/<!--/!{/,$FLAG/ s/,$FLAG//g}" $FILE
                ;;
        esac
      done
    fi
  FIRST=false
  done
fi

ui_print " "
if $NOTIF; then
  ui_print "   Patching existing audio effects configs..."
  for OFILE in ${CFGS}; do
    FILE="$UNITY$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
    cp_ch -i $ORIGDIR$OFILE $FILE
    osp_detect_notification $FILE
  done
fi

if $VOLU; then
  ui_print "   Removing volume listener library..."
  ui_print "   Note that AML is NOT needed for this"
  if $MAGISK; then
    for FILE in $(find $ORIGVEN/lib* -type f -name "libvolumelistener.so" 2>/dev/null); do
      mktouch $(echo $FILE | sed "s|$ORIGVEN|$MODPATH/system/vendor|")
    done
  else
    mv -f $FILE $FILE.bak
    echo -e "$FILE\n$FILE.bak" >> $INFO
  fi
  sleep 2
fi

if $USB; then
  ui_print "   Patching usb policy files..."
  if [ "$UPCS" ]; then
  cp_ch -n $UF/tools/$ARCH32/xmlstarlet $UNITY/system/bin/xmlstarlet
  sed -i "s|USB=false|USB=true|" $TMPDIR/common/aml.sh
  sed -i "s|usb=false|usb=true|" $TMPDIR/module.prop
    for OFILE in ${UPCS}; do
      FILE="$UNITY$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
      cp_ch -i $ORIGDIR$OFILE $FILE
      grep -iE " name=\"usb[ _]+.* output\"" $FILE | sed -r "s/.*ame=\"([A-Za-z_ ]*)\".*/\1/" | while read i; do
      patch_xml $FILE "/module/mixPorts/mixPort[@name=\"$i\"]/profile[@name=\"\"]"
      done
      grep -iE "tagName=\"usb[ _]+.* out\"" $FILE | sed -r "s/.*ame=\"([A-Za-z_ ]*)\".*/\1/" | while read i; do
      patch_xml $FILE "/module/devicePorts/devicePort[@tagName=\"$i\"]/profile[@name=\"\"]"
      done
    done
  else
    for OFILE in ${APS}; do
      FILE="$UNITY$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
      cp_ch -i $ORIGDIR$OFILE $FILE
      SPACES=$(sed -n "/^ *usb {/p" $FILE | sed -r "s/^( *).*/\1/")
      sed -i "/^$SPACES\usb {/,/^$SPACES}/ {/sampling_rates/p; s/\(^ *\)\(sampling_rates .*$\)/\1<!--$MODID\2$MODID-->/g;}" $FILE
      sed -i "/^$SPACES\usb {/,/^$SPACES}/ s/\(^ *\)sampling_rates .*/\1sampling_rates 48000<!--$MODID-->/g" $FILE
    done
  fi
fi

$MAGISK && ! $SYSOVER && cp_ch -i $TMPDIR/common/aml.sh $UNITY/.aml.sh
