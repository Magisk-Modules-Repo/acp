$MAGISK || { for FILE in ${POLS}; do
  if [ ! -z $XML ]; then
    [ "$(basename $FILE)" != "audio_policy_configuration.xml" ] && continue
    cp_ch $ORIGDIR$FILE $UNITY$FILE
    sed -ri "/<mixPort name=\"(deep_buffer)|(raw)\"/,/<\/mixPort>/ {/flags=\"AUDIO_OUTPUT_FLAG_FAST.*\">$/d; s|( *)<!--(.*flags=\".*\".*)$MODID-->|\1\2|}" $UNITY$FILE
  else
    cp_ch $ORIGDIR$FILE $UNITY$FILE
    sed -ri "/^ *(deep_buffer)|(raw) \{/,/}/ {/^ *flags AUDIO_OUTPUT_FLAG_FAST$/d; s|#$MODID||}" $UNITY$FILE
  fi
done }
