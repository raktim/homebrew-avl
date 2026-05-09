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

prints the 3.52 banner and exits 0.

## Examples

The example geometries shipped by MIT are installed under
`$(brew --prefix)/share/avl/runs`. The snippets below use the
`vanilla` case (a small RC-style trainer) and drive AVL non-interactively
from a heredoc. All numerical output below is real, produced by the
formula in this tap.

### Trim and total forces

    avl $(brew --prefix)/share/avl/runs/vanilla.avl <<'EOF' >/dev/null
    OPER
    X
    FT
    forces.txt

    QUIT
    EOF

`forces.txt` then contains the trim solution:

      Alpha =  11.62169     pb/2V =  -0.00000     p'b/2V =  -0.00000
      Beta  =   0.00000     qc/2V =   0.00000
      Mach  =     0.000     rb/2V =  -0.00000     r'b/2V =  -0.00000
      ...
      CLtot =   1.16647
      CDtot =   0.04327
      CDvis =   0.00000     CDind = 0.0432724
      CLff  =   1.16562     CDff  = 0.0431610    | Trefftz
      CYff  =   0.00000         e =    0.9018    | Plane

### Stability derivatives and neutral point

Replace `FT` above with `ST` to get the full Jacobian in stability axes:

      Stability-axis derivatives...

                                  alpha                beta
                       ----------------    ----------------
      z' force CL |    CLa =   4.724462    CLb =   0.000000
      y  force CY |    CYa =  -0.000000    CYb =  -0.266470
      x  force CD |    CDa =   0.350776    CDb =  -0.000000
      x' mom.  Cl'|    Cla =  -0.000000    Clb =  -0.183969
      y  mom.  Cm |    Cma =  -0.284327    Cmb =   0.000000
      z' mom.  Cn'|    Cna =  -0.000000    Cnb =   0.017176

                       roll rate  p'      pitch rate  q'        yaw rate  r'
                       ----------------    ----------------    ----------------
      z' force CL |    CLp =  -0.000000    CLq =   4.540877    CLr =   0.000000
      ...
      Neutral point  Xnp =   0.704164

`SB` gives the same derivatives in body axes.

### Alpha sweep

Loop in shell, drive AVL once per α:

    for a in -2 0 2 4 6 8 10; do
      avl $(brew --prefix)/share/avl/runs/vanilla.avl <<EOF >/dev/null
    OPER
    A A $a
    X
    FT
    sweep_a${a}.txt

    QUIT
    EOF
    done

Result for the vanilla case:

       alpha       CL          CD
        -2      0.00249     0.00000
         0      0.17843     0.00103
         2      0.35328     0.00405
         4      0.52664     0.00897
         6      0.69810     0.01571
         8      0.86725     0.02414
        10      1.03372     0.03413

### Eigenmode analysis

    avl $(brew --prefix)/share/avl/runs/vanilla.avl <<'EOF' >/dev/null
    OPER
    X

    MODE
    N
    W
    modes.txt

    QUIT
    EOF

`modes.txt` lists the system eigenvalues for each run case (run case
index, then real and imaginary parts in the last two columns). Run
case 1 of `vanilla` gives the eight roots

         -2.16687              0
         -1.21899   ±   1.05570j
         -0.06190              0
         -0.01685   ±   0.29517j
          0.06859   ±   1.11060j

with imaginary parts in rad / (Lref / Vref). Pairing with the
eigenvectors recovers the usual phugoid / short-period / Dutch-roll /
roll-subsidence / spiral classification; the table above is just to
show that the analysis runs end-to-end without a graphics device.

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
