if [ -f $VEN/etc/audio_output_policy.conf ] && [ -f $SYS/etc/audio_policy_configuration.xml ]; then
  for BUFFER in "Speaker" "Wired Headset" "Wired Headphones"; do
    NUM=$(cat -n $AMLPATH$SYS/etc/audio_policy_configuration.xml | sed -n "/$BUFFER/ {n;n;/deep_buffer,/p}" | sed 's/<!--.*//')
	NUM=$((NUM-1))
	sed -i "${NUM}d" $AMLPATH$SYS/etc/audio_policy_configuration.xml
    sed -ri "/$BUFFER/ {n;/deep_buffer,/ s/<!--(.*)-->/\1/g}" $AMLPATH$SYS/etc/audio_policy_configuration.xml
  done
elif [ ! -f $VEN/etc/audio_output_policy.conf ] && [ -f $SYS/etc/audio_policy_configuration.xml ] && [ "$(grep "<!--.*deep_buffer" $AMLPATH$SYS/etc/audio_policy_configuration.xml)" ]; then
  sed -ri -n '/( *)<!--(.*)deep_buffer/{x;d;};1h;1!{x;p;};${x;p;}' $AMLPATH$SYS/etc/audio_policy_configuration.xml
  sed -ri '/deep_buffer/ s/<!--(.*)-->/\1/g' $AMLPATH$SYS/etc/audio_policy_configuration.xml
else
  for FILE in ${POLS}; do
    if [ "$FILE" == "$SYS/etc/audio_policy_configuration.xml" ] && [ ! "$(grep "#deep_buffer" $AMLPATH$FILE)" ] && [ "$(grep '^deep_buffer' $AMLPATH$FILE)" ]; then
	    sed -i '/deep_buffer {/,/}/ s/^#//' $AMLPATH$FILE
    fi
  done
  for FILE in ${POLSXML}; do
    if [ "$(grep "<!--.*deep_buffer" $AMLPATH$FILE)" ]; then
      sed -i '/<!--deep_buffer {/,/}-->/ s/<!--deep_buffer/deep_buffer/g; s/}-->/}/g' $AMLPATH$FILE
    fi
  done
fi
# if [ ! -z $XML_PRFX ]; then
  # # Enter xmlstarlet logic here
# fi
