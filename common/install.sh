# Tell user aml is needed if applicable
if $MAGISK && ! $SYSOVERRIDE; then
  if $BOOTMODE; then LOC="/sbin/.core/img/*/system $MOUNTPATH/*/system"; else LOC="$MOUNTPATH/*/system"; fi
  FILES=$(find $LOC -type f -name "*audio_*policy*.conf" -o -name "*audio_*policy*.xml" 2>/dev/null)
  if [ ! -z "$FILES" ] && [ ! "$(echo $FILES | grep '/aml/')" ]; then
    ui_print " "
    ui_print "   ! Conflicting audio mod found!"
    ui_print "   ! You will need to install !"
    ui_print "   ! Audio Modification Library !"
    sleep 3
  fi
fi

# Check if FLAGS are even present. If not, do removal since there's nothing to patch
PATCH=false
for FILE in ${POLS}; do
  case $FILE in
    *.xml) [ "$(grep 'flags="AUDIO_OUTPUT_FLAG' $FILE)" ] && { PATCH=true; break; };;
    *.conf) [ "$(grep 'flags AUDIO_OUTPUT_FLAG' $FILE)" ] && { PATCH=true; break; };;
  esac
done

# Get Rem/Pat from zipname
if $PATCH; then
  case $(basename $ZIP) in
    *rem*|*Rem*|*REM*) PATCH=false;;
    *nrem*|*Nrem*|*NREM*) PATCH=true;;
    *) PATCH="";;
  esac
else
  ui_print " "
  ui_print "! No flags detected in policy files!"
  ui_print "! Using removal logic!"
fi

# Keycheck binary by someone755 @Github, idea for code below by Zappo @xda-developers
chmod 755 $INSTALLER/common/keycheck

keytest() {
  ui_print "- Vol Key Test -"
  ui_print "   Press Vol Up:"
  (/system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $INSTALLER/events) || return 1
  return 0
}

chooseport() {
  #note from chainfire @xda-developers: getevent behaves weird when piped, and busybox grep likes that even less than toolbox/toybox grep
  while (true); do
    /system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $INSTALLER/events
    if (`cat $INSTALLER/events 2>/dev/null | /system/bin/grep VOLUME >/dev/null`); then
      break
    fi
  done
  if (`cat $INSTALLER/events 2>/dev/null | /system/bin/grep VOLUMEUP >/dev/null`); then
    return 0
  else
    return 1
  fi
}

chooseportold() {
  # Calling it first time detects previous input. Calling it second time will do what we want
  $INSTALLER/common/keycheck
  $INSTALLER/common/keycheck
  SEL=$?
  if [ "$1" == "UP" ]; then
    UP=$SEL
  elif [ "$1" == "DOWN" ]; then
    DOWN=$SEL
  elif [ $SEL -eq $UP ]; then
    return 0
  elif [ $SEL -eq $DOWN ]; then
    return 1
  else
    ui_print "   Vol key not detected!"
    abort "   Use name change method in TWRP"
  fi
}
ui_print " "
if [ -z $PATCH ]; then
  if keytest; then
    FUNCTION=chooseport
  else
    FUNCTION=chooseportold
    ui_print "   ! Legacy device detected! Using old keycheck method"
    ui_print " "
    ui_print "- Vol Key Programming -"
    ui_print "   Press Vol Up Again:"
    $FUNCTION "UP"
    ui_print "   Press Vol Down"
    $FUNCTION "DOWN"
  fi
  ui_print " "
  ui_print "- Select Patch Method -"
  ui_print "   Patch flags or remove sections?:"
  ui_print "   Vol Up = Patch (new logic)"
  ui_print "   Vol Down = Remove (old logic)"
  ui_print "   Only select Remove if patch doesn't work for you"
  if $FUNCTION; then
    PATCH=true
  else
    PATCH=false
  fi
else
  ui_print "   Patching method specified in zipname!"
fi

ui_print "   Patching existing audio policy files..."
if $PATCH; then
  ui_print "   Using patch logic"
  for OFILE in ${POLS}; do
    FILE="$UNITY$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
    cp_ch_nb $ORIGDIR$OFILE $FILE 0644 false
    case $FILE in
      *.xml) for MIX in "deep_buffer" "raw" "low_latency" "primary-out"; do
               sed -ri "/<mixPort name=\"$MIX\"/,/<\/mixPort> *$/ {/flags=\"[^\"]*/p; s|( *)(.*flags=\"[^\"]*.*)|\1<!--\2$MODID-->|; s|-->$MODID-->|$MODID-->|}" $FILE
               if [ "$MIX" == "deep_buffer" -o $MIX == "low_latency" ]; then
                 sed -ri "/<mixPort name=\"$MIX\"/,/<\/mixPort> *$/ {/<!--/! {s|flags=\"[^\"]*|flags=\"AUDIO_OUTPUT_FLAG_NONE|}}" $FILE
               elif [ "$MIX" == "raw" ]; then
                 sed -i "/<mixPort name=\"$MIX\"/,/<\/mixPort> *$/ {/<!--/! {s|flags=\"[^\"]*|flags=\"AUDIO_OUTPUT_FLAG_FAST|}}" $FILE
               else
                 sed -i "/<mixPort name=\"$MIX\"/,/<\/mixPort> *$/ {/<!--/! {s/|AUDIO_OUTPUT_FLAG_DEEP_BUFFER//; s/AUDIO_OUTPUT_FLAG_DEEP_BUFFER|//}}" $FILE
               fi
             done;;
      *.conf) for MIX in "deep_buffer" "raw" "low_latency" "primary"; do
                sed -ri "/^ *$MIX \{/,/}/ {/flags .*$/p; s|( *flags .*$)|#$MODID\1|}" $FILE
                if [ "$MIX" == "deep_buffer" -o $MIX == "low_latency" ]; then
                  sed -i "/^ *$MIX {/,/}/ {/^ *flags .*$/ s|flags .*|flags AUDIO_OUTPUT_FLAG_NONE|}" $FILE
                elif [ "$MIX" == "raw" ]; then
                  sed -i "/^ *$MIX {/,/}/ {/^ *flags .*$/ s|flags .*|flags AUDIO_OUTPUT_FLAG_FAST|}" $FILE
                else
                  sed -i "/^ *$MIX {/,/}/ {/^ *flags .*$/ s/|AUDIO_OUTPUT_FLAG_DEEP_BUFFER//; s/AUDIO_OUTPUT_FLAG_DEEP_BUFFER|//}" $FILE
                fi
              done;;
    esac
  done
else
  ui_print "   Using remove logic"
  sed -i "s/patch=true/patch=false/" $INSTALLER/module.prop
  sed -i "s/PATCH=true/PATCH=false/" $INSTALLER/common/aml.sh
  FIRST=true
  for FLAG in "deep_buffer" "raw" "low_latency"; do
    if [ -f $VEN/etc/audio_output_policy.conf ] && [ -f /system/etc/audio_policy_configuration.xml ]; then
      $FIRST && cp_ch_nb $ORIGDIR/system/etc/audio_policy_configuration.xml $UNITY/system/etc/audio_policy_configuration.xml 0644 false
      for BUFFER in "Earpiece" "Speaker" "Wired Headset" "Wired Headphones" "Line" "HDMI" "Proxy" "FM" "BT SCO All" "USB Device Out" "Telephony Tx" "voice_rx" "primary input" "surround_sound" "record_24" "BT A2DP Out" "BT A2DP Headphones" "BT A2DP Speaker"; do
        if [ "$(sed -n "/$BUFFER/ {n;/$FLAG,/ p}" $UNITY/system/etc/audio_policy_configuration.xml)" ] && [ ! "$(sed -n "/$BUFFER/ {n;n;/$FLAG,/p}" $UNITY/system/etc/audio_policy_configuration.xml)" ]; then
          $FIRST && { sed -i "/$BUFFER/ {n;/$FLAG,/ p}" $UNITY/system/etc/audio_policy_configuration.xml;
                      sed -ri "/$BUFFER/ {n;n;/$FLAG,/ s/( *)(.*)/\1<!--\2$MODID-->/}" $UNITY/system/etc/audio_policy_configuration.xml; }
          sed -i "/$BUFFER/{n;s/$FLAG,//;}" $UNITY/system/etc/audio_policy_configuration.xml
        fi
      done
    elif [ ! -f $VEN/etc/audio_output_policy.conf ] && [ -f /system/etc/audio_policy_configuration.xml ]; then
      $FIRST && { cp_ch_nb $ORIGDIR/system/etc/audio_policy_configuration.xml $UNITY/system/etc/audio_policy_configuration.xml 0644 false;
                  sed -ri "/($FLAG,|,$FLAG)/p" $UNITY/system/etc/audio_policy_configuration.xml;
                  sed -ri "/($FLAG,|,$FLAG)/{n;s/( *)(.*)$FLAG(.*)/\1<!--\2$FLAG\3$MODID-->/}" $UNITY/system/etc/audio_policy_configuration.xml; }
      sed -i "/<!--/!{/$FLAG,/ s/$FLAG,//g}" $UNITY/system/etc/audio_policy_configuration.xml
      sed -i "/<!--/!{/,$FLAG/ s/,$FLAG//g}" $UNITY/system/etc/audio_policy_configuration.xml
    elif [ -f $VEN/etc/audio/audio_policy_configuration.xml ]; then
      $FIRST && { cp_ch_nb $ORIGDIR$VEN/etc/audio/audio_policy_configuration.xml $UNITY$VEN/etc/audio/audio_policy_configuration.xml 0644 false;
                  sed -ri "/($FLAG,|,$FLAG)/p" $UNITY$VEN/etc/audio/audio_policy_configuration.xml;
                  sed -ri "/($FLAG,|,$FLAG)/{n;s/( *)(.*)$FLAG(.*)/\1<!--\2$FLAG\3$MODID-->/}" $UNITY$VEN/etc/audio/audio_policy_configuration.xml; }
      sed -i "/<!--/!{/$FLAG,/ s/$FLAG,//g}" $UNITY$VEN/etc/audio/audio_policy_configuration.xml
      sed -i "/<!--/!{/,$FLAG/ s/,$FLAG//g}" $UNITY$VEN/etc/audio/audio_policy_configuration.xml
    else
      for OFILE in ${POLS}; do
        FILE="$UNITY$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
        $FIRST && cp_ch_nb $ORIGDIR$OFILE $FILE 0644 false
        case $FILE in
          *.conf) if [ ! "$(grep "#$MODID *$FLAG" $FILE)" ] && [ "$(grep "^ *$FLAG" $FILE)" ]; then
                    sed -i "/$FLAG {/,/}/ s/^/#$MODID/" $FILE
                  fi;;
          *.xml) if [ ! "$(grep "<!--.*$FLAG" $FILE)" ]; then
                   sed -i "/$FLAG {/,/}/ s/$FLAG {/<!--$FLAG {/g; s/}/}$MODID-->/g" $FILE
                 fi;;
        esac
      done
    fi
  FIRST=false
  done
fi
$MAGISK && cp -f $INSTALLER/common/aml.sh $UNITY/.aml.sh
