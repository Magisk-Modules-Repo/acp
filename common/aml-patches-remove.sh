# v DO NOT MODIFY v
# See instructions file for predefined variables
# Add patches (such as audio config) here
# NOTE: Destination variable must have '$AMLPATH' in front of it
# Patch Ex: sed -i '/v4a_standard_fx {/,/}/d' $AMLPATH$CONFIG_FILE
# ^ DO NOT MODIFY ^
if [ -f $V_AUD_OUT_POL ] && [ -f $AUD_POL_CONF ]; then
  for BUFFER in "Speaker" "Wired Headset" "Wired Headphones"; do
    NUM=$(cat -n $AMLPATH$AUD_POL_CONF | sed -n "/$BUFFER/ {n;n;/deep_buffer,/p}" | sed 's/<!--.*//')
	NUM=$((NUM-1))
	sed -i "${NUM}d" $AMLPATH$AUD_POL_CONF
    sed -ri "/$BUFFER/ {n;/deep_buffer,/ s/<!--(.*)-->/\1/g}" $AMLPATH$AUD_POL_CONF
  done
elif [ ! -f $V_AUD_OUT_POL ] && [ -f $AUD_POL_CONF ] && [ "$(grep "<!--.*deep_buffer" $AUD_POL_CONF)" ]; then
  sed -ri -n '/( *)<!--(.*)deep_buffer/{x;d;};1h;1!{x;p;};${x;p;}' $AMLPATH$AUD_POL_CONF
  sed -ri '/deep_buffer/ s/<!--(.*)-->/\1/g' $AMLPATH$AUD_POL_CONF
else
  for CFG in $AUD_POL $V_AUD_OUT_POL $V_AUD_POL; do
    if [ -f $CFG ] && [ "$(grep '#deep_buffer' $AMLPATH$CFG)" ]; then
	  sed -i '/deep_buffer {/,/}/ s/^#//' $AMLPATH$CFG
    fi
  done
  for CFG in $A2DP_AUD_POL $AUD_POL_CONF $AUD_POL_VOL $SUB_AUD_POL $USB_AUD_POL; do
    if [ -f $CFG ] && [ "$(grep "<!--.*deep_buffer" $AMLPATH$CFG)" ]; then
	  sed -i '/<!--deep_buffer {/,/}-->/ s/<!--deep_buffer/deep_buffer/g; s/}-->/}/g' $AMLPATH$CFG
	fi
  done
fi
