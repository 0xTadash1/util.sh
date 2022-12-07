btrfs-prop-set-user-dirs-comp() (
  _err() { echo 'ERR: '"$@" >/dev/null 1>&2; }
  _info() { echo 'INFO: '"$@"; }

  # Load all `XDG_xxxx_DIR` vars
  userdirs_dirs="$XDG_CONFIG_HOME/user-dirs.dirs"
  [ ! -f "$userdirs_dirs" ] && {
    _err "\`$userdirs_dirs\` not found."
    exit 1
  }
  source "$XDG_CONFIG_HOME/user-dirs.dirs" || {
    _err "\`source $userdirs_dirs\` failed."
    exit 1
  }

  case "$1" in
    zlib|lzo|zstd) algo="$1" ;;
    no|none) algo='none' ;;
    '') algo='' ;;
    *)
      _err 'expected to take the compression algorithm as an argument:'
      _err '  - zlib: slower, higher compression ratio'
      _err '  - lzo : designed to be fast, worse compression ratio than zlib'
      _err '  - zstd: similar compression ratio to zlib, but faster'
      _err '  - no or none       : disable compression (same as `chattr +m`)'
      _err '  - "" (empty string): set the dafault value'
      _err ''
      _err '  In this way, the compression level is not supported.'
      _err ''
      _err '  cf. https://btrfs.wiki.kernel.org/index.php/Compression'
      _err '  cf. btrfs-property(8) or https://btrfs.readthedocs.io/en/latest/btrfs-property.html'
      exit 2
      ;;
  esac

  _info 'The compressions works on data written.'
  _info 'Therefore, the properties should be set on an empty file/directory.'
  echo

  printf '%s' 'Start setting properties with `'"$algo"'` as the algorithm? [Y/n]: '
  read _rep
  case "$_rep" in
    ''|[yY]*) true ;;
    *)
      echo Cancelled.
      exit 2
      ;;
  esac

  set_comp() {
    local user_dir="$1"
    local algo="$2"

    if [ -d "$user_dir" ]; then
      btrfs property set "$user_dir" compression "$algo" \
        || exit $?
    else
      _info "\`$user_dir\` not found. Passed."
    fi
  }

  set_comp "$XDG_DESKTOP_DIR"     "$algo"
  set_comp "$XDG_DOWNLOAD_DIR"    "$algo"
  set_comp "$XDG_TEMPLATES_DIR"   "$algo"
  set_comp "$XDG_PUBLICSHARE_DIR" "$algo"
  set_comp "$XDG_DOCUMENTS_DIR"   "$algo"
  set_comp "$XDG_MUSIC_DIR"       "$algo"
  set_comp "$XDG_PICTURES_DIR"    "$algo"
  set_comp "$XDG_VIDEOS_DIR"      "$algo"
)
