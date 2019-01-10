RUNONCE=true
PATCH=true
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
else
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
