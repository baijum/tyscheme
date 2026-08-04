TARGET   = index
FIGURE   = numint
MPOST   ?= mpost
LUATEX  ?= luatex
TEXFLAGS = -interaction=nonstopmode

# docmacro.tex does \input tex2page unconditionally, even for the PDF build,
# so the tex2page macro package (not just the HTML-generation tool) must be
# on the TeX search path. It isn't part of TeX Live, so a copy is vendored
# here (see vendor/tex2page/COPYING for its license).
export TEXINPUTS := .:vendor/tex2page:$(TEXINPUTS)

.PHONY: all pdf clean distclean

all: pdf

pdf: $(TARGET).pdf

# index.tex embeds a MetaPost figure (numint.mp) that it writes out to disk
# via \verbwritefile the first time it is run, and it errors out trying to
# include the figure's EPS output before mpost has generated it (see
# README.adoc). The bootstrap pass below is only there to materialize
# numint.mp and is expected to fail once it reaches the missing EPS; mpost
# then generates the figure so the real passes never hit that error.
$(TARGET).pdf: $(TARGET).tex
	-$(LUATEX) -interaction=batchmode $(TARGET)
	$(MPOST) $(FIGURE)
	$(LUATEX) $(TEXFLAGS) $(TARGET)
	bibtex $(TARGET)
	makeindex $(TARGET)
	$(LUATEX) $(TEXFLAGS) $(TARGET)
	$(LUATEX) $(TEXFLAGS) $(TARGET)

# index.tex and its chapters embed their code listings via \verbwritefile,
# which writes each one out as a standalone .scm file when TeX runs; Z-sec-temp.tex
# and index.xrf are scratch files written by the same macro package.
clean:
	rm -f *.aux *.log *.idx *.ind *.ilg *.toc *.bbl *.blg *.out *.mpx \
	      $(FIGURE).mp $(FIGURE).log $(FIGURE)-*.eps \
	      Z-sec-temp.tex index.xrf *.scm

distclean: clean
	rm -f $(TARGET).pdf
