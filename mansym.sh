
# NAME
#         mansym - Create a symbolic link to the man-pages file in the manpath
#                  directory.
#
# SYNOPSIS
#         mansym NEWMAN MANDIR
#
# DESCRIPTION
#         Create a symbolic link to the man-pages file in the manpath directory.
#
#         A NEWMAN argument is the path of man-pages file. It's something like
#         `/foo/bar/baz.1`. Those with the suffix `.gz` are also allowed.
#         Internally, the program uses `ln` to symbolic linking. NEWMAN may be
#         a relative path to the link in MANDIR. E.g. `MANDIR/man1/foo.1.gz`
#
#         A MANDIR argument is the directory path of man utilities detectables.
#         MANDIR must be part of the `manpath` result. See manpath(1) and
#         manpath(5) for more information.
#
# EXIT STATUS
#         0    Success
#         1    Invalid arguments
#         2    Missing arguments
#         3    `mkdir` command failed
#         4    `ln` command failed
#         5    `mandb` command failed
#
# SEE ALSO
#         ln(1), man-pages(7), manpath(1), manpath(5), man(7), mandb(8), mkdir(1)

mansym() (
  _err() { echo "$@" >/dev/null 1>&2; }

  local newman
  if [ -z "$1" ]; then
    _err 'Missing first arg; a path of new man-pages file.'
    exit 2
  elif [ ! -f "$1" ]; then
    _err "${1} is not a regular file."
    exit 1
  fi
  newman="$1"

  local filename="${newman##*/}"
  local section
  # E.g. foo.1.gz -> foo.1, bar.1p -> bar.1p, bax.n.gzip -> bax.n
  section="${filename%.gz*}"
  # E.g. foo.1 -> 1
  section="${section##*.}"

  if [ -z "$filename" ] || [ -z "$section" ] || [ -n "$(echo "$section" | tr -d '[:alnum:]')" ]; then
    _err 'Failed to parse the man-pages path. Expected: `/foo/bar/baz.1`'
    exit 1
  fi

  local mandir
  if [ -z "$2" ]; then
    _err 'Missing second arg; a directory path of man utils detectables.'
    _err 'See the SEARCH PATH section of manpath(5).'
    exit 2
  else
    case "$(command manpath)" in
      *"$mandir"*) ;;
      *)
        _err 'The specified man directory is not in `manpath` result.'
        exit 1
        ;;
    esac
  fi
  mandir="${2%/}"
  mandir="${mandir}/man${section}"

  [ -d "$mandir" ] \
    || command mkdir -p "$mandir" \
    || exit 3

  command ln -sfv "$newman" "${mandir}/${filename}" \
    || exit 4
  command mandb \
    || exit 5

  exit 0
)
