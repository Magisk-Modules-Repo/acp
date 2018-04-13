if ! $MAGISK; then
  if [ "$MODID" == "Udb_Remover" ]; then
    if [ -f $UNITY$VEN/etc/audio_output_policy.conf ] && [ -f $UNITY$SYS/etc/audio_policy_configuration.xml ]; then
      for BUFFER in "Speaker" "Wired Headset" "Wired Headphones"; do
        NUM=$(cat -n $UNITY$SYS/etc/audio_policy_configuration.xml | sed -n "/$BUFFER/ {n;n;/deep_buffer,/p}" | sed "s/<!--.*//")
        NUM=$((NUM-1))
        sed -i "${NUM}d" $UNITY$SYS/etc/audio_policy_configuration.xml
        sed -ri "/$BUFFER/ {n;/deep_buffer,/ s/<!--(.*)-->/\1/g}" $UNITY$SYS/etc/audio_policy_configuration.xml
      done
    elif [ ! -f $UNITY$VEN/etc/audio_output_policy.conf ] && [ -f $UNITY$SYS/etc/audio_policy_configuration.xml ] && [ "$(grep "<!--.*deep_buffer" $UNITY$SYS/etc/audio_policy_configuration.xml)" ]; then
      sed -ri -n "/( *)<!--(.*)deep_buffer/{x;d;};1h;1!{x;p;};\${x;p;}" $UNITY$SYS/etc/audio_policy_configuration.xml
      sed -ri "/deep_buffer/ s/<!--(.*)-->/\1/g" $UNITY$SYS/etc/audio_policy_configuration.xml
    elif [ -f $VEN/etc/audio/audio_policy_configuration.xml ]; then
      sed -ri -n "/( *)<!--(.*)deep_buffer/{x;d;};1h;1!{x;p;};\${x;p;}" $UNITY$VEN/etc/audio/audio_policy_configuration.xml
      sed -ri "/deep_buffer/ s/<!--(.*)-->/\1/g" $UNITY$VEN/etc/audio/audio_policy_configuration.xml
    else
      for OFILE in ${POLS}; do
        FILE="$UNITY$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
        case $FILE in
          *.conf) sed -i "/deep_buffer {/,/}/ s/^#//" $FILE;;
          *.xml) sed -i "/<!--deep_buffer {/,/}-->/ s/<!--deep_buffer/deep_buffer/g; s/}-->/}/g" $FILE;;
        esac 
      done
    fi
  else
    for OFILE in ${POLS}; do
      FILE="$UNITY$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
      case $FILE in
        *.xml) sed -ri "/<mixPort name=\"(deep_buffer)|(raw)|(low_latency)\"/,/<\/mixPort>/ {/<!--/!{/flags=\"AUDIO_OUTPUT_FLAG_.*\"/d}; s|( *)<!--(.*flags=\".*\".*)$MODID-->|\1\2|}" $FILE;;
        *.conf) sed -ri "/^ *(deep_buffer)|(raw)|(low_latency) \{/,/}/ {/^ *flags AUDIO_OUTPUT_FLAG_.*$/d; s|#$MODID||}" $FILE;;
      esac
    done
  fi
fi
