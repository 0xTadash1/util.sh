psqlHomeNoCowNoComp() {
  local PSQL_HOME="${PSQL_HOME:?Please set}"
  [ -d "$PSQL_HOME" ] && {
    echo "already exist: $PSQL_HOME"
    return 1
  }

  command mkdir -pv "$PSQL_HOME"
  # No CoW, No compression
  command chattr +Cm "$PSQL_HOME"
}
