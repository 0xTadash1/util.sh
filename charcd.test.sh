# To test, `zsh -c '. ./charcd.test.sh'` or `bash -c '. ./charcd.test.sh'`
(
# Init
. ./charcd.sh

fail_at() { echo "FAILURE $((++F)) at $1"; }

# Start cases
echo a       | charcd | [[ "$(cat)" == '61' ]]                   || fail_at $LINENO
printf 'a'   | charcd | [[ "$(cat)" == '61' ]]                   || fail_at $LINENO
echo ab      | charcd | [[ "$(cat)" == '61 62' ]]                || fail_at $LINENO
echo abc     | charcd | [[ "$(cat)" == '61 62 63' ]]             || fail_at $LINENO
echo abcd    | charcd | [[ "$(cat)" == '61 62 63 64' ]]          || fail_at $LINENO
echo abcde   | charcd | [[ "$(cat)" == '61 62 63 64 65' ]]       || fail_at $LINENO
echo a b     | charcd | [[ "$(cat)" == '61 20 62' ]]             || fail_at $LINENO
echo a b c d | charcd | [[ "$(cat)" == '61 20 62 20 63 20 64' ]] || fail_at $LINENO
echo a bcd e | charcd | [[ "$(cat)" == '61 20 62 63 64 20 65' ]] || fail_at $LINENO
echo 'a b'   | charcd | [[ "$(cat)" == '61 20 62' ]]             || fail_at $LINENO
echo 'a  b'  | charcd | [[ "$(cat)" == '61 20 20 62' ]]          || fail_at $LINENO
echo ' '     | charcd | [[ "$(cat)" == '20' ]]                   || fail_at $LINENO
echo ' a'    | charcd | [[ "$(cat)" == '20 61' ]]                || fail_at $LINENO
echo 'a '    | charcd | [[ "$(cat)" == '61 20' ]]                || fail_at $LINENO
echo '  a  ' | charcd | [[ "$(cat)" == '20 20 61 20 20' ]]       || fail_at $LINENO

echo                      | charcd | [[ "$(cat)" == '' ]]                 || fail_at $LINENO
printf '\n\n'             | charcd | [[ "$(cat)" == 'A' ]]                || fail_at $LINENO
printf '\nA'              | charcd | [[ "$(cat)" == 'A 41' ]]             || fail_at $LINENO
printf '\nA\n'            | charcd | [[ "$(cat)" == 'A 41' ]]             || fail_at $LINENO
printf '\nA\n\n'          | charcd | [[ "$(cat)" == 'A 41 A' ]]           || fail_at $LINENO
printf '\a\b\t\n\v\f\r\e' | charcd | [[ "$(cat)" == '7 8 9 A B C D 1B' ]] || fail_at $LINENO
printf '\0'               | charcd | [[ "$(cat)" == '0' ]]                || fail_at $LINENO
printf '\n\0'             | charcd | [[ "$(cat)" == 'A 0' ]]              || fail_at $LINENO
printf '\0\n'             | charcd | [[ "$(cat)" == '0' ]]                || fail_at $LINENO
printf '\0\0\n\n'         | charcd | [[ "$(cat)" == '0 0 A' ]]            || fail_at $LINENO
printf '\n\0\0\n\n'       | charcd | [[ "$(cat)" == 'A 0 0 A' ]]          || fail_at $LINENO


charcd a       | [[ "$(cat)" == '61' ]]             || fail_at $LINENO
charcd ab      | [[ "$(cat)" == '61 62' ]]          || fail_at $LINENO
charcd abc     | [[ "$(cat)" == '61 62 63' ]]       || fail_at $LINENO
charcd abcd    | [[ "$(cat)" == '61 62 63 64' ]]    || fail_at $LINENO
charcd abcde   | [[ "$(cat)" == '61 62 63 64 65' ]] || fail_at $LINENO
charcd a b     | [[ "$(cat)" == '61 62' ]]          || fail_at $LINENO
charcd a b c d | [[ "$(cat)" == '61 62 63 64' ]]    || fail_at $LINENO
charcd a bcd e | [[ "$(cat)" == '61 62 63 64 65' ]] || fail_at $LINENO
charcd 'a b'   | [[ "$(cat)" == '61 20 62' ]]       || fail_at $LINENO
charcd 'a  b'  | [[ "$(cat)" == '61 20 20 62' ]]    || fail_at $LINENO
charcd ' '     | [[ "$(cat)" == '20' ]]             || fail_at $LINENO
charcd ' a'    | [[ "$(cat)" == '20 61' ]]          || fail_at $LINENO
charcd 'a '    | [[ "$(cat)" == '61 20' ]]          || fail_at $LINENO
charcd '  a  ' | [[ "$(cat)" == '20 20 61 20 20' ]] || fail_at $LINENO
charcd 'a'     | [[ "$(cat)" == '61' ]]             || fail_at $LINENO

charcd $'\n'               | [[ "$(cat)" == 'A' ]]                || fail_at $LINENO
charcd $'\n\n'             | [[ "$(cat)" == 'A A' ]]              || fail_at $LINENO
charcd $'\nA'              | [[ "$(cat)" == 'A 41' ]]             || fail_at $LINENO
charcd $'\nA\n'            | [[ "$(cat)" == 'A 41 A' ]]           || fail_at $LINENO
charcd $'\nA\n\n'          | [[ "$(cat)" == 'A 41 A A' ]]         || fail_at $LINENO
charcd $'\a\b\t\n\v\f\r\e' | [[ "$(cat)" == '7 8 9 A B C D 1B' ]] || fail_at $LINENO

# zsh || bash
charcd $'\0'             | ([[ "${v:=$(cat)}" == '0' || "$v" == '' ]])      || fail_at $LINENO
charcd $'\0' $'\n'       | ([[ "${v:=$(cat)}" == '0 A' || "$v" == 'A' ]])   || fail_at $LINENO
charcd $'\0' $'\0' $'\n' | ([[ "${v:=$(cat)}" == '0 0 A' || "$v" == 'A' ]]) || fail_at $LINENO

# Bash seems to delete the string after `\0` for each quotation (`"foo"`, `'bar'`, `$'baz'`).
# Therefore, to continue the string after `\0`, put it in a separate quote.
# Also, only `$'\n'` is deleted in the same quotation even if it is before `\0`.
#
# I.e. `$'Foo\0''Bar'` instead of `$'Foo\0Bar'`
# I.e. `$'\n'$'\0'` instead of `$'\n\0'
charcd $'\n'$'\0'     | ([[ "${v:=$(cat)}" == 'A 0' || "$v" == 'A' ]])       || fail_at $LINENO
charcd $'\0'$'\n'     | ([[ "${v:=$(cat)}" == '0 A' || "$v" == 'A' ]])       || fail_at $LINENO
charcd $'\0\0'$'\n\n' | ([[ "${v:=$(cat)}" == '0 0 A A' || "$v" == 'A A' ]]) || fail_at $LINENO

charcd $'\n'$'\0\0'$'\n\n' | ([[ "${v:=$(cat)}" == 'A 0 0 A A' || "$v" == 'A A A' ]]) || fail_at $LINENO
charcd $'A\0' $'\0''B' $'C\nD' \
| ([[ "${v:=$(cat)}" == '41 0 0 42 43 A 44' || "$v" == '41 42 43 A 44' ]]) || fail_at $LINENO

# It should fail
charcd >& /dev/null && fail_at $LINENO

# Result
if (( F == 0 )); then
  echo 'ALL TEST CASE PASSED.'
  return 0
else
  echo "$F TEST CASE(S) FAILED."
  return 1
fi
)
