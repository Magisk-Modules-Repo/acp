remove_prop() {
  AMLPROP="$AMLPATH/system.prop"
  if [ -f $AMLPROP ]; then
    if [ "$(cat $1)" ]; then
      cat $1 | while read PROP; do
        test "$(grep "#$PROP" $AMLPROP)" && sed -i "\|#$PROP|d" $AMLPROP || { test "$(grep "$PROP" $AMLPROP)" && sed -i "\|$PROP|d" $AMLPROP; }
      done
    fi
    test ! -s $AMLPROP && rm -f $AMLPROP
  fi
  rm -f $1
}
