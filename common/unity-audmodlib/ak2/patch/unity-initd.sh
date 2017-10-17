#!/sbin/sh
# Backups and restores boot (kernel) parition - credits to Osm0sis @xda-developers

. /tmp/backuptool.functions
MODID=audmodlib
SYS=<SYS>
BLOCK=<BLOCK>

list_files() {
cat <<EOF
<FILES>
EOF
}

case "$1" in
  backup)
    list_files | while read FILE DUMMY; do
      backup_file $FILE
    done
    # backup custom kernel
    if [ -e "$BLOCK" ]; then
      dd if=$BLOCK of=/tmp/boot.img
    fi
  ;;
  restore)
    list_files | while read FILE REPLACEMENT; do
      R=""
      [ -n "$REPLACEMENT" ] && R="$REPLACEMENT"
      [ -f "$C/$FILE" ] && restore_file $FILE $R
    done
  ;;
  pre-backup)
    # Stub
  ;;
  post-backup)
    # Stub
  ;;
  pre-restore)
    # Stub
  ;;
  post-restore)
   <FILES2>
   # wait out ROM kernel flash then restore custom kernel
    while sleep 5; do
      [ -e /tmp/boot.img -a -e "$BLOCK" ] && dd if=/tmp/boot.img of=$BLOCK
      exit
    done&
  ;;
esac
