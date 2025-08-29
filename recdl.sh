#!/usr/bin/env sh

set -u

which "fzf" >/dev/null 2>&1 ||
  {
    echo "'fzf' could be found in the current environment. This dependency is required. Abort." >&2;
    return 1
  }

# note: also echo ".." to allow going backward in recdl
if which "fd" >/dev/null 2>&1; then
  fd_cmd() {
    relpath=$1
    echo "${relpath}/../"
    fd . "${relpath}" -t d --hidden --no-ignore -d 1
  }
elif which "find" >/dev/null 2>&1; then
  fd_cmd() {
    relpath=$1
    echo "${relpath}/../"
    find "${relpath}/" -maxdepth 1 -type d
  }
else
  echo "Neither 'fd' nor 'find' could be found in the current environment. These dependencies are required. Abort." >&2
  return 1
fi

recdl() {
  base="$(pwd)"
  newdir_relative="./"
  while true; do
    newdir_relative="$(
      fd_cmd "$(realpath --relative-to="$base" "$newdir_relative")" | fzf \
        --layout=reverse \
        --smart-case \
        --algo=v2 \
        --style=full \
        --height=40%
    )"
    exit_status=$?

    # 130 is an expected SIGINT interrupt of fzf (see fzf manpage)
    [ $exit_status -eq 130 ] && {
      cd "$newdir_relative" || {
        echo "Error: unexpected error while trying to 'cd' to '$newdir_relative'" >&2
        return 1
      }
      return 0
    }

    # No match (see fzf manpage)
    [ $exit_status -eq 1 ] && {
      echo "Warning: impossible to 'cd' to given directory as it is not part of possible choices." >&2
      continue
    }
    [ $exit_status -eq 2 ] && {
      echo "Error: unexpected error of fzf" >&2
      return 1
    }
    [ $exit_status -eq 0 ] || {
      echo "Error: unexpected error status: '$exit_status'. Abort." >&2
      return 1
    }

    [ -d "$newdir_relative" ] || {
      echo "Error: unexpectedly, '$newdir_relative' is not a directory. Abort." >&2
      return 1
    }

    echo ">$newdir_relative" >&2
  done
}

alias hrecdl="cd \$HOME; recdl"
