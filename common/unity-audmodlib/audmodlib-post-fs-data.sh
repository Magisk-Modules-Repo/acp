<SHEBANG>
SH=${0%/*}
SEINJECT=<SEINJECT>
AMLPATH=<AMLPATH>
MAGISK=<MAGISK>
XML_PRFX=<XML_PRFX>
ROOT=<ROOT>
SYS=<SYS>
VEN=<VEN>
SOURCE=<SOURCE>
MODIDS=""
LIBDIR=<LIBDIR>
LIBPATCH=<LIBPATCH>
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

set_sepolicy hal_audio_default hal_audio_default process execmem
set_sepolicy audioserver audioserver_tmpfs file read,write,execute
set_sepolicy audioserver system_file file execmod
set_sepolicy mediaserver mediaserver_tmpfs file read,write,execute
set_sepolicy mediaserver system_file file execmod
set_sepolicy $SOURCE init unix_stream_socket connectto
set_sepolicy $SOURCE property_socket sock_file getattr,open,read,write,execute
set_sepolicy $SOURCE
set_sepolicy audio_prop

# MOD PATCHES

if [ "$MAGISK" == true ]; then
  for MOD in ${MODIDS}; do
    sed -i "/^#$MODID/,/fi #$MODID/d" $SH/post-fs-data.sh
  done
  test ! "$(sed -n '/# MOD PATCHES/{n;p}' $AMLPATH/post-fs-data.sh)" && rm -rf $AMLPATH
fi

echo "Audmodlib script has run successfully $(date +"%m-%d-%Y %H:%M:%S")" > /cache/audmodlib.log
