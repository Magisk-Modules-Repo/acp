ui_print "   Patching existing audio policy files..."
for FILE in ${POLS}; do
  case $FILE in
    cp_ch $ORIGDIR$FILE $UNITY$FILE
    *xml) sed -ri "/<mixPort name=\"(deep_buffer)|(raw)\"/,/<\/mixPort> *$/ {/flags=\".*\">$/p; s|( *)(.*flags=\".*\">$)|\1<!--\2$MODID-->|}" $UNITY$FILE
          sed -ri "/<mixPort name=\"(deep_buffer)|(raw)\"/,/<\/mixPort> *$/ {/<!--/! {s|flags=\".*\"|flags=\"AUDIO_OUTPUT_FLAG_FAST\"|}}" $UNITY$FILE;;
    *conf) sed -ri "/^ *(deep_buffer)|(raw) \{/,/}/ {/flags .*$/p; s|( *flags .*$)|#$MODID\1|}" $UNITY$FILE
           sed -ri "/^ *(deep_buffer)|(raw) \{/,/}/ {/^ *flags .*$/ s|(flags .*)|flags AUDIO_OUTPUT_FLAG_FAST|}" $UNITY$FILE;;
  esac
done
