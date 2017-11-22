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
test -d $SYS/priv-app && SOURCE=priv_app || SOURCE=system_app

<AMLFILES>

# SEPOLICY SETTING FUNCTION
set_sepolicy() {
  if [ $(basename $SEINJECT) == "sepolicy-inject" ]; then
	test -z $2 && $SEINJECT -Z $1 -l || $SEINJECT -s $1 -t $2 -c $3 -p $4 -l
  else
    test -z $2 && $SEINJECT --live "permissive $(echo $1 | sed 's/,/ /g')" || $SEINJECT --live "allow $1 $2 $3 { $(echo $4 | sed 's/,/ /g') }" 
  fi
}

# CUSTOM USER SCRIPT
