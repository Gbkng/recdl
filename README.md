# About recdl

A read-eval-cd-loop as a simple, `sh`-compliant, shell function.

`recdl.sh` shell script repeats the following `read-eval-cd` loop:

- Scan directories in a starting point (i.e. a base directory, which defaults to `PWD`)
- Let the user interactively choose one of these directories (see
  [`fzf`](https://github.com/junegunn/fzf) documentation for more information)
- `cd` to the chosen directory (Actually, the present implementation of the
  loop do not cd at each iteration, but gives the illusion it does.)
- Repeat...

To interrupt the loop, press `Escape` or `Ctrl-C`. If there is no error,
`recdl.sh` **outputs the last selected directory to its standard output**.

**It is not possible to `cd` from inside the script directly**, as a process
cannot propagate its environment to its parent process (which `PWD` variable is
part of). That is why `recdl.sh` only output a directory: it allows the parent
process to use the standard output of the `recdl.sh` command to do any
operation, **including `cd` to this output**.

The `recdl` script is basically a convenient wrapper around `fzf`.

# Installation

Simply clone this repository and ensure `recdl.sh` is in a directory referenced in your `$PATH`.

If you follow the [XDG Base Directory
Specification](https://specifications.freedesktop.org/basedir-spec/latest/#variables)
such that `~/.local/bin` is part of your `$PATH`, simply create a symlink to
`recdl.sh` at `~/.local/bin`:

```sh
ln -s "$(realpath $PATH_TO_THIS_REPOSITORY/recdl.sh)" "~/.local/bin/recdl.sh"
```

For the sake of simplicity, the name of the symlink is `recdl.sh`, but it might
be more convenient to name the symlink `recdl` directly.

# Usage

**NOTE:** `recdl.sh` is typically not used directly, but as a component of
another command. See `Examples` section below which illustrates some common use
cases.

```sh
recdl.sh
```

Hit `Enter` to select a directory (read
[`fzf`](https://github.com/junegunn/fzf) usage instructions for more
information)

Hit `Ctrl-C` or `Escape` to interrupt the loop, which outputs the last selected
directory to standard output.

By default, `recdl.sh` uses `PWD` variable as its starting point. Another base
directory can be selected using the `--path` option:

```sh
recdl.sh --path SOME_PATH
```

For a minimalist layout, use the `--no-base` and `--no-current` options:

```sh
recdl.sh --no-base --no-current
```

By default, `recdl.sh` displays the currently selected directory, using `tput`
to clear the previously displayed directory. It can be useful to deactivate
this option, when embedding `recdl.sh` in other commands, which may have
complex display.

More generally, except from the lastly selected directory, `recdl.sh` displays
everything to standard error, so that it's easy to silence any information,
error, or warning message, for instance by using `2>/dev/null`.

See `recdl.sh --help` for more information.

# Examples

By itself, `recdl.sh` does nothing more than printing a path to standard
output. It can then be used in other commands or aliases.

Here are some common use cases:

- Go to selected directory if the command succeed:

  ```sh
  dir="$(recdl.sh)" && cd $dir
  ```

- Open your favorite editor at the selected directory, starting at `$HOME`, with a minimalist display:

  ```sh
  dir="$(recdl.sh --path $HOME --no-base --no-current)" && $EDITOR $dir
  ```

# Requirements

- [`fzf`](https://github.com/junegunn/fzf)
- [`fd`](https://github.com/sharkdp/fd) (recommended) or `find`; `find` is
available by default on most system while `fd` runs faster

# Rationale

The goal of `recdl` is to change directory with a more pleasant approach than
usual `cd`. The latter is repetitive and often does not have fuzzy completion.

The `fzf` application allows to fuzzy search any directory or subdirectory
inside the current one, directly, with fuzzy match.

Running `fzf` directly from a large directory (e.g. `$HOME`) is not always
satisfactory, as too many directories are scanned recursively, leading to high
CPU and power usage.

One could set filters, such as searching across git repositories only, skipping
git-ignored files, skipping hidden files, etc. These filters can be very
relevant inside specific project directories (e.g. to find a source
file to edit). However, they are not always tailored to a generic directory
search.

The present approach has the following interesting features:
1) enabling fuzzy search
2) being very fast (<100ms), and being low on CPU consumption, even when no
   filter is applied on directories to scan
3) not having to manually repeat the same command (thus the loop)

Note that running `fzf` directly enables fuzzy search on the entire path of
directories, which is often wanted, but at the detriment of feature 2 above.

# Alternatives

A very simple alternative is to use
[`ranger`](https://github.com/ranger/ranger) like so: `source ranger`. The
`recdl` is much more basic and can be easily customized.
