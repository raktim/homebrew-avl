# homebrew-avl

A Homebrew tap that installs **AVL** — *Athena Vortex Lattice* — on
macOS, built directly from MIT's canonical source distribution.

## Credit

AVL is the work of **Mark Drela** and **Harold Youngren** at MIT.
This repository contains **only** a Homebrew packaging shim and a small
no-op replacement for the X11 windowing layer; **all numerical and
aerodynamic code is taken verbatim from the upstream MIT distribution**
and is unmodified. Please cite and credit Drela & Youngren for any
analysis you publish.

- Upstream source and documentation: <https://web.mit.edu/drela/Public/web/avl/>
- AVL is distributed under the GNU General Public License, version 2 or later.
- This packaging is unaffiliated with MIT; it just makes `brew install avl`
  work on macOS without requiring XQuartz.

## What this tap does

This is a **headless build**: the X11/XQuartz windowing layer is replaced
with no-op stubs so AVL runs from the command line, reads `.avl` geometry
files, executes OPER / MODE / TIME commands, and writes every text and
data output file — without requiring XQuartz to be installed. Only the
interactive plot windows are unavailable. All numerical AVL/eispack code
is built verbatim from the upstream tarball.

## Install

```sh
brew tap raktim/avl
brew install avl
```

The formula depends on `gcc` (for `gfortran`); Homebrew will pull it in if
it isn't already present.

## Verify

```sh
echo QUIT | avl                 # banner + main menu, then clean exit
avl $(brew --prefix avl)/share/avl/runs/vanilla.avl <<'EOF'
OPER
x
ft
total.txt

quit
EOF
```

The second command should produce `total.txt` in the working directory
with `CLtot ≈ 1.166`, `CDtot ≈ 0.0433`, `α ≈ 11.6°` for the vanilla case
— bit-identical to running MIT's prebuilt `avl` binary on the same input.

## What's built and what isn't

| Component | Status |
| --- | --- |
| AVL Fortran sources (src/) | unchanged, gfortran double-precision |
| eispack (eigenvalue solver) | unchanged, double-precision |
| `matrix-lapackdp` + bundled LAPACK/BLAS sources | unchanged |
| plotlib (`libPlt_gDP.a`) | unchanged Fortran sources |
| `plotlib/xwin11/Xwin2.c` | replaced with no-op stubs (`MSKBITS` preserved verbatim) |
| X11 / XQuartz dependency | **removed** |
| Interactive plot windows (G, T, EX, etc.) | silently no-op |
| Text/data output (FT, FN, FS, FE, FB, ST, SB, HM, VM, MRF, ...) | fully functional |

The numerical core is byte-for-byte the same as MIT's distribution. Only
the X11 windowing C layer is swapped — see `Formula/avl.rb` for the exact
stubbed symbols.

## Files

```
Formula/
  avl.rb       # the formula (fetches avl3.52.tgz, applies headless patch)
README.md      # this file
```

## Updating the formula

When MIT releases a new `avl3.XX.tgz`:

1. Download it and recompute `sha256` with `shasum -a 256 avl3.XX.tgz`.
2. Update `url`, `version`, and `sha256` in `Formula/avl.rb`.
3. If `plotlib/xwin11/Xwin2.c` adds new public symbols, extend the
   `headless_xwin_stub` heredoc with no-op stubs for them.
4. Test locally:
   ```sh
   brew tap-new --no-git local/avl
   cp Formula/avl.rb "$(brew --repository)/Library/Taps/local/homebrew-avl/Formula/"
   brew install --build-from-source local/avl/avl
   brew test local/avl/avl
   ```

## License

AVL itself is GPL-2.0-or-later — copyright **Mark Drela & Harold
Youngren**. The formula and the headless `Xwin2.c` stub in this repository
are also GPL-2.0-or-later, as derivative works of the AVL distribution.

This packaging is provided "as is" with no warranty, in keeping with the
upstream license.
