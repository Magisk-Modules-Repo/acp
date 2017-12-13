<SHEBANG>
SH=${0%/*}
MODID=<MODID>
SEINJECT=<SEINJECT>
AMLPATH=<AMLPATH>
MAGISK=<MAGISK>
ROOT=<ROOT>
SYS=<SYS>
VEN=<VEN>
SOURCE=<SOURCE>
LIBDIR=<LIBDIR>
if [ -d $SYS/priv-app ]; then SOURCE=priv_app; else SOURCE=system_app; fi

### FILE LOCATIONS ###
CFGS="${CFGS} $(find -L $SYS -type f -name "*audio_effects*.conf")"
CFGSXML="${CFGSXML} $(find -L $SYS -type f -name "*audio_effects*.xml")"
POLS="${POLS} $(find -L $SYS -type f -name "*audio*policy*.conf")"
POLSXML="${POLSXML} $(find -L $SYS -type f -name "*audio_policy*.xml")"
MIXS="${MIXS} $(find -L $SYS -type f -name "*mixer_paths*.xml")"

# SEPOLICY SETTING FUNCTION
set_sepolicy() {
  if [ "$(basename $SEINJECT)" == "sepolicy-inject" ]; then
	  if [ -z $2 ]; then $SEINJECT -Z $(echo $1 | sed 's/,/; set_sepolicy /g') -l; else $SEINJECT -s $1 -t $2 -c $3 -p $4 -l; fi
  else
    if [ -z $2 ]; then $SEINJECT --live "permissive $(echo $1 | sed 's/,/ /g')"; else $SEINJECT --live "allow $1 $2 $3 { $(echo $4 | sed 's/,/ /g') }"; fi
  fi
}

# CUSTOM USER SCRIPT
