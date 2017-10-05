# v DO NOT MODIFY v
# See instructions file for predefined variables
# Add xmlstarlet patches here
# NOTE: Destination variable must have '$AMLPATH' in front of it
# Patch Ex: if [ "$($XML_PRFX sel -t -m '/mixer/ctl[@name="HPHR DAC Switch"]' -c . $AMLPATH$MIX)" ]; then
#             $XML_PRFX ed -u "/mixer/ctl[@name='HPHR DAC Switch']/@value" -v 1 $AMLPATH$MIX > $AMLPATH$MIX.temp
#             mv -f $AMLPATH$MIX.temp $AMLPATH$MIX
#           fi
# ^ DO NOT MODIFY ^
