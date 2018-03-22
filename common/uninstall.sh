$MAGISK || { for FILE in ${POLS}; do
  case $FILE in
    *xml) sed -ri "/<mixPort name=\"(deep_buffer)|(raw)\"/,/<\/mixPort>/ {/flags=\"AUDIO_OUTPUT_FLAG_FAST.*\">$/d; s|( *)<!--(.*flags=\".*\".*)$MODID-->|\1\2|}" $UNITY$FILE;;
    *conf) sed -ri "/^ *(deep_buffer)|(raw) \{/,/}/ {/^ *flags AUDIO_OUTPUT_FLAG_FAST$/d; s|#$MODID||}" $UNITY$FILE;;
  esac
done }
