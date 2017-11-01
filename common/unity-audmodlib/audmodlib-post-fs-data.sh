#!/system/bin/sh
SH=${0%/*}
EXT=<EXT>
SEINJECT=<SEINJECT>
AMLPATH=<AMLPATH>
MAGISK=<MAGISK>
XML_PRFX=<XML_PRFX>
ROOT=<ROOT>
SYS=<SYS>
VEN=<VEN>
MODIDS=""
test -d $SYS/priv-app && SOURCE=priv_app || SOURCE=system_app

# AUDIO EFFECTS
CONFIG_FILE=$SYS/etc/audio_effects.conf
HTC_CONFIG_FILE=$SYS/etc/htc_audio_effects.conf
OTHER_V_FILE=$SYS/etc/audio_effects_vendor.conf
OFFLOAD_CONFIG=$SYS/etc/audio_effects_offload.conf
V_CONFIG_FILE=$VEN/etc/audio_effects.conf
# AUDIO POLICY
A2DP_AUD_POL=$SYS/etc/a2dp_audio_policy_configuration.xml
AUD_POL=$SYS/etc/audio_policy.conf
AUD_POL_CONF=$SYS/etc/audio_policy_configuration.xml
AUD_POL_VOL=$SYS/etc/audio_policy_volumes.xml
SUB_AUD_POL=$SYS/etc/r_submix_audio_policy_configuration.xml
USB_AUD_POL=$SYS/etc/usb_audio_policy_configuration.xml
V_AUD_OUT_POL=$VEN/etc/audio_output_policy.conf
V_AUD_POL=$VEN/etc/audio_policy.conf
# MIXER PATHS
MIX_PATH=$SYS/etc/mixer_paths.xml
MIX_PATH_DTP=$SYS/etc/mixer_paths_dtp.xml
MIX_PATH_i2s=$SYS/etc/mixer_paths_i2s.xml
MIX_PATH_TASH=$SYS/etc/mixer_paths_tasha.xml
STRIGG_MIX_PATH=$SYS/sound_trigger_mixer_paths.xml
STRIGG_MIX_PATH_9330=$SYS/sound_trigger_mixer_paths_wcd9330.xml
V_MIX_PATH=$VEN/etc/mixer_paths.xml

# SEPOLICY SETTING FUNCTION
set_sepolicy() {
  if [ $(basename $SEINJECT) == "sepolicy-inject" ]; then
	test -z $4 && $SEINJECT -Z $1 -l || $SEINJECT -s $1 -t $2 -c $3 -p $4 -l
  elif [ ! -z $SEINJECT ]; then
    test -z $3 && $SEINJECT --live "permissive $(echo $1 | sed 's/,/ /g')" || $SEINJECT --live "allow $1 $2 $3 { $(echo $4 | sed 's/,/ /g') }" 
  fi
}

set_sepolicy audioserver audioserver_tmpfs file read,write,execute
set_sepolicy audioserver system_file file execmod
set_sepolicy mediaserver mediaserver_tmpfs file read,write,execute
set_sepolicy mediaserver system_file file execmod
set_sepolicy $SOURCE init unix_stream_socket connectto
set_sepolicy $SOURCE property_socket sock_file getattr,open,read,write,execute
set_sepolicy $SOURCE audio_prop

# MAGISK PROP REMOVAL FUNCTION
<PROPREMOVE>

# MOD PATCHES

for MOD in ${MODIDS}; do
  sed -i "/magisk\/${MOD}/,/fi #${MOD}/d" $SH/post-fs-data.sh
done

test "$MAGISK" == true -a ! "$(sed -n '/# MOD PATCHES/{n;p}' $AMLPATH/post-fs-data.sh)" && rm -rf $AMLPATH

echo "Audmodlib script has run successfully $(date +"%m-%d-%Y %H:%M:%S")" > /cache/audmodlib.log
