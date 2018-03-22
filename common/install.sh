# Remove old ubdr
[ -f $(echo $MOD_VER | sed "s/$MODID/Ubd_Remover/g") ]; then
  ui_print "   Old Ubdr detected! Removing..."
  INFO=$(echo $INFO | sed "s/$MODID/Ubd_Remover/g")
  MODPATH=$(echo $MODPATH | sed "s/$MODID/Ubd_Remover/g")
  MODID="Ubd_Remover"
  unity_uninstall
  MODID=`grep_prop id $INSTALLER/module.prop`
  INFO=$(echo $INFO | sed "s/Ubd_Remover/$MODID/g")
  MODPATH=$(echo $MODPATH | sed "s/Ubd_Remover/$MODID/g|")
fi
ui_print "   Patching existing audio policy files..."
for FILE in ${POLS}; do
  cp_ch $ORIGDIR$FILE $UNITY$FILE
  case $FILE in
    *.xml) sed -ri "/<mixPort name=\"(deep_buffer)|(raw)\"/,/<\/mixPort> *$/ {/flags=\".*\">$/p; s|( *)(.*flags=\".*\">$)|\1<!--\2$MODID-->|}" $UNITY$FILE
          sed -ri "/<mixPort name=\"(deep_buffer)|(raw)\"/,/<\/mixPort> *$/ {/<!--/! {s|flags=\".*\"|flags=\"AUDIO_OUTPUT_FLAG_FAST\"|}}" $UNITY$FILE;;
    *.conf) sed -ri "/^ *(deep_buffer)|(raw) \{/,/}/ {/flags .*$/p; s|( *flags .*$)|#$MODID\1|}" $UNITY$FILE
           sed -ri "/^ *(deep_buffer)|(raw) \{/,/}/ {/^ *flags .*$/ s|flags .*|flags AUDIO_OUTPUT_FLAG_FAST|}" $UNITY$FILE;;
  esac
done
