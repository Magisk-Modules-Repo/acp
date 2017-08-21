# v DO NOT MODIFY v
# See instructions file for predefined variables
# Add patches (such as audio config) here (starting at line 9)
# NOTE: Destination variable must have '$AMLPATH' in front of it
# Patch Ex: sed -i '/v4a_standard_fx {/,/}/d' $AMLPATH$CONFIG_FILE
#
#
# ^ DO NOT MODIFY ^
ui_print "    Patching existing audio_policy files..."
if [ -f $V_AUD_OUT_POL ] && [ -f $AUD_POL_CONF ]; then
  sed -i '/Speaker/{n;s/deep_buffer,//;}' $AMLPATH$AUD_POL_CONF
  sed -i '/Wired Headset/{n;s/deep_buffer,//;}' $AMLPATH$AUD_POL_CONF
  sed -i '/Wired Headphones/{n;s/deep_buffer,//;}' $AMLPATH$AUD_POL_CONF
elif [ ! -f $V_AUD_OUT_POL ] && [ -f $AUD_POL_CONF ]; then
  sed -i 's/deep_buffer,//g' $AMLPATH$AUD_POL_CONF
  sed -i 's/,deep_buffer//g' $AMLPATH$AUD_POL_CONF
else
  for CFG in $A2DP_AUD_POL $AUD_POL $AUD_POL_CONF $AUD_POL_VOL $SUB_AUD_POL $USB_AUD_POL $V_AUD_OUT_POL $V_AUD_POL; do
    if [ -f $CFG ]; then
	  sed -i '/deep_buffer {/,/}/d' $AMLPATH$CFG
    fi
  done
fi
