#!/usr/bin/env sh

set -u

which "fzf" >/dev/null 2>&1 ||
  {
    echo "'fzf' could be found in the current environment. This dependency is required. Abort." >&2;
    return 1;
  }

if which "fd" >/dev/null 2>&1; then
  fd_cmd() {
    fd -t d --hidden --no-ignore -d 1
  }
elif which "find" >/dev/null 2>&1; then
  fd_cmd() {
    find . -maxdepth 1 -type d
  }
else
  echo "Neither 'fd' nor 'find' could be found in the current environment. These dependencies are required. Abort." >&2
  return 1
fi

recdl() {
  base=$(pwd)
  while true; do
    dir="$(
      fd_cmd | fzf \
        --layout=reverse \
        --smart-case \
        --algo=v2 \
        --style=full \
        --height=40%
    )"
    exit_status=$?
    # 130 is an expected SIGINT interrupt of fzf (see 'man fzf')
    [ $exit_status -eq 130 ] && break
    # No match (see fzf manpage)
    [ $exit_status -eq 1 ] && { 
      echo "Warning: impossible to 'cd' to given directory as it is not part of possible choices." >&2; 
      continue
    }
    [ $exit_status -eq 0 ] || {
      echo "unexpected error status: '$exit_status'" >&2
      break
    }
    # change to selected directory
    { [ -d "$dir" ] && cd "$dir"; } || {
      echo "unexpected error while 'cd': '$exit_status'" >&2
      break
    }
  realpath --relative-to="$base" "$(pwd)"
  done
}

alias hrecdl="cd \$HOME; recdl"
