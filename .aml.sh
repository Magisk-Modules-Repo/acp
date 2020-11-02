#!/system/bin/sh
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

alias xmlstarlet="$mod/tools/xmlstarlet"
NOTIF=false
PATCH=false
REMV=false
USB=false
if $USB && [ ! -z "$(find $MODPATH/system -type f -name 'usb_audio_policy_configuration.xml')" ]; then
  USBFILE=true
else
  USBFILE=false
fi
FILES=$(find $MODPATH/system -type f)

for FILE in $FILES; do
  case $FILE in
    *audio_effects*) $NOTIF && osp_detect "notification" $FILE;;
    *audio_*policy*.xml) $PATCH || continue
                         sed -ri "/<mixPort name=\"(deep_buffer)|(low_latency)\"/,/<\/mixPort> *$/ s|flags=\"[^\"]*|flags=\"AUDIO_OUTPUT_FLAG_NONE|" $FILE
                         sed -i "/<mixPort name=\"raw\"/,/<\/mixPort> *$/ s|flags=\"[^\"]*|flags=\"AUDIO_OUTPUT_FLAG_FAST|" $FILE
                         sed -i "/<mixPort name=\"primary-out\"/,/<\/mixPort> *$/ s/|AUDIO_OUTPUT_FLAG_DEEP_BUFFER//g" $FILE;;
    *audio_*policy*.conf) if $PATCH; then
                            sed -ri "/^ *(deep_buffer)|(low_latency) \{/,/}/ s|flags .*|flags AUDIO_OUTPUT_FLAG_NONE|" $FILE
                            sed -i "/^ *raw {/,/}/ s|flags .*|flags AUDIO_OUTPUT_FLAG_PRIMARY|" $FILE
                            sed -i "/^ *primary {/,/}/ s/|AUDIO_OUTPUT_FLAG_DEEP_BUFFER//g" $FILE
                          fi
                          if $USB && ! $USBFILE; then
                            SPACES=$(sed -n "/^ *usb {/p" $FILE | sed -r "s/^( *).*/\1/")
                            sed -i "/^$SPACES\usb {/,/^$SPACES}/ s/\(^ *\)sampling_rates .*/\1sampling_rates 48000/g" $FILE
                          fi;;
    usb_audio_policy_configuration.xml) grep -iE " name=\"usb[ _]+.* output\"" $FILE | sed -r "s/.*ame=\"([A-Za-z_ ]*)\".*/\1/" | while read i; do
                                          patch_xml $FILE "/module/mixPorts/mixPort[@name=\"$i\"]/profile[@name=\"\"]"
                                        done
                                        grep -iE "tagName=\"usb[ _]+.* out\"" $FILE | sed -r "s/.*ame=\"([A-Za-z_ ]*)\".*/\1/" | while read i; do
                                          patch_xml $FILE "/module/devicePorts/devicePort[@tagName=\"$i\"]/profile[@name=\"\"]"
                                        done;;
  esac
done

if $REMV; then
  for FLAG in "deep_buffer" "raw" "low_latency"; do
    if [ -f $MODPATH/system/vendor/etc/audio_output_policy.conf ] && [ -f $MODPATH/system/etc/audio_policy_configuration.xml ]; then
      for BUFFER in "Earpiece" "Speaker" "Wired Headset" "Wired Headphones" "Line" "HDMI" "Proxy" "FM" "BT SCO All" "USB Device Out" "Telephony Tx" "voice_rx" "primary input" "surround_sound" "record_24" "BT A2DP Out" "BT A2DP Headphones" "BT A2DP Speaker"; do
        sed -i "/$BUFFER/ s/$FLAG//g" $MODPATH/system/etc/audio_policy_configuration.xml
      done
    elif [ ! -f $MODPATH/system/vendor/etc/audio_output_policy.conf ] && [ -f $MODPATH/system/etc/audio_policy_configuration.xml ]; then
      sed -ri "s/$FLAG,|,$FLAG//g" $MODPATH/system/etc/audio_policy_configuration.xml
    elif [ -f $MODPATH/system/vendor/etc/audio/audio_policy_configuration.xml ]; then
      sed -ri "s/$FLAG,|,$FLAG//g" $MODPATH/system/vendor/etc/audio/audio_policy_configuration.xml
    else
      for FILE in $FILES; do
        case $NAME in
          *audio_*policy*.conf) sed -i "/$FLAG {/,/}/d" $FILE;;
          *audio_*policy*.xml) sed -ri "s/$FLAG,|,$FLAG//g" $FILE;;
        esac
      done
    fi
  done
fi
