for FILE in ${FILES}; do
  NAME=$(echo "$FILE" | sed "s|$MOD|system|")
  case $NAME in
    *audio_*policy*.xml) sed -ri "/<mixPort name=\"(deep_buffer)|(low_latency)\"/,/<\/mixPort> *$/ s|flags=\"[^\"]*|flags=\"AUDIO_OUTPUT_FLAG_NONE|" $MODPATH/$NAME
                         sed -i "/<mixPort name=\"raw\"/,/<\/mixPort> *$/ s|flags=\"[^\"]*|flags=\"AUDIO_OUTPUT_FLAG_FAST|" $MODPATH/$NAME;;
    *audio_*policy*.conf) sed -ri "/^ *(deep_buffer)|(low_latency) \{/,/}/ s|flags .*|flags AUDIO_OUTPUT_FLAG_NONE|" $MODPATH/$NAME
                          sed -i "/^ *raw \{/,/}/ s|flags .*|flags AUDIO_OUTPUT_FLAG_FAST|" $MODPATH/$NAME;;
  esac
done
