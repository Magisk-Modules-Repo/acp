<SHEBANG>
SH=${0%/*}
MODID=<MODID>
SEINJECT=<SEINJECT>
AMLPATH=<AMLPATH>
MAGISK=<MAGISK>
XML_PRFX=<XML_PRFX>
ROOT=<ROOT>
SYS=<SYS>
VEN=<VEN>
if [ -d $SYS/priv-app ]; then SOURCE=priv_app; else SOURCE=system_app; fi

### FILE LOCATIONS ###
CFGS="${CFGS} $(find -L $SYS -type f -name "*audio_effects*.conf")"
POLS="${POLS} $(find -L $SYS -type f -name "*audio*policy*.conf" -o -name "*audio_policy*.xml")"
MIXS="${MIXS} $(find -L $SYS -type f -name "*mixer_paths*.xml")"

# SEPOLICY SETTING FUNCTION
set_sepolicy() {
  if [ "$(basename $SEINJECT)" == "sepolicy-inject" ]; then
	  if [ -z $2 ]; then $SEINJECT -Z $1 -l; else $SEINJECT -s $1 -t $2 -c $3 -p $4 -l; fi
  else
    if [ -z $2 ]; then $SEINJECT --live "permissive $(echo $1 | sed 's/,/ /g')"; else $SEINJECT --live "allow $1 $2 $3 { $(echo $4 | sed 's/,/ /g') }"; fi
  fi
}

# CUSTOM USER SCRIPT
