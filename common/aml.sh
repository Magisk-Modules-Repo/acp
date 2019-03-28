[ -f "$MODULEROOT/acp/system/bin/xmlstarlet" ] && alias xmlstarlet=$MODULEROOT/acp/system/bin/xmlstarlet


osp_detect_notification() {
  case $1 in
    *.conf) local SPACES=$(sed -n "/^output_session_processing {/,/^}/ {/^ *notification {/p}" $1 | sed -r "s/( *).*/\1/")
            local EFFECTS=$(sed -n "/^output_session_processing {/,/^}/ {/^$SPACES\notification {/,/^$SPACES}/p}" $1 | grep -E "^$SPACES +[A-Za-z]+" | sed -r "s/( *.*) .*/\1/g")
            for EFFECT in ${EFFECTS}; do
              SPACES=$(sed -n "/^effects {/,/^}/ {/^ *$EFFECT {/p}" $1 | sed -r "s/( *).*/\1/")
              sed -i "/^effects {/,/^}/ {/^$SPACES$EFFECT {/,/^$SPACES}/ s/^/#/g}" $1
            done;;
     *.xml) local EFFECTS=$(sed -n "/^ *<postprocess>$/,/^ *<\/postprocess>$/ {/^ *<stream type=\"notification\">$/,/^ *<\/stream>$/ {/<stream type=\"notification\">/d; /<\/stream>/d; s/<apply effect=\"//g; s/\"\/>//g; p}}" $1)
            for EFFECT in ${EFFECTS}; do
              sed -ri "s/^( *)<apply effect=\"$EFFECT\"\/>/\1<\!--<apply effect=\"$EFFECT\"\/>-->/" $1
            done;;
  esac
}

patch_xml() {
  if [ "$(xmlstarlet sel -t -m "$2" -c . $1)" ]; then
    [ "$(xmlstarlet sel -t -m "$2" -c . $1 | sed -r "s/.*samplingRates=\"([0-9]*)\".*/\1/")" == "48000" ] && return
    xmlstarlet ed -L -u "$2/@samplingRates" -v "48000" $1
  else
    local NP=$(echo "$2" | sed -r "s|(^.*)/.*$|\1|")
    local SNP=$(echo "$2" | sed -r "s|(^.*)\[.*$|\1|")
    local SN=$(echo "$2" | sed -r "s|^.*/.*/(.*)\[.*$|\1|")
    xmlstarlet ed -L -s "$NP" -t elem -n "$SN-$MODID" -i "$SNP-$MODID" -t attr -n "name" -v "" -i "$SNP-$MODID" -t attr -n "format" -v "AUDIO_FORMAT_PCM_16_BIT" -i "$SNP-$MODID" -t attr -n "samplingRates" -v "48000" -i "$SNP-$MODID" -t attr -n "channelMasks" -v "AUDIO_CHANNEL_OUT_STEREO" $1
    xmlstarlet ed -L -r "$SNP-$MODID" -v "$SN" $1
  fi
}

osp_detect_notification $MODPATH/$NAME

RUNONCE=true
PATCH=false
USB=false
REMV=false
if $PATCH; then
  for FILE in ${FILES}; do
    NAME=$(echo "$FILE" | sed "s|$MOD|system|")
    case $NAME in
      *audio_*policy*.xml) sed -ri "/<mixPort name=\"(deep_buffer)|(low_latency)\"/,/<\/mixPort> *$/ s|flags=\"[^\"]*|flags=\"AUDIO_OUTPUT_FLAG_NONE|" $MODPATH/$NAME
                           sed -i "/<mixPort name=\"raw\"/,/<\/mixPort> *$/ s|flags=\"[^\"]*|flags=\"AUDIO_OUTPUT_FLAG_FAST|" $MODPATH/$NAME
                           sed -i "/<mixPort name=\"primary-out\"/,/<\/mixPort> *$/ s/|AUDIO_OUTPUT_FLAG_DEEP_BUFFER//; s/AUDIO_OUTPUT_FLAG_DEEP_BUFFER|//" $MODPATH/$NAME;;
      *audio_*policy*.conf) sed -ri "/^ *(deep_buffer)|(low_latency) \{/,/}/ s|flags .*|flags AUDIO_OUTPUT_FLAG_NONE|" $MODPATH/$NAME
                            sed -i "/^ *raw {/,/}/ s|flags .*|flags AUDIO_OUTPUT_FLAG_PRIMARY|" $MODPATH/$NAME
                            sed -i "/^ *primary {/,/}/ s/|AUDIO_OUTPUT_FLAG_DEEP_BUFFER//; s/AUDIO_OUTPUT_FLAG_DEEP_BUFFER|//" $MODPATH/$NAME;;
    esac
  done
fi
if $REMV; then
  for FLAG in "deep_buffer" "raw" "low_latency"; do
    if [ -f $MODPATH/system/vendor/etc/audio_output_policy.conf ] && [ -f $MODPATH/system/etc/audio_policy_configuration.xml ]; then
      for BUFFER in "Earpiece" "Speaker" "Wired Headset" "Wired Headphones" "Line" "HDMI" "Proxy" "FM" "BT SCO All" "USB Device Out" "Telephony Tx" "voice_rx" "primary input" "surround_sound" "record_24" "BT A2DP Out" "BT A2DP Headphones" "BT A2DP Speaker"; do
        sed -i "/$BUFFER/ s/$FLAG//g" $MODPATH/system/etc/audio_policy_configuration.xml
      done
    elif [ ! -f $MODPATH/system/vendor/etc/audio_output_policy.conf ] && [ -f $MODPATH/system/etc/audio_policy_configuration.xml ]; then
      sed -i "s/$FLAG,//g" $MODPATH/system/etc/audio_policy_configuration.xml
      sed -i "s/,$FLAG//g" $MODPATH/system/etc/audio_policy_configuration.xml
    elif [ -f $MODPATH/system/vendor/etc/audio/audio_policy_configuration.xml ]; then
      sed -i "s/$FLAG,//g" $MODPATH/system/vendor/etc/audio/audio_policy_configuration.xml
      sed -i "s/,$FLAG//g" $MODPATH/system/vendor/etc/audio/audio_policy_configuration.xml
    else
      for FILE in ${FILES}; do
        NAME=$(echo "$FILE" | sed "s|$MOD|system|")
        case $NAME in
          *audio_*policy*.conf) sed -i "/$FLAG {/,/}/d" $MODPATH/$NAME;;
          *audio_*policy*.xml) sed -i "/$FLAG {/,/}/d" $MODPATH/$NAME
                               sed -i "s/$FLAG,//g" $MODPATH/$NAME
                               sed -i "s/,$FLAG//g" $MODPATH/$NAME;;
        esac
      done
    fi
  done
fi

if $USB; then
  if [ "$(find $MODPATH/system -type f -name "usb_audio_policy_configuration.xml")" ]; then
    for FILE in $(find $MODPATH/system -type f -name "usb_audio_policy_configuration.xml"); do
      grep -iE " name=\"usb[ _]+.* output\"" $FILE | sed -r "s/.*ame=\"([A-Za-z_ ]*)\".*/\1/" | while read i; do
        patch_xml $FILE "/module/mixPorts/mixPort[@name=\"$i\"]/profile[@name=\"\"]"
      done
      grep -iE "tagName=\"usb[ _]+.* out\"" $FILE | sed -r "s/.*ame=\"([A-Za-z_ ]*)\".*/\1/" | while read i; do
        patch_xml $FILE "/module/devicePorts/devicePort[@tagName=\"$i\"]/profile[@name=\"\"]"
      done
    done
  else
    for FILE in $(find $MODPATH/system -type f -name "*audio_*policy*.conf"); do
      SPACES=$(sed -n "/^ *usb {/p" $FILE | sed -r "s/^( *).*/\1/")
      sed -i "/^$SPACES\usb {/,/^$SPACES}/ s/\(^ *\)sampling_rates .*/\1sampling_rates 48000/g" $FILE
    done
  fi
fi
