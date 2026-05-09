# AVL on macOS via Homebrew

A small tap that builds Mark Drela's AVL (Athena Vortex Lattice) from
its MIT source distribution. The build skips X11, so XQuartz is not
required.

## Install

    brew tap raktim/avl
    brew install avl

`gfortran` is pulled in through the `gcc` formula if it is not already
on the system.

## What the formula does

It downloads `avl3.52.tgz` from web.mit.edu, replaces
`plotlib/xwin11/Xwin2.c` with a stub that exposes the same set of
Fortran-callable symbols (`gwxopen`, `gwxline`, and 25 others) as no-ops,
and otherwise compiles the source as shipped. The Fortran sources, the
`eispack` library, and the bundled LAPACK subset are unchanged.
`MSKBITS`, the bit-pattern routine used for dashed lines, is copied from
the original Xwin2.c rather than stubbed.

The resulting `avl` binary runs all OPER, MODE, and TIME commands and
writes every output file the upstream binary writes. Commands that
would open a plot window do nothing.

## Sanity check

    echo QUIT | avl

prints the 3.52 banner and exits 0. For a fuller check, the `vanilla`
example installed under `$(brew --prefix)/share/avl/runs` trims to
CL = 1.166, CD = 0.0433 at α = 11.6°, which matches the upstream
binary on the same input.

## Updating to a new AVL release

1. Run `shasum -a 256 avl3.XX.tgz` and update `url`, `version`, and
   `sha256` in `Formula/avl.rb`.
2. If new public symbols appear in `plotlib/xwin11/Xwin2.c`, add no-op
   counterparts to `headless_xwin_stub` in the formula.
3. `brew install --build-from-source raktim/avl/avl` and `brew test`.

## Citation

AVL is by Mark Drela and Harold Youngren. Cite the program and the
user primer at web.mit.edu/drela/Public/web/avl for any work that
relies on its results. This tap is a build script; the science is
theirs.

## License

GPL-2.0-or-later, matching the upstream AVL distribution.
