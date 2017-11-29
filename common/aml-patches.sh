ui_print "    Patching existing audio_policy files..."
if [ -f $VEN/etc/audio_output_policy.conf ] && [ -f $SYS/etc/audio_policy_configuration.xml ]; then
  for BUFFER in "Speaker" "Wired Headset" "Wired Headphones"; do
    if [ "$(sed -n "/$BUFFER/ {n;/deep_buffer,/ p}" $AMLPATH$SYS/etc/audio_policy_configuration.xml)" ] && [ ! "$(sed -n "/$BUFFER/ {n;n;/deep_buffer,/p}" $AMLPATH$SYS/etc/audio_policy_configuration.xml)" ]; then
      sed -i "/$BUFFER/ {n;/deep_buffer,/ p}" $AMLPATH$SYS/etc/audio_policy_configuration.xml
      sed -ri "/$BUFFER/ {n;n;/deep_buffer,/ s/( *)(.*)/\1<!--\2-->/}" $AMLPATH$SYS/etc/audio_policy_configuration.xml
      sed -i "/$BUFFER/{n;s/deep_buffer,//;}" $AMLPATH$SYS/etc/audio_policy_configuration.xml
	fi
  done
elif [ ! -f $VEN/etc/audio_output_policy.conf ] && [ -f $SYS/etc/audio_policy_configuration.xml ] && [ "$(grep "deep_buffer," $AMLPATH$SYS/etc/audio_policy_configuration.xml)" ] && [ ! "$(grep "<!--.*deep_buffer" $AMLPATH$SYS/etc/audio_policy_configuration.xml)" ]; then
  sed -ri "/(deep_buffer,|,deep_buffer)/p" $AMLPATH$SYS/etc/audio_policy_configuration.xml
  sed -ri '/(deep_buffer,|,deep_buffer)/{n;s/( *)(.*)deep_buffer(.*)/\1<!--\2deep_buffer\3-->/}' $AMLPATH$SYS/etc/audio_policy_configuration.xml
  sed -i '/<!--/!{/deep_buffer,/ s/deep_buffer,//g}' $AMLPATH$SYS/etc/audio_policy_configuration.xml
  sed -i '/<!--/!{/,deep_buffer/ s/,deep_buffer//g}' $AMLPATH$SYS/etc/audio_policy_configuration.xml
else
  for FILE in ${POLS}; do
    if [ "$FILE" == "*.conf" -o "$FILE" == "$SYS/etc/audio_policy_configuration.xml" ] && [ ! "$(grep "#deep_buffer" $AMLPATH$FILE)" ] && [ "$(grep '^deep_buffer' $AMLPATH$FILE)" ]; then
	  sed -i '/deep_buffer {/,/}/ s/^/#/' $AMLPATH$FILE
	elif [ "$FILE" == "*.xml" ] && [ ! "$(grep "<!--.*deep_buffer" $AMLPATH$FILE)" ]; then
	  sed -i '/deep_buffer {/,/}/ s/deep_buffer/<!--deep_buffer/g; s/}/}-->/g' $AMLPATH$FILE
	fi
  done
fi
