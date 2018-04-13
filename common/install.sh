ui_print "   Patching existing audio policy files..."
for OFILE in ${POLS}; do
  FILE="$UNITY$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
  cp_ch $ORIGDIR$OFILE $FILE
  case $FILE in
    *.xml) sed -ri "/<mixPort name=\"(deep_buffer)|(raw)|(low_latency)\"/,/<\/mixPort> *$/ {/flags=\"[^\"]*/p; s|( *)(.*flags=\"[^\"]*.*)|\1<!--\2$MODID-->|}" $FILE
           sed -ri "/<mixPort name=\"(deep_buffer)|(low_latency)\"/,/<\/mixPort> *$/ {/<!--/! {s|flags=\"[^\"]*|flags=\"AUDIO_OUTPUT_FLAG_NONE|}}" $FILE
           sed -i "/<mixPort name=\"raw\"/,/<\/mixPort> *$/ {/<!--/! {s|flags=\"[^\"]*|flags=\"AUDIO_OUTPUT_FLAG_FAST|}}" $FILE;;
    *.conf) sed -ri "/^ *(deep_buffer)|(raw)|(low_latency) \{/,/}/ {/flags .*$/p; s|( *flags .*$)|#$MODID\1|}" $FILE
            sed -ri "/^ *(deep_buffer)|(low_latency) \{/,/}/ {/^ *flags .*$/ s|flags .*|flags AUDIO_OUTPUT_FLAG_NONE|}" $FILE
            sed -i "/^ *raw \{/,/}/ {/^ *flags .*$/ s|flags .*|flags AUDIO_OUTPUT_FLAG_FAST|}" $FILE;;
  esac
done
if $MAGISK; then
  cp -f $INSTALLER/common/aml.sh $UNITY/.aml.sh
fi
