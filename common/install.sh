ui_print "   Patching existing audio policy files..."
for FILE in ${POLS}; do
  cp_ch $ORIGDIR$FILE $UNITY$FILE
  case $FILE in
    *.xml) sed -ri "/<mixPort name=\"(deep_buffer)|(raw)|(low_latency)\"/,/<\/mixPort> *$/ {/flags=\"[^\"]*/p; s|( *)(.*flags=\"[^\"]*.*)|\1<!--\2$MODID-->|}" $UNITY$FILE
           sed -ri "/<mixPort name=\"(deep_buffer)|(low_latency)\"/,/<\/mixPort> *$/ {/<!--/! {s|flags=\"[^\"]*|flags=\"AUDIO_OUTPUT_FLAG_PRIMARY|}}" $UNITY$FILE
           sed -i "/<mixPort name=\"raw\"/,/<\/mixPort> *$/ {/<!--/! {s|flags=\"[^\"]*|flags=\"AUDIO_OUTPUT_FLAG_FAST|}}" $UNITY$FILE;;
    *.conf) sed -ri "/^ *(deep_buffer)|(raw)|(low_latency) \{/,/}/ {/flags .*$/p; s|( *flags .*$)|#$MODID\1|}" $UNITY$FILE
            sed -ri "/^ *(deep_buffer)|(low_latency) \{/,/}/ {/^ *flags .*$/ s|flags .*|flags AUDIO_OUTPUT_FLAG_PRIMARY|}" $UNITY$FILE
            sed -i "/^ *raw \{/,/}/ {/^ *flags .*$/ s|flags .*|flags AUDIO_OUTPUT_FLAG_FAST|}" $UNITY$FILE;;
  esac
done
