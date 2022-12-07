# Print character codes for STDIN and/or arguments.
charcd() {
  {
    [ -p /dev/stdin ] && cat
    # NOTE: `"$*"` and `"$@"` are NOT same.
    #  `"$*"` -> `"arg1 arg2"`
    #  `"$@"` -> `"arg1" "arg2"`
    [ -n "$*" ] && printf "$*"
  } | (
    input="$(cat)"
    : ${input:?No STDIN or arguments given}

    for c in $(echo "${input}" | sed "s/./'& /g"); do
      printf '%X ' "$c"
    done
    echo
  )
}
