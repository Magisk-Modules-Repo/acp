<SHEBANG>
SH=${0%/*}
SEINJECT=<SEINJECT>
AMLPATH=<AMLPATH>
MAGISK=<MAGISK>
XML_PRFX=<XML_PRFX>
ROOT=<ROOT>
SYS=<SYS>
VEN=<VEN>
MODIDS=""
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

set_sepolicy audioserver audioserver_tmpfs file read,write,execute
set_sepolicy audioserver system_file file execmod
set_sepolicy mediaserver mediaserver_tmpfs file read,write,execute
set_sepolicy mediaserver system_file file execmod
set_sepolicy $SOURCE init unix_stream_socket connectto
set_sepolicy $SOURCE property_socket sock_file getattr,open,read,write,execute
set_sepolicy $SOURCE,audio_prop

# MOD PATCHES

if [ "$MAGISK" == true ]; then
  for MOD in ${MODIDS}; do
    sed -i "/magisk\/$MOD/,/fi #$MOD/d" $SH/post-fs-data.sh
  done
  test ! "$(sed -n '/# MOD PATCHES/{n;p}' $AMLPATH/post-fs-data.sh)" && rm -rf $AMLPATH
fi

echo "Audmodlib script has run successfully $(date +"%m-%d-%Y %H:%M:%S")" > /cache/audmodlib.log
