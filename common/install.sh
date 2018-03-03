ui_print "   Patching existing audio_policy files..."
if [ -f $VEN/etc/audio_output_policy.conf ] && [ -f $SYS/etc/audio_policy_configuration.xml ]; then
  cp_ch $ORIGDIR$SYS/etc/audio_policy_configuration.xml $UNITY$SYS/etc/audio_policy_configuration.xml
  for BUFFER in "Earpiece" "Speaker" "Wired Headset" "Wired Headphones" "Line" "HDMI" "Proxy" "FM" "BT SCO All" "USB Device Out" "Telephony Tx" "voice_rx" "primary input" "surround_sound" "record_24" "BT A2DP Out" "BT A2DP Headphones" "BT A2DP Speaker"; do
    if [ "$(sed -n "/$BUFFER/ {n;/deep_buffer,/ p}" $UNITY$SYS/etc/audio_policy_configuration.xml)" ] && [ ! "$(sed -n "/$BUFFER/ {n;n;/deep_buffer,/p}" $UNITY$SYS/etc/audio_policy_configuration.xml)" ]; then
      sed -i "/$BUFFER/ {n;/deep_buffer,/ p}" $UNITY$SYS/etc/audio_policy_configuration.xml
      sed -ri "/$BUFFER/ {n;n;/deep_buffer,/ s/( *)(.*)/\1<!--\2-->/}" $UNITY$SYS/etc/audio_policy_configuration.xml
      sed -i "/$BUFFER/{n;s/deep_buffer,//;}" $UNITY$SYS/etc/audio_policy_configuration.xml
    fi
  done
elif [ ! -f $VEN/etc/audio_output_policy.conf ] && [ -f $SYS/etc/audio_policy_configuration.xml ]; then
  cp_ch $ORIGDIR$SYS/etc/audio_policy_configuration.xml $UNITY$SYS/etc/audio_policy_configuration.xml
  sed -ri "/(deep_buffer,|,deep_buffer)/p" $UNITY$SYS/etc/audio_policy_configuration.xml
  sed -ri "/(deep_buffer,|,deep_buffer)/{n;s/( *)(.*)deep_buffer(.*)/\1<!--\2deep_buffer\3-->/}" $UNITY$SYS/etc/audio_policy_configuration.xml
  sed -i "/<!--/!{/deep_buffer,/ s/deep_buffer,//g}" $UNITY$SYS/etc/audio_policy_configuration.xml
  sed -i "/<!--/!{/,deep_buffer/ s/,deep_buffer//g}" $UNITY$SYS/etc/audio_policy_configuration.xml
elif [ -f $VEN/etc/audio/audio_policy_configuration.xml ]; then
  cp_ch $ORIGDIR$VEN/etc/audio/audio_policy_configuration.xml $UNITY$VEN/etc/audio/audio_policy_configuration.xml
  sed -ri "/(deep_buffer,|,deep_buffer)/p" $UNITY$VEN/etc/audio/audio_policy_configuration.xml
  sed -ri "/(deep_buffer,|,deep_buffer)/{n;s/( *)(.*)deep_buffer(.*)/\1<!--\2deep_buffer\3-->/}" $UNITY$VEN/etc/audio/audio_policy_configuration.xml
  sed -i "/<!--/!{/deep_buffer,/ s/deep_buffer,//g}" $UNITY$VEN/etc/audio/audio_policy_configuration.xml
  sed -i "/<!--/!{/,deep_buffer/ s/,deep_buffer//g}" $UNITY$VEN/etc/audio/audio_policy_configuration.xml
else
  for FILE in ${POLS}; do
    cp_ch $ORIGDIR$FILE $UNITY$FILE
    $MAGISK && cp_ch $ORIGDIR$FILE $UNITY$FILE
    case $FILE in
      *.conf) if [ ! "$(grep "# *deep_buffer" $UNITY$FILE)" ] && [ "$(grep '^ *deep_buffer' $UNITY$FILE)" ]; then
                sed -i "/deep_buffer {/,/}/ s/^/#/" $UNITY$FILE
              fi;;
      *.xml) if [ ! "$(grep "<!--.*deep_buffer" $UNITY$FILE)" ]; then
               sed -i "/deep_buffer {/,/}/ s/deep_buffer/<!--deep_buffer/g; s/}/}-->/g" $UNITY$FILE
             fi;;
    esac
  done
fi
