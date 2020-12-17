module TestData exposing (..)

text: String
text =
    """


\\begin{mathmacro}
\\newcommand{\\A}[0]{\\mathbb{A}}
\\newcommand{\\B}[0]{\\text{B}}
\\newcommand{\\C}[0]{\\mathbb{C}}
\\newcommand{\\Dcal}[0]{\\mathcal{D}}
\\newcommand{\\Ecal}[0]{\\mathcal{E}}
\\newcommand{\\Fcal}[0]{\\mathcal{F}}
\\newcommand{\\G}[0]{\\mathbb{G}}
\\newcommand{\\g}[0]{\\mathfrak{g}}
\\newcommand{\\Hcal}[0]{\\mathcal{H}}
\\newcommand{\\Ical}[0]{\\mathcal{I}}
\\newcommand{\\K}[0]{\\mathbb{K}}
\\newcommand{\\Kcal}[0]{\\mathcal{K}}
\\newcommand{\\Lcal}[0]{\\mathcal{L}}
\\newcommand{\\Mcal}[0]{\\mathcal{M}}
\\newcommand{\\N}[0]{\\mathbb{N}}
\\newcommand{\\Ncal}[0]{\\mathcal{N}}
\\newcommand{\\Ocal}[0]{\\mathcal{O}}
\\newcommand{\\Pro}[0]{\\mathbb{P}}
\\newcommand{\\Pcal}[0]{\\mathcal{P}}
\\newcommand{\\Q}[0]{\\mathbb{Q}}
\\newcommand{\\Qcal}[0]{\\mathcal{Q}}
\\newcommand{\\R}[0]{\\mathbb{R}}
\\newcommand{\\Scal}[0]{\\mathcal{S}}
\\newcommand{\\Tcal}[0]{\\mathcal{T}}
\\newcommand{\\Ucal}[0]{\\mathcal{U}}
\\newcommand{\\Xcal}[0]{\\mathcal{X}}
\\newcommand{\\Ycal}[0]{\\mathcal{Y}}
\\newcommand{\\Z}[0]{\\mathbb{Z}}
\\newcommand{\\Zcal}[0]{\\mathcal{Z}}
\\newcommand{\\cart}[0]{\\ar @{} [dr] |{\\Box}}
\\newcommand{\\Hom}[0]{\\text{Hom}}
\\newcommand{\\Isom}[0]{\\text{Isom}}
\\newcommand{\\Pic}[0]{\\text{Pic}}
\\newcommand{\\GL}[0]{\\text{GL}}
\\newcommand{\\PGL}[0]{\\text{PGL}}
\\newcommand{\\SL}[0]{\\text{SL}}
\\newcommand{\\Sym}[0]{\\text{Sym}}
\\newcommand{\\Spec}[0]{\\text{Spec}}
\\newcommand{\\un}[0]{\\underline}
\\newcommand{\\pr}[0]{\\text{pr}}
\\newcommand{\\ov}[0]{\\overline}
\\newcommand{\\im}[0]{\\text{Im}}
\\newcommand{\\wh}[0]{\\widehat}
\\newcommand{\\wt}[1]{\\widetilde}
\\newcommand{\\ev}[0]{\\text{ev}}
\\newcommand{\\Char}[0]{\\text{char}}
\\newcommand{\\Bl}[0]{\\text{Bl}}
\\newcommand{\\M}[0]{\\text{M}}
\\newcommand{\\Sch}[0]{\\text{Sch}}
\\newcommand{\\di}[1]{\\displaystyle}
\\end{mathmacro}

\\title{Test}
% \\author{James Carlson}
% \\email{jxxcarlson@gmail.com}
% \\date{August 5, 2018}s

\\maketitle

% EXAMPLE 1

\\begin{comment}
This multi-line comment
should also not
be visible in the
rendered text.
\\end{comment}



\\section{Test A: $a^2 + b^2 = c^2$}



\\section{Test B: $\\Mcal$}

"""