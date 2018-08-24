if ! $MAGISK || $SYSOVERRIDE; then
  if $(grep_prop patch $MOD_VER); then
    for OFILE in ${POLS}; do
      FILE="$UNITY$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
      case $FILE in
        *.xml) for MIX in "deep_buffer" "raw" "low_latency" "primary-out"; do
                 sed -ri "/<mixPort name=\"$MIX\"/,/<\/mixPort>/ {/<!--/!{/flags=\"AUDIO_OUTPUT_FLAG_.*\"/d}; s|( *)<!--(.*flags=\".*\".*)$MODID-->|\1\2|}" $FILE
               done;;
        *.conf) for MIX in "deep_buffer" "raw" "low_latency" "primary"; do
                  sed -i "/^ *$MIX {/,/}/ {/^ *flags AUDIO_OUTPUT_FLAG_.*$/d; s|#$MODID||}" $FILE
                done;;
      esac
    done
  else
    for FLAG in "deep_buffer" "raw" "low_latency"; do
      if [ -f $UNITY$VEN/etc/audio_output_policy.conf ] && [ -f $UNITY$SYS/etc/audio_policy_configuration.xml ] && [ "$(grep "<!--.*$FLAG" $UNITY$SYS/etc/audio_policy_configuration.xml)" ]; then
        for BUFFER in "Speaker" "Wired Headset" "Wired Headphones"; do
          NUM=$(cat -n $UNITY$SYS/etc/audio_policy_configuration.xml | sed -n "/$BUFFER/ {n;n;/$FLAG,/p}" | sed "s/<!--.*//")
          NUM=$((NUM-1))
          sed -i "${NUM}d" $UNITY$SYS/etc/audio_policy_configuration.xml
          sed -ri "/$BUFFER/ {n;/$FLAG,/ s/<!--(.*)$MODID-->/\1/g}" $UNITY$SYS/etc/audio_policy_configuration.xml
        done
      elif [ ! -f $UNITY$VEN/etc/audio_output_policy.conf ] && [ -f $UNITY$SYS/etc/audio_policy_configuration.xml ] && [ "$(grep "<!--.*$FLAG" $UNITY$SYS/etc/audio_policy_configuration.xml)" ]; then
        sed -ri -n "/( *)<!--(.*)$FLAG/{x;d;};1h;1!{x;p;};\${x;p;}" $UNITY$SYS/etc/audio_policy_configuration.xml
        sed -ri "/$FLAG/ s/<!--(.*)$MODID-->/\1/g" $UNITY$SYS/etc/audio_policy_configuration.xml
      elif [ -f $VEN/etc/audio/audio_policy_configuration.xml ] && [ "$(grep "<!--.*$FLAG" $UNITY$VEN/etc/audio_policy_configuration.xml)" ]; then
        sed -ri -n "/( *)<!--(.*)$FLAG/{x;d;};1h;1!{x;p;};\${x;p;}" $UNITY$VEN/etc/audio/audio_policy_configuration.xml
        sed -ri "/$FLAG/ s/<!--(.*)$MODID-->/\1/g" $UNITY$VEN/etc/audio/audio_policy_configuration.xml
      else
        for OFILE in ${POLS}; do
          FILE="$UNITY$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
          case $FILE in
            *.conf) [ "$(grep "^#$MODID" $FILE)" ] && sed -i "/$FLAG {/,/}/ s/^#$MODID//" $FILE;;
            *.xml) [ "$(grep "<!--$FLAG" $FILE)" ] && sed -i "/<!--$FLAG {/,/}$MODID-->/ s/<!--$FLAG {/$FLAG {/g; s/}$MODID-->/}/g" $FILE;;
          esac
        done
      fi
    done
  fi
fi
