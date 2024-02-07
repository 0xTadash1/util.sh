# NAME
# 	charcd - Print character codes for STDIN and/or arguments.
#
# SYNOPSIS
# 	charcd <string>...
#
# DESCRIPTION
# 	This command outputs the character codes of strings provided as input or arguments.
# 	It outputs each character’s code point, separated by a space,
# 	in hexadecimal format without zero-padding.
#
# 	The one last linefeed in the STDIN string is ignored by this function.
charcd() (
	if [[ -t 0 && "$#" == 0 ]]; then
		printf '%s\n' 'No input from STDIN or arguments provided.' 1>&2
		return 1
	fi

	# Insert `"` and Replace `"\0` with `00`
	__charcd__read_stdin_and_insert_quotes_and_validate_null() {
		# If `\0` is included, it will be removed in bash.
		# Therefore, exceptionally, `\0` is converted to `00` instead of `"\0`.
		# Then the result of `printf %x` is `0` as well as `\0`.
		#
		# Example:
		#   ABC\n -> "A"B"C"\n
		#   \n\n\n -> "\n"\n"\n
		#   ABC\n012\n -> "A"B"C"\n"0"1"2"\n
		#   \0 -> 00
		#   \1 -> "\1
		#   012\0\1\2 -> "0"1"200"\1"\2
		#   " -> ""
		#   "Foo" bar -> """F"o"o""" "b"a"r

		__charcd__1of2_insert_quote_and_substitute_quote0_with_00_and_null_with_0 \
		| __charcd__2of2_atomically_replace_00_with_quote0_and_quote0_with_00
	}

	# Insert `"`, and Substitute `"0` with `00` and `\0` with `0`.
	__charcd__1of2_insert_quote_and_substitute_quote0_with_00_and_null_with_0() {
		# At this step, `0` and `\0` are processed as follows:
		#    0 -> 00, \0 -> "0
		# The two representations are reversed in the next step.
		#
		# Example:
		#    ABC\n -> "A"B"C"\n
		#    \n\n\n -> "\n"\n"\n
		#    ABC\n012\n -> "A"B"C"\n00"1"2"\n
		#    \0 -> "0
		#    \1 -> "\1
		#    012\0\1\2 -> 00"1"2"0"\1"\2
		#    " -> ""
		#    "Foo" bar -> """F"o"o""" "b"a"r

		sed '
			s/./"&/g;   # Insert `"` before all chars or byte codes except `\n`
			s/"0/00/g;  # Substitute `"0` with `00` before `\0` becomes `0` or `"\0` becomes `"0`
		' \
		| tr '\0' '0' \
		| awk -v ORS='"\n' '{ print $0; }'

		# sed, tr, awk
		#   Reason for inserting `"` and replacing `"0` with `00` at the same time:
		#
		#   1. Awk terminates at `\0` and ignores the rest of the string.
		#      - Therefore, first substitute `\0` with `00`.
		#   2. However, before that, insert `"` into `0` to make it `"0`.
		#      - This is to distinguish between `00` (originally `\0`) and `0`.

		# sed, awk
		#   When inserting `"` before LF:
		#
		#   - Sed requires a different script in non-GNU envs and special handling for empty lines.
		#   - However, awk can perform this task more simply and consistently across various envs.

		# tr
		#   It can handle `\0` in non-GNU envs like macOS, where sed and awk can't.
	}

	# Atomically Replace: `00` -> `"0`, `"0` -> `00`
	__charcd__2of2_atomically_replace_00_with_quote0_and_quote0_with_00() {
		# Replacing `00` with `"0` or blanks beforehand will not work due to ambiguity.
		# However, awk can solve this problem:
		#
		# 1. Stream into awk with the input delimiter `RS` set as `00`.
		# 2. Replace existing `"0` with `00`.
		# 3. Awk outputs with the output delimiter `ORS` set as `"0`,
		#    and where it was `00` on input, it is replaced with `"0`.
		#
		# This allows the replacement of `00` to `"0` and `"0` to `00` to be processed
		# simultaneously and all at once.

		# To replace atomically, use Record Separator and Output Record Separator of awk
		awk -v RS='00' \
		    -v ORS='"0' '{
			gsub("\"0", "00");
			print $0
		}' \
		| sed '$s/"0$//'  # Remove `"0` at the end of the last line. It's ORS by awk.
	}

	{
		__charcd__window() {
			preprocessed="${1:?}"
			# stdin:
			#   abc\n\n --> "a"b"c"\n"\n -->
			#   --> (The last LF is removed via command sub) --> "a"b"c"\n"
			#
			#  arg:
			#   abc\n\n --> "a"b"c"\n"\n| -->
			#   --> (The last isn't LF, it's `|`) --> "a"b"c"\n"\n|
			lf_keeper_len=${2:?}  # should be 1 or 2

			len="$(( ${#preprocessed} - lf_keeper_len ))"
			start=0
			size=2  # `"a`, `"b`, etc.
			for start in $(seq 0 $size "$(( len - size ))"); do
				printf '%X ' "${preprocessed:${start}:${size}}"
			done
		}

		if [[ ! -t 0 ]]; then
			# NOTE:
			#   One or more `\n` at the end of the last line are removed via Command substitution.
			#
			#   In stdin, only one trailing `"` should be deleted.
			#   This is useful in cases such as `echo foo | charcd`.
			preprocessed_stdin="$(__charcd__read_stdin_and_insert_quotes_and_validate_null)"

			__charcd__window "$preprocessed_stdin" 1
		fi

		for arg in "$@"; do
			# NOTE:
			#   Add one character (here, `|`) to avoid deleting the ending LF.
			#   Unlike stdin, such behavior is not expected for any argument.
			preprocessed_arg="$(
				printf '%s' "${arg}|" | __charcd__read_stdin_and_insert_quotes_and_validate_null)"

			__charcd__window "$preprocessed_arg" 2
		done
	} \
	| sed 's/ $//'  # Remove trailing space
	echo  # Append line break
)

