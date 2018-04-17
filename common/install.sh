# Tell user aml is needed if applicable
if $MAGISK; then
  if $BOOTMODE; then LOC="/sbin/.core/img/*/system $MOUNTPATH/*/system"; else LOC="$MOUNTPATH/*/system"; fi
  FILES=$(find $LOC -type f -name "*audio_*policy*.conf" -o -name "*audio_*policy*.xml")
  if [ ! -z "$FILES" ] && [ ! "$(echo $FILES | grep '/aml/')" ]; then
    ui_print " "
    ui_print "   ! Conflicting audio mod found!"
    ui_print "   ! You will need to install !"
    ui_print "   ! Audio Modification Library !"
    sleep 3
  fi
fi

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
