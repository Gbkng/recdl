# About recdl

A read-eval-cd-loop simple `sh`-compliant shell function.

The present `recdl.sh` shell script defines the `recdl` function, which repeats the
following `read-eval-cd` cycle:

- Scan directories in the current working directory
- Let the user interactively choose a directory (see
  [`fzf`](https://github.com/junegunn/fzf) documentation for more information)
- `cd` to the chosen directory

To interrupt the loop, press `Escape` or `Ctrl-C`. The loop is interrupted.

The `recdl` function is basically just a convenient wrapper around `fzf`.

Note that this repository is really just a way to share the basic idea of
combining `fd` and `fzf` to create a a `read-eval-cd` loop. It is not meant to
become a standalone application.

# Installation

Simply clone this repository and `source` (or `.`, on `sh`) the `recdl.sh`
script.

Alternatively, you can copy the `recdl` function of the `recdl.sh` script
directly inside your shell configuration. It allows you to customize the
function to your needs, making it independent from possible future updates.

# Usage

```sh
$ recdl
```

Hit `Enter` to select a directory (read
[`fzf`](https://github.com/junegunn/fzf) usage instructions for more
information)

Hit `Ctrl-C` or `Escape` to interrupt the loop, leaving your shell in the last
selected directory.

The `hrecdl` alias allows to run `recdl` from the `$HOME` directory. Usage is
the same.

# Requirements

- [`fzf`](https://github.com/junegunn/fzf)
- [`fd`](https://github.com/sharkdp/fd) (recommended) or `find`; `find` is
available by default on most system while `fd` runs faster

# Rationale

Running `fzf` directly from `$HOME` is not always satisfactory, as too many
directories are scanned recursively, leading to high CPU and power
usage.

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

A very simple alternative could be to use
[`ranger`](https://github.com/ranger/ranger) like so: `source ranger`. The
`recdl` is much more basic and can be easily customized.
