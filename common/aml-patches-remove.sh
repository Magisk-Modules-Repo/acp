if [ -f $VEN/etc/audio_output_policy.conf ] && [ -f $SYS/etc/audio_policy.conf ]; then
  for BUFFER in "Speaker" "Wired Headset" "Wired Headphones"; do
    NUM=$(cat -n $AMLPATH$SYS/etc/audio_policy.conf | sed -n "/$BUFFER/ {n;n;/deep_buffer,/p}" | sed 's/<!--.*//')
	NUM=$((NUM-1))
	sed -i "${NUM}d" $AMLPATH$SYS/etc/audio_policy.conf
    sed -ri "/$BUFFER/ {n;/deep_buffer,/ s/<!--(.*)-->/\1/g}" $AMLPATH$SYS/etc/audio_policy.conf
  done
elif [ ! -f $VEN/etc/audio_output_policy.conf ] && [ -f $SYS/etc/audio_policy.conf ] && [ "$(grep "<!--.*deep_buffer" $AMLPATH$SYS/etc/audio_policy.conf)" ]; then
  sed -ri -n '/( *)<!--(.*)deep_buffer/{x;d;};1h;1!{x;p;};${x;p;}' $AMLPATH$SYS/etc/audio_policy.conf
  sed -ri '/deep_buffer/ s/<!--(.*)-->/\1/g' $AMLPATH$SYS/etc/audio_policy.conf
else
  for CFG in $SYS/etc/audio_policy.conf $VEN/etc/audio_output_policy.conf $VEN/etc/audio_policy.conf; do
    if [ -f $CFG ] && [ "$(grep '#deep_buffer' $AMLPATH$CFG)" ]; then
	  sed -i '/deep_buffer {/,/}/ s/^#//' $AMLPATH$CFG
    fi
  done
  for FILE in ${POLS}; do
    if [ "$(grep "<!--.*deep_buffer" $AMLPATH$FILE)" ]; then
	  sed -i '/<!--deep_buffer {/,/}-->/ s/<!--deep_buffer/deep_buffer/g; s/}-->/}/g' $AMLPATH$FILE
	fi
  done
fi
