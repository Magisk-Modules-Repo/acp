$MAGISK || { for FILE in ${POLS}; do
  if [ ! -z $XML ]; then
    [ "$(basename $FILE)" != "audio_policy_configuration.xml" ] && continue
    cp_ch $ORIGDIR$FILE $UNITY$FILE
    sed -ri '/<mixPort name="(deep_buffer)|(raw)"/,/<\/mixPort>/ {s|( *)<!--(.*flags=".*".*)-->|\1\2|; /flags="AUDIO_OUTPUT_FLAG_FAST"/d}' $UNITY$FILE
  else
    cp_ch $ORIGDIR$FILE $UNITY$FILE
    sed -i "/^# *raw {/,/}/ s/^#//" $UNITY$FILE
    sed -i "/^# *deep_buffer {/,/}/ s/^#//" $UNITY$FILE
  fi
done }
