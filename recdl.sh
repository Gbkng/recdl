#!/usr/bin/env sh

set -u

# >>> Default values (see arg parsing and --help for more information)
# note: using './' gives prettier output than using $(pwd)
start_path="./"
bool_init="false"
bool_output_base="true"
bool_output_current="true"

# >>> Argument parsing
while [ $# -gt 0 ]; do
   case $1 in
       -h|--help) echo "Syntaxe: recdl.sh
                   [--path PATH]  start at PATH instead of current directory
                   [--init]  output a to-be-eval script defining the 'recdl'
                   alias, and exit. If the --no-base, or --no-current
                   are used with --init, those options are propagated to the
                   'recdl' alias.
                   [--no-base]  do not output base directory in interface
                   [--no-current]  do not output current directory in interface
                   [--help]  print this help message, and exit

                   DESCRIPTION

                   Output a path constructed by interactively appending contiguous subdirectories, using a fuzzy search interface.
       "; exit 0;;
       --path) start_path="$2"; shift 2 ;;
       --init) bool_init="true"; shift 1 ;;
       --no-base) bool_output_base="false"; shift 1 ;;
       --no-current) bool_output_current="false"; shift 1 ;;
       *) error "error in argument parsing with arg='$1'"; exit 2 ;;
   esac
done

readonly start_path
readonly bool_init
readonly bool_output_base
readonly bool_output_current

if [ "$bool_init" = "true" ]; then
  script_full_path=$(realpath "$0")
  opts=""
  [ "$bool_output_base" = "false" ] && opts="$opts --no-base"
  [ "$bool_output_current" = "false" ] && opts="$opts --no-current"
  echo "alias recdl='dir=\"\$($script_full_path $opts)\" && cd \"\$dir\"'"
  exit 0
fi

# >>> Dependency checking
which "fzf" >/dev/null 2>&1 ||
  {
    echo "'fzf' could not be found in the current environment. This dependency is required. Abort." >&2;
    exit 1
  }

# Select fd or find to be used inside recd loop, prefering fd.
# note: also echo ".." to allow going backward in recdl, as '..' is not
# present present in output the below fd/find cmd
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
  echo "Neither 'fd' nor 'find' could be found in the current environment. At least one of these dependencies are required. Abort." >&2
  exit 1
fi

# >>> read-eval-cd loop
# note: 'cd' globally is often a confusing thing to do. However, as the loop
# relies on './' (for ergonomy) and '../' (for going-backward feature), it is
# considered the less confusing alternative.
# This is done in a subshell to ensure encapsulation.
(
  cd "$start_path" || {
    echo "Error: unexpected error while 'cd' into start path ('$start_path'). Abort"
    exit 1
  }

  [ "$bool_output_base" = "true" ] && echo "[base] $(realpath "$start_path")" >&2

  current_relative_path="."
  while true; do
    # a buffer is required, as exit value of fzf is irrelevant in case of
    # error or interrupt
    buff="$(
      fd_cmd "$(realpath --relative-to="$start_path" "$current_relative_path")" | fzf \
        --layout=reverse \
        --smart-case \
        --algo=v2 \
        --style=full \
        --height=40%
    )"

    exit_status=$?

    # 130 is an expected SIGINT interrupt of fzf (see fzf manpage)
    [ $exit_status -eq 130 ] && {
      # output target directory to stdout makes the function composable with cd
      realpath "${start_path}/${current_relative_path}" || {
        echo "Error: unexpected error while trying to resolve output path ('${start_path}/${current_relative_path}'). Abort." >&2
        exit 1
      }
      exit 0
    }

    # No match (see fzf manpage)
    [ $exit_status -eq 1 ] && {
      echo "Warning: impossible to 'cd' to given directory as it is not part of possible choices." >&2
      continue
    }
    [ $exit_status -eq 2 ] && {
      echo "Error: unexpected error of fzf" >&2
      exit 1
    }
    [ $exit_status -eq 0 ] || {
      echo "Error: unexpected error status: '$exit_status'. Abort." >&2
      exit 1
    }

    current_relative_path=$buff

    [ -d "$current_relative_path" ] || {
      echo "Error: unexpectedly, '$current_relative_path' is not a directory. Abort." >&2
      exit 1
    }

    # clear line and print currently selected directory
    # see tput manpage
    [ "$bool_output_current" = "true" ] && printf "%s> %s" "$(tput el)" "$current_relative_path" >&2
  done
)
