# AVL (Athena Vortex Lattice) is the work of Mark Drela and Harold Youngren
# at MIT. This formula does NOT modify any AVL numerical or aerodynamic
# code — it builds the official MIT tarball verbatim and only swaps the
# X11 windowing layer (plotlib/xwin11/Xwin2.c) for a no-op stub so the
# binary links without XQuartz. Upstream: https://web.mit.edu/drela/Public/web/avl/
class Avl < Formula
  desc "Athena Vortex Lattice by Drela & Youngren (MIT) — headless build, no X11"
  homepage "https://web.mit.edu/drela/Public/web/avl/"
  url "https://web.mit.edu/drela/Public/web/avl/avl3.52.tgz"
  version "3.52"
  sha256 "0b588ecea9222f5b625d0af0c87ae31daf3cdba1532cf0bbb36f93d6e854849b"
  license "GPL-2.0-or-later"

  depends_on "gcc" # provides gfortran

  def install
    # Headless build: replace the X11 windowing layer with no-op stubs that
    # expose every symbol the rest of the plot library expects to link
    # against. MSKBITS is pure bit-math and is preserved verbatim from the
    # upstream MIT Xwin2.c so any caller that relies on its exact behavior
    # (including its quirky `exit(0)` on an empty mask) stays bit-identical
    # to the canonical distribution. Numerical AVL code is not touched.
    xwin = buildpath/"plotlib/xwin11/Xwin2.c"
    xwin.unlink
    xwin.write headless_xwin_stub

    # Drop X11 paths from plotlib's gfortran-DP config and the AVL bin Makefile.
    inreplace "plotlib/config.make.gfortranDP" do |s|
      s.gsub!(/^LINKLIB\s*=.*$/, "LINKLIB =")
      s.gsub!(/^INCDIR\s*=.*$/,  "INCDIR =")
    end

    inreplace "bin/Makefile.gfortranDP" do |s|
      s.gsub!(%r{^PLTLIB\s*=\s*-L/opt/X11/lib\s+-lX11\s*$}, "PLTLIB =")
    end

    fc = Formula["gcc"].opt_bin/"gfortran"

    # 1) plot library (with stubbed X11 layer)
    cd "plotlib" do
      system "make", "gfortranDP", "FC=#{fc}"
    end

    # 2) eispack
    cd "eispack" do
      system "make", "-f", "Makefile.gfortran", "FC=#{fc}"
    end

    # 3) avl binary
    cd "bin" do
      system "make", "-f", "Makefile.gfortranDP", "FC=#{fc}", "avl"
      bin.install "avl"
    end

    # User-facing docs and example session/run files.
    doc.install Dir["avl_doc*.txt"].first => "avl_doc.txt" if Dir["avl_doc*.txt"].any?
    doc.install "session1.txt", "session2.txt", "version_notes.txt", "README"
    pkgshare.install "runs"
  end

  def caveats
    <<~EOS
      This is a HEADLESS build of AVL — the X11/XQuartz plot windows are
      replaced with no-op stubs. AVL still runs, reads .avl geometry files,
      executes OPER/MODE/etc. commands from stdin or scripts, and writes
      every text/data output file (forces, stability derivatives, strip
      forces, body axis derivatives, eigenmode listings, etc.).

      Interactive plot commands ("G" in OPER, "EX" eigenmode plots, etc.)
      will silently do nothing — there is no graphics output device.

      Example run files are installed at:
        #{HOMEBREW_PREFIX}/share/avl/runs

      Try a sanity check:
        avl #{HOMEBREW_PREFIX}/share/avl/runs/vanilla
    EOS
  end

  test do
    # AVL prints its banner and an "AVL c>" prompt before reading commands.
    # Feed it an immediate Quit so it exits cleanly, and confirm the banner
    # mentions the version we built.
    output = pipe_output("#{bin}/avl", "QUIT\n", 0)
    assert_match "AVL", output
    assert_match "3.52", output
  end

  private

  # No-op replacement for plotlib/xwin11/Xwin2.c. Mirrors every public
  # symbol of the upstream X11 implementation, but performs no drawing
  # and links no X libraries. MSKBITS is preserved verbatim.
  def headless_xwin_stub
    <<~C
      /* Headless no-op replacement for Xplot11/xwin11/Xwin2.c.
         Provides the same Fortran-callable symbol set as the X11
         implementation. The MSKBITS utility is preserved verbatim
         from the upstream MIT distribution. */

      #include <stdio.h>
      #include <stdlib.h>
      #include <string.h>

      #ifdef UNDERSCORE
      #define MSKBITS          mskbits_
      #define GWXREVFLAG       gwxrevflag_
      #define GWXOPEN          gwxopen_
      #define GWXWINOPEN       gwxwinopen_
      #define GWXCLEAR         gwxclear_
      #define GWXSTATUS        gwxstatus_
      #define GWXRESIZE        gwxresize_
      #define GWXRESET         gwxreset_
      #define GWXCLOSE         gwxclose_
      #define GWXFLUSH         gwxflush_
      #define GWXLINE          gwxline_
      #define GWXDASH          gwxdash_
      #define GWXCURS          gwxcurs_
      #define GWXCURSC         gwxcursc_
      #define GWXPEN           gwxpen_
      #define GWXDESTROY       gwxdestroy_
      #define GWXLINEZ         gwxlinez_
      #define GWXPOLY          gwxpoly_
      #define GWXSTRING        gwxstring_
      #define GWXSETCOLOR      gwxsetcolor_
      #define GWXSETBGCOLOR    gwxsetbgcolor_
      #define GWXCOLORNAME2RGB gwxcolorname2rgb_
      #define GWXALLOCRGBCOLOR gwxallocrgbcolor_
      #define GWXFREECOLOR     gwxfreecolor_
      #define GWXDISPLAYBUFFER gwxdisplaybuffer_
      #define GWXDRAWTOBUFFER  gwxdrawtobuffer_
      #define GWXDRAWTOWINDOW  gwxdrawtowindow_
      #else
      #define MSKBITS          mskbits
      #define GWXREVFLAG       gwxrevflag
      #define GWXOPEN          gwxopen
      #define GWXWINOPEN       gwxwinopen
      #define GWXCLEAR         gwxclear
      #define GWXSTATUS        gwxstatus
      #define GWXRESIZE        gwxresize
      #define GWXRESET         gwxreset
      #define GWXCLOSE         gwxclose
      #define GWXFLUSH         gwxflush
      #define GWXLINE          gwxline
      #define GWXDASH          gwxdash
      #define GWXCURS          gwxcurs
      #define GWXCURSC         gwxcursc
      #define GWXPEN           gwxpen
      #define GWXDESTROY       gwxdestroy
      #define GWXLINEZ         gwxlinez
      #define GWXPOLY          gwxpoly
      #define GWXSTRING        gwxstring
      #define GWXSETCOLOR      gwxsetcolor
      #define GWXSETBGCOLOR    gwxsetbgcolor
      #define GWXCOLORNAME2RGB gwxcolorname2rgb
      #define GWXALLOCRGBCOLOR gwxallocrgbcolor
      #define GWXFREECOLOR     gwxfreecolor
      #define GWXDISPLAYBUFFER gwxdisplaybuffer
      #define GWXDRAWTOBUFFER  gwxdrawtobuffer
      #define GWXDRAWTOWINDOW  gwxdrawtowindow
      #endif

      void GWXREVFLAG(int *revflag) { *revflag = 0; }

      void GWXOPEN(int *xsizeroot, int *ysizeroot, int *depth) {
          *xsizeroot = 800; *ysizeroot = 600; *depth = 24;
      }

      void GWXWINOPEN(int *xstart, int *ystart, int *xsize, int *ysize) {
          (void)xstart; (void)ystart; (void)xsize; (void)ysize;
      }

      void GWXCLEAR(void)       {}
      void GWXCLOSE(void)       {}
      void GWXDESTROY(void)     {}
      void GWXFLUSH(void)       {}
      void GWXDISPLAYBUFFER(void) {}
      void GWXDRAWTOBUFFER(void)  {}
      void GWXDRAWTOWINDOW(void)  {}
      void GWXRESET(void)       {}

      void GWXSTATUS(unsigned int *xstart, unsigned int *ystart,
                     unsigned int *xsize,  unsigned int *ysize) {
          *xstart = 0; *ystart = 0; *xsize = 800; *ysize = 600;
      }

      void GWXRESIZE(int *x, int *y) { (void)x; (void)y; }

      void GWXLINE(int *x1, int *y1, int *x2, int *y2) {
          (void)x1; (void)y1; (void)x2; (void)y2;
      }
      void GWXLINEZ(int *ix, int *iy, int *n) { (void)ix; (void)iy; (void)n; }
      void GWXPOLY(int *xc, int *yc, int *n)  { (void)xc; (void)yc; (void)n; }
      void GWXSTRING(int *x, int *y, char *s, int *len) {
          (void)x; (void)y; (void)s; (void)len;
      }
      void GWXDASH(int *lmask) { (void)lmask; }
      void GWXPEN(int *ipen)   { (void)ipen; }

      void GWXSETCOLOR(int *pixel)   { (void)pixel; }
      void GWXSETBGCOLOR(int *pixel) { (void)pixel; }

      void GWXCOLORNAME2RGB(int *red, int *grn, int *blu,
                            int *nc, char *colorname, int len) {
          (void)colorname; (void)len;
          *red = 0; *grn = 0; *blu = 0;
          *nc  = -1;  /* color-not-found: lets callers fall back gracefully */
      }

      void GWXALLOCRGBCOLOR(int *red, int *grn, int *blu, int *ic) {
          (void)red; (void)grn; (void)blu;
          *ic = -1;
      }

      void GWXFREECOLOR(int *pix) { (void)pix; }

      /* Cursor input — in headless mode there is no plot window to click in.
         Return ESC (27) so AVL's interactive plot menus exit cleanly the
         moment they ask for cursor input, and signal "no button" for the
         button-down variant. */
      void GWXCURS(int *x, int *y, int *state) {
          (void)x; (void)y;
          *state = 27;
      }
      void GWXCURSC(int *x, int *y, int *btn) {
          (void)x; (void)y;
          *btn = -1;
      }

      /* MSKBITS — verbatim from upstream MIT Xwin2.c. Pure bit-pattern
         utility used elsewhere in the plot library (for line dash patterns).
         Preserved exactly so headless builds remain bit-identical to the
         canonical AVL distribution wherever this routine is reachable. */
      void
      MSKBITS(int* mask, int* ibits, int* ndash)
      {
      #define BITSINMASK 16

      int            i,ic,ibit,ibitold;
      int            nbits, nshft;
      unsigned short lmask;

      	  lmask = *mask;
                nshft = ibitold = 0;

      	  if(lmask!=0) {
       	    while (!(ibitold = (lmask & 0x01)))
                  lmask >>= 1;
                  nshft++;
      	  }
                if(ibitold==0) {
      	    *ndash = 0;
      	    exit(0);
      	  }

          	  nbits = ic = ibit = 0;

      	  for (i=0; i<(BITSINMASK-nshft); ++i) {

      	    ibit=(lmask & 0x01);

      	    if(ibit != ibitold) {
      	      ibits[ic++] = nbits;
      	      nbits = 0;
      	     }

                  ibitold = ibit;
                  nbits++;

      	    lmask >>= 1;
      	  }

      	  if(ibit==1) {

                  ibits[ic++] = nbits;
                  if(nshft>0)
                    ibits[ic++] = nshft;

      	    }
                 else
          	    ibits[ic++] = nbits + nshft;

      	  *ndash = ic;
      }
    C
  end
end
