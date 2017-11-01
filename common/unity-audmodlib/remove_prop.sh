remove_prop() {
  AMLPROP="$AMLPATH/system.prop"
  if [ -f $AMLPROP ]; then
    cat $1 | while read PROP; do
      test "$(grep "#$PROP" $AMLPROP)" && sed -i "\|#$PROP|d" $AMLPROP || { test "$(grep "$PROP" $AMLPROP)" && sed -i "\|$PROP|d" $AMLPROP; }
    done
    test ! -s $AMLPROP && rm -f $AMLPROP
  fi
  rm -f $1
}
