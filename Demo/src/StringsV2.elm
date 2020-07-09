module StringsV2 exposing (anharmonic, initialText, macros, mathExampleText)


macros =
    """
\\def\\half{\\small\\frac{1}{2}}
\\def\\bbR{\\mathbb{R}}
\\def\\caA{\\mathcal{A}}
\\def\\caC{\\mathcal{C}}
\\def\\caD{\\mathcal{D}}
\\def\\caF{\\mathcal{F}}
\\def\\caL{\\mathcal{L}}
\\def\\caP{\\mathcal{P}}
\\def\\UUU{\\mathcal{U}}
\\def\\FFF{\\mathcal{F}}
\\def\\ZZ{\\mathbb{Z}}
\\def\\UU{\\mathbb{U}}
\\def\\CC{\\mathbb{C}}
\\newcommand{\\boa}{\\mathbf{a}}
\\newcommand{\\boi}{\\mathbf{i}}
\\newcommand{\\bop}{\\mathbf{p}}
\\newcommand{\\boF}{\\mathbf{F}}
\\newcommand{\\boL}{\\mathbf{L}}
\\newcommand{\\bor}{\\mathbf r }
\\newcommand{\\boR}{{\\bf R}}
\\newcommand{\\bov}{\\mathbf v }
\\newcommand{\\sinc}{\\,\\text{sinc}\\,}
\\newcommand{\\bra}{\\langle}
\\newcommand{\\ket}{\\rangle}
\\newcommand{\\set}[1]{\\{#1\\}}
\\newcommand{\\sett}[2]{\\{ #1 | #2 \\}}
\\def\\card{{\\bf card}\\; }
\\def\\id{\\mathbf{1}}
"""


macros2 =
    """
$$
\\newcommand{\\bra}{\\langle}
\\newcommand{\\ket}{\\rangle}

\\newcommand{\\set}[1]{\\{\\ #1 \\ \\}}
\\newcommand{\\sett}[2]{\\{\\ #1 \\ |\\ #2 \\}}
\\newcommand{\\id}{\\mathbb{\\,I\\,}}
$$
"""


initialText =
    """

\\title{Sample MiniLaTeX Doc}

\\begin{mathmacro}
\\newcommand{\\bt}[1]{\\bf{#1}}
\\newcommand{\\mca}[0]{\\mathcal{A}}
\\end{mathmacro}

\\begin{textmacro}
\\newcommand{\\boss}{Phineas Fogg}
\\newcommand{\\hello}[1]{Hello \\strong{#1}!}
\\newcommand{\\reverseconcat}[3]{#3#2#1}
\\end{textmacro}

\\maketitle

% EXAMPLE 1

\\tableofcontents

\\section{Introduction}

MiniLatex is a subset of LaTeX that can be
rendered live in the browser using a custom just-in-time compiler.
Mathematical text is rendered by \\href{https://mathjax.org}{MathJax}:

$$
\\int_{-\\infty}^\\infty e^{-x^2} dx = \\pi
$$

The combination of MiniLaTeX and MathJax
gives you access to both text-mode
and math-mode LaTeX in the browser.

Feel free to
experiment with MiniLatex using this app
\\mdash you can change the text in the
left-hand window, or clear it and enter
your own text. Use the \\blue{export} button
below to export the text you write to a
LaTeX document on your computer.  It can
be processed as-is by any program that runs LaTeX,
e.g, TeXShop or \\code{pdflatex}.


Images in MiniLaTeX are accessed by URL (see the example
in section 4 below). When you export a document, images
used in it will be listed to the right
of the rendered text.  To use them in the exported
document, right (option) click on the image and
save it in a folder named \\italic{image}.

For more information about
the MiniLaTeX project, please go to
\\href{https://minilatex.io}{minilatex.io},
or write to jxxcarlson at gmail.

\\section{Try it out}

\\italic{Try editing formula \\eqref{integral:xn} or \\eqref{integral:exp} below.}
Note, e.g., from the source text, that the formulas are written inside
equation environments.

The most basic integral:

\\begin{equation}
\\label{integral:xn}
\\int_0^1 x^n dx = \\frac{1}{n+1}
\\end{equation}

An improper integral:

\\begin{equation}
\\label{integral:exp}
\\int_0^\\infty e^{-x} dx = 1
\\end{equation}

An equation alignment:

\\begin{align}
2x + 3y &= 1 \\\\
-x + 5y &= 2 \\\\
\\end{align}


\\section{Theorems}

\\begin{theorem}
There are infinitely many prime numbers.
\\end{theorem}

\\begin{theorem}
There are infinitley many prime numbers
$p$ such that $p \\equiv 1\\ mod\\ 4$.
\\end{theorem}

\\section{Images}

\\image{http://psurl.s3.amazonaws.com/images/jc/beats-eca1.png}{Figure 1. Two-frequency beats}{width: 350, align: center}

\\section{SVG}

\\begin{svg}
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0" y="0" width="381.603" height="250.385" viewBox="0, 0, 381.603, 250.385">
  <g id="Layer_1">
    <g>
      <path d="M95.401,166.09 L71.5,124.692 L95.401,83.295 L143.203,83.295 L167.103,124.692 L143.202,166.09 z" fill="#CCDD10"/>
      <path d="M95.401,166.09 L71.5,124.692 L95.401,83.295 L143.203,83.295 L167.103,124.692 L143.202,166.09 z" fill-opacity="0" stroke="#000000" stroke-width="1"/>
    </g>
    <g>
      <path d="M166.401,126.09 L142.5,84.692 L166.401,43.295 L214.203,43.295 L238.103,84.692 L214.202,126.09 z" fill="#0D9B53"/>
      <path d="M166.401,126.09 L142.5,84.692 L166.401,43.295 L214.203,43.295 L238.103,84.692 L214.202,126.09 z" fill-opacity="0" stroke="#000000" stroke-width="1"/>
    </g>
    <g>
      <path d="M167.401,207.885 L143.5,166.487 L167.401,125.09 L215.203,125.09 L239.103,166.487 L215.202,207.885 z" fill="#0D9B53"/>
      <path d="M167.401,207.885 L143.5,166.487 L167.401,125.09 L215.203,125.09 L239.103,166.487 L215.202,207.885 z" fill-opacity="0" stroke="#000000" stroke-width="1"/>
    </g>
    <g>
      <path d="M309.401,209.885 L285.5,168.487 L309.401,127.09 L357.203,127.09 L381.103,168.487 L357.203,209.885 z" fill="#0D9B53"/>
      <path d="M309.401,209.885 L285.5,168.487 L309.401,127.09 L357.203,127.09 L381.103,168.487 L357.203,209.885 z" fill-opacity="0" stroke="#000000" stroke-width="1"/>
    </g>
    <g>
      <path d="M309.401,125.09 L285.5,83.692 L309.401,42.295 L357.203,42.295 L381.103,83.692 L357.203,125.09 z" fill="#0D9B53"/>
      <path d="M309.401,125.09 L285.5,83.692 L309.401,42.295 L357.203,42.295 L381.103,83.692 L357.203,125.09 z" fill-opacity="0" stroke="#000000" stroke-width="1"/>
    </g>
    <g>
      <path d="M23.401,126.09 L-0.5,84.692 L23.401,43.295 L71.203,43.295 L95.103,84.692 L71.203,126.09 z" fill="#0D9B53"/>
      <path d="M23.401,126.09 L-0.5,84.692 L23.401,43.295 L71.203,43.295 L95.103,84.692 L71.203,126.09 z" fill-opacity="0" stroke="#000000" stroke-width="1"/>
    </g>
    <g>
      <path d="M237.401,84.295 L213.5,42.897 L237.401,1.5 L285.203,1.5 L309.103,42.897 L285.203,84.295 z" fill="#CCDD10"/>
      <path d="M237.401,84.295 L213.5,42.897 L237.401,1.5 L285.203,1.5 L309.103,42.897 L285.203,84.295 z" fill-opacity="0" stroke="#000000" stroke-width="1"/>
    </g>
    <g>
      <path d="M239.401,249.885 L215.5,208.487 L239.401,167.09 L287.203,167.09 L311.103,208.487 L287.203,249.885 z" fill="#CCDD10"/>
      <path d="M239.401,249.885 L215.5,208.487 L239.401,167.09 L287.203,167.09 L311.103,208.487 L287.203,249.885 z" fill-opacity="0" stroke="#000000" stroke-width="1"/>
    </g>
    <g>
      <path d="M94.401,84.295 L70.5,42.897 L94.401,1.5 L142.203,1.5 L166.103,42.897 L142.202,84.295 z" fill="#CCDD10"/>
      <path d="M94.401,84.295 L70.5,42.897 L94.401,1.5 L142.203,1.5 L166.103,42.897 L142.202,84.295 z" fill-opacity="0" stroke="#000000" stroke-width="1"/>
    </g>
    <g>
      <path d="M333.302,94.897 C327.411,94.897 322.635,90.328 322.635,84.692 C322.635,79.056 327.411,74.487 333.302,74.487 C339.193,74.487 343.968,79.056 343.968,84.692 C343.968,90.328 339.193,94.897 333.302,94.897 z" fill="#D60B8E"/>
      <path d="M333.302,94.897 C327.411,94.897 322.635,90.328 322.635,84.692 C322.635,79.056 327.411,74.487 333.302,74.487 C339.193,74.487 343.968,79.056 343.968,84.692 C343.968,90.328 339.193,94.897 333.302,94.897 z" fill-opacity="0" stroke="#000000" stroke-width="1"/>
    </g>
  </g>
</svg>
\\end{svg}

\\section{Lists}

\\begin{itemize}

\\item This is \\strong{just} a test.

\\item \\italic{And so is this:} $a^2 + b^2 = c^2$

\\begin{itemize}

\\item Items can be nested

\\item And you can do this: $ \\frac{1}{1 + \\frac{2}{3}} $

\\end{itemize}

\\end{itemize}

\\section{Tables}

\\begin{indent}
\\begin{tabular}{ l l l l }
Hydrogen & H & 1 & 1.008 \\\\
Helium & He & 2 & 4.003 \\\\
Lithium& Li & 3 & 6.94 \\\\
Beryllium& Be& 4& 9.012 \\\\
\\end{tabular}
\\end{indent}

\\section{Math-mode macros}

Math-mode macros are added using the \\code{mathmacro} environment:

\\begin{verbatim}
\\begin{mathmacro}
\\newcommand{\\bt}[1]{\\bf{#1}}
\\newcommand{\\mca}[0]{\\mathcal{A}}
\\end{mathmacro}
\\end{verbatim}

Then saying

\\begin{verbatim}
 $$
 a^2 = \\bt{Z}/\\mca
 $$
\\end{verbatim}

yields

$$
a^2 = \\bt{Z}/\\mca
$$

Likewise, saying

\\begin{verbatim}
\\begin{equation}
\\label{eq:function.type}
\\mca^{\\bt{Z}} = \\bt{Z} \\to \\mca
\\end{equation}
\\end{verbatim}

yields

\\begin{equation}
\\label{eq:function.type}
\\mca^{\\bt{Z}} = \\bt{Z} \\to \\mca
\\end{equation}

There are some restrictions:

\\begin{verbatim}
1. No regions, e.g, use \\bf{#1},
   not {\\bf #1}

2. Macros with no arguments:
   Say \\newcommand{\\mca}[0]{\\mathcal{A}},
   not \\newcommand{\\mca}{\\mathcal{A}}

3. No recursion: the body of the macro
   cannot refer to other macros defined
   in the mathmacro environment.

4. Put the mathmacro environment at
   the beginning of the document
\\end{verbatim}

Items 1—3 will be eliminated in a
future release.

\\section{Text-mode Macros}

Text-mode macros are defined in a \\code{textmacro} environment:

\\begin{verbatim}
\\begin{textmacro}
\\newcommand{\\boss}{Phineas Fogg}
\\newcommand{\\hello}[1]{Hello \\strong{#1}!}
\\newcommand{\\reverseconcat}[3]{#3#2#1}
\\end{textmacro}
\\end{verbatim}

Then

\\begin{verbatim}
\\italic{My boss is \\boss.}
\\end{verbatim}

produces \\italic{My boss is \\boss.}
Likewise, the text

\\begin{verbatim}
\\hello{John}
\\end{verbatim}

yields \\hello{John}.

\\section{MiniLatex Macros}

MiniLatex has a number of macros of its own,  For
example, text can be rendered in various colors, \\red{such as red}
and \\blue{blue}. Text can \\highlight{be highlighted}
and can \\strike{also be struck}. Here are the macros:

\\begin{verbatim}
\\red
\\blue
\\highlight
\\strike
\\end{verbatim}

\\section{Errors and related matters}

Errors, as illustrated below, are rendered in real time and are reported in red, in place.
For example, suppose you type the  text

\\begin{verbatim}
  $$
  a^2 + b^2 = c^2
\\end{verbatim}

Then you will see this in the rendered text window:

\\image{http://jxxcarlson.s3.amazonaws.com/miniLaTeXErrorMsg-2020-02-22.png}{Fig 2. Error message}{width: 200}

We plan to make further improvements in error reporting.

\\section{More about MiniLaTeX}

This app is intended as a bare-bones demonstration of what one can do with MiniLaTeX.
There are several other apps in various stages of development which
offer different or more sophisticated services:

\\begin{itemize}

\\item \\href{https://knode.io}{knode.io} is a web app for creating, editing, and distributing
MiniLaTeX documents.  Try this link: \\href{https://knode.io/424}{QM class notes on knode.io}.
Public documents can be read by anyone, but to create documents, you need to create an account
on knode.io.

\\item \\href{https://reader.minilatex.app}{reader.minilatex.app} is a read-only app for
distributing MiniLaTeX documents on the web.  Good for class notes and the like.

\\item \\italic{In development}: a desktop app for creating MiniLaTeX content. Documents
are stored on your computer's hard disk and can also be stored in the cloud.
Documents can also be posted to any website that implements the app's publishing
protocol.  The desktop app supports two document formats: MiniLaTeX and MathMarkdown,
a version of Markdown that can render math-mode LaTeX.

\\end{itemize}

For more information about these or related apps, please contact jxxcarlson at gmail.
Bug reports and feature requests are best posted on
the \\href{https://github.com/jxxcarlson/meenylatex}{Github repo} for this project,
but email is also OK.

\\section{The Technology}

MiniLatex is written in \\href{https://elm-lang.org}{Elm}, the statically typed functional
programming language created by Evan Czaplicki for building web applications.  Because of its excellent
\\href{https://package.elm-lang.org/packages/elm/parser/latest}{parser combinator library},
Elm is a good fit for a project like the present one.  Math-mode LaTeX is rendered
by \\href{https://mathjax.org}{MathJax}.  It is a pleasure to thank Davide Cervone for his
generous help with MathJax.

For an overview of the design of MiniLatex, see
\\href{https://hackernoon.com/towards-latex-in-the-browser-2ff4d94a0c08}{Towards Latex in the Browser}.
Briefly, \\href{https://www.mathjax.org/}{MathJax} is used for math-mode
text and Elm is used for text-mode material.

One feature of note is the default incremental
parsing and rendering of source text, which is needed for responsive live editing.
Source text is divided into logical paragraphs: ordinary paragraphs or an outer
begin-end block.  When a logical paragraph is modified, only that paragraph
is recompiled.  The upside of this strategy is that recompilation is very fast.
The downside is that numbering and cross-references can get out of sync.  Press
the \\blue{Full Render} button to recompile the entire document and bring everything
into sync.

\\href{https://github.com/jxxcarlson/meenylatex}{Github repo}

\\medskip

\\section{References}

\\begin{thebibliography}

\\bibitem{G} James Carlson, \\href{https://knode.io/628}{MiniLaTeX Grammar},

\\bibitem{H} James Carlson, \\href{https://hackernoon.com/towards-latex-in-the-browser-2ff4d94a0c08}{Towards LaTeX in the Browser }, Hackernoon

\\bibitem{S} \\href{http://package.elm-lang.org/packages/jxxcarlson/minilatex/latest}{Source code}

\\bibitem{T} James Carlson, \\href{https://knode.io/525}{MiniLatex Technical Report}

\\end{thebibliography}
"""


mathExampleText =
    """
% EXAMPLE 2

\\setcounter{section}{8}


\\section{Bras and Kets}

Paul Dirac invented a new notation \\mdash the notation of bras and kets \\mdash for working with hermitian inner products and operators on a Hilbert space $H$.  We describe the basics below, then elaborate on how these apply in the case of countable and continuous orthonormal bases.  We also discuss some of the mathematical issues raised by the delta function and by formulas such as

\\begin{equation}
\\int_{-\\infty}^\\infty \\frac{dx}{2\\pi}\\; | x \\ket\\bra x | = 1
\\end{equation}
a
that Dirac introduced and which abound in the physics literature.

\\subsection{The basics}

For the inner product of two vectors, we write $\\bra u | v \\ket$, where this expression is linear in the second variable and conjugate linear in the first.  Thus Dirac's $\\bra u | v \\ket$ is the mathematicians's $\\bra v, w \\ket$.

In this notations, $\\bra u | c v\\ket = c\\bra u | v \\ket$, but $\\bra cu |  v\\ket = \\bar c\\bra u | v \\ket$. The symmetry condition reads $\\bra v | u \\ket = \\overline{\\bra u  | v \\ket}$.

Let $A$ be an operator.  The expression $\\bra u | A | v \\ket$ means $\\bra u | Av \\ket$.  Thus it is the same as $\\bra A^*u | v \\ket$.

The symbol $|v\\ket$ has the same meaning as $v$ if $v$ is a vector. Such vectors are called \\term{kets}.  Let $\\set{ \\psi_a }$ be a set of states, that is, eigenvectors for an operator $A$ with eigenvalue $a$.  The notations $\\psi_a$, $|\\psi_a \\ket$, and  $|a\\ket$ all stand fors the same thing.  It makes sense to say

\\begin{equation}
A|a\\ket = a|a\\ket
\\end{equation}

The expression $\\bra u |$ is the \\term{bra} associated to $u$, where $u$ is an element of the space \\emph{dual} to $V$.  That is, $u$ is a linear functional on $V$:

\\begin{equation}
\\bra u |(v) = u(v)
\\end{equation}

If $u$ is a vector in $V$, we may define the linear functional $\\phi_u(v) = \\bra u | v \\ket$.  In this case, both sides of the equation

\\begin{equation}
\\bra u |(v) = \\bra u | v \\ket
\\end{equation}

have meaning.  For finite-dimensional spaces, we may view bras as row vectors and kets as column vectors.

Consider next the expression $| v \\ket \\bra v |$ where $v$ is a unit vector. it operates on a arbitrary vector $w$ by the rule

\\begin{equation}
  | w \\ket \\mapsto | v \\ket \\bra v | w \\ket
\\end{equation}

If $| w \\ket$ is orthogonal to $| v \\ket$, then the result is zero.  If $| w \\ket = | v \\ket$, then the result is $| v \\ket$, Therefore $| v \\ket \\bra v |$ is orthogonal projection onto $v$.


\\subsection{Resolution of the identity}

Let $\\set{ |v_n\\ket} = \\set{ |n\\ket}$ be a complete orthonormal set for $H$ which is indexed by integers $n = 0, 1, 2, \\ldots$.  We claim that

\\begin{equation}
\\label{resolutionofidentity}
\\sum_n | n \\ket \\bra n | = \\id.
\\end{equation}

That is, the expression on the left, which is a sum of projections operators, is the identity operator $\\id$.  We say that the left-hand side of \\eqref{resolutionofidentity} is  \\term{resolution of the identity}.  The proof that  \\eqref{resolutionofidentity} holds an exercise in bra-ket formalism. Let $v$ be arbitrary and write

\\begin{equation}
  v = \\sum_m | m \\ket\\bra m | v \\ket
\\end{equation}

This is the Fourier decomposition of $v$.  Note that it depends linearly on $| v \\ket$. Applying $\\sum | n \\ket\\bra n|$ to $v$, we find that

\\begin{align}
\\left(\\sum_n  | n\\ket \\bra n |\\right) \\left(\\sum_m | m \\ket\\bra m | v \\ket \\right) &=
\\sum_{m,n}  | n \\ket \\bra n |m \\ket\\bra m | v \\ket  \\\\
&= \\sum_{m,n}  | n \\ket \\delta_{n,m}\\bra m | v \\ket \\\\
& = \\sum_{m}  | m \\ket \\bra m | v \\ket \\\\
&= v
\\end{align}

\\strong{Q.E.D.}

Here the quantities $\\delta_{n,m}$ may be viewed as the elements of the identity matrix  \\mdash possibly $n\\times n$, possibly $\\infty\\times\\infty$.

Consider next an operator $\\Omega$.  Write it as

\\begin{align}
\\Omega &= \\left(\\sum_m  | m \\ket \\bra m |\\right) \\Omega \\left(\\sum_n  | n \\ket \\bra n | \\right) \\\\
&= \\sum_{m,n}  |m | \\ket \\bra m |  \\Omega | n \\ket \\bra n | & \\\\
& = \\sum_m  | m\\ket   \\Omega_{m.n} \\bra n |
\\end{align}

The operator  is determined by its \\term{matrix elements}

\\begin{equation}
\\Omega_{m,n} = \\bra m |  \\Omega | n \\ket
\\end{equation}

The matrix elements are the elements o the matrix of  $\\Omega$ in the given orthonormal basis, i.e.,  the $\\Omega_{m,n}$

One often encounters the phrase "let us insert a resolution of the identity".  To see what this means, consider the expression $\\bra m AB m \\ket$, which we expand as follows:

\\begin{align}
\\bra m | AB n | \\ket &= \\bra m | A\\id B | n \\ket \\\\
&= \\sum_i \\bra m A | i \\ket \\bra i | B n \\ket
\\end{align}

This is the same as the identity

\\begin{equation}
(AB)_{mn} = \\sum_i A_{mi} B_{in}
\\end{equation}

\\subsection{Continuous spectrum}

One also has resolution of the identity for operators with continuous spectrum.  Take, for example, the operator $-id/dx$ which has (generalized) eigenfunctions $e^{ikx}$. Writing $| k \\ket$ for $e^{ikx}$, one has

\\begin{equation}
\\id = \\frac{1}{2\\pi} \\int_{-\\infty}^\\infty dk\\, | k \\ket \\bra k |
\\end{equation}

Standing by itself, the meaning of this formula is a subtle matter.  However, when applied to a function, we have

\\begin{equation}
| f \\ket = \\frac{1}{2\\pi} \\int_{-\\infty}^\\infty dk\\, | k \\ket \\bra k | f \\ket
\\end{equation}

This is an encoding of the Fourier inversion theorem:

\\begin{equation}
f(x) = \\frac{1}{\\sqrt{2\\pi}} \\int_{-\\infty}^\\infty \\hat f(k) e^{ikx} dk
\\end{equation}




\\subsection{References}

\\href{http://ocw.mit.edu/courses/physics/8-05-quantum-physics-ii-fall-2013/lecture-notes/MIT8_05F13_Chap_04.pdf}{Dirac's Bra and Ket notation} \\mdash Notes from B. Zwiebach's course at MIT

\\href{http://www.physics.iitm.ac.in/~labs/dynamical/pedagogy/vb/delta.pdf}{All about the Dirac delta function} \\mdash V. Balakrishnan, IIT Madras

\\href{http://math.arizona.edu/~kglasner/math456/fouriertransform.pdf}{Fourier transform techniques} \\mdash U. Arizona notes

\\href{https://www.math.utah.edu/~gustafso/s2013/3150/pdeNotes/fourierTransorm-PeterOlver2013.pdf}{Fourier transform} \\mdash Olver notes

\\href{http://www.physics.rutgers.edu/~steves/501/Lectures_Final/Lec06_Propagator.pdf}{Free particle propagator}


"""


anharmonic =
    """
\\setcounter{section}{6}

\\begin{mathmacro}
\\newcommand{\\bt}[1]{\\bf{#1}}
\\newcommand{\\mca}[0]{\\mathcal{A}}
\\end{mathmacro}

$$
a^2 = \\bt{Z}/\\mca
$$


\\section{Anharmonic Oscillator}

\\innertableofcontents

The classical anharmonic oscillator is one
with a "non-linear spring". By this we mean
that the standard force law $F = -kx$ has
additional terms, e.g., $F = -kx - \\ell x^3$
. In this case the corresponding potential is
a quartic:

\\begin{equation}
V(x) = (1/2)kx^2 + (\\ell/4)x^4
\\end{equation}

In this section we study the quantum anharmonic
oscillator with a quartic term in the
potential. Our first task is to find the
energy of the ground state when a small quartic
term is added to the potential. For this
we need some basic perturbation theory. An
approximation to the ground state energy in
two ways: (i) by doing a Gaussian integral
(ii) by working out the expression $(a +
a^\\dagger)^4$ as a noncommutative polynomial
using the harmonic oscillator operator calculus.

\\subsection{Perturbation theory}

Let us suppose given a quantum mechanical
system with Hamiltonian of the form $H =
H_0 + \\epsilon V$ , where a complete set of
non-degenerate eigenstates for $H_0$ is known.
Let us call these states $\\psi^{(m)}$ . By
nondegenerate, we mean that all eigenspaces
have dimension one. The second term is a small
multiple of an operator which we generally take
to be a potential. We use this setup to find
solutions of the time-ndependent Schroedinger
equation $H\\psi = E\\psi$ up to terms of order
epsilon, where we imagine that true solutions
have an expansion $\\psi = \\psi_0 + \\epsilon
\\psi_1 + \\epsilon^2 \\psi_2 + \\cdots$ .
Substituting into the Schroedinger equation
and ignoring terms in $\\epsilon^2$ or higher
powers, we have

\\begin{equation}
H_0\\psi_0 + \\epsilon H_0 \\psi_1 + \\epsilon V\\psi_0
 =
E_0\\psi_0 + \\epsilon E_0 \\psi_1 + \\epsilon E_1 \\psi_0
\\end{equation}

The $\\epsilon^0$ component of this equation is

\\begin{equation}
H_0\\psi_0 =
E_0\\psi_0
\\end{equation}

Therefore $\\psi_0$ , the zeroth term in the
perturbation expansion, is an eigenfunction of
the unperturbed Hamiltonian. That is, $\\psi_0
= \\psi^{(m)}$ up to a constant.

The $\\epsilon^1$ component of the equation reads

\\begin{equation}
\\label{foperturbationequation}
 H_0 \\psi_1 + V\\psi_0
 =
 E_0 \\psi_1 +  E_1 \\psi_0
\\end{equation}

Take the inner product with $\\psi_0$ :

\\begin{equation}
\\left< \\psi_0 | H_0  | \\psi_1\\right> +  \\left< \\psi_0  | V | \\psi_0 \\right>
 =
 E_0 \\left< \\psi_0  |  \\psi_1 \\right> +  E_1 \\left< \\psi_0  |  \\psi_0 \\right>
\\end{equation}

Because $\\psi_0$ is an eigenfunction of $H_0$
, the first term on the left is equal to the
first term on the right, so that

\\begin{equation}
\\label{perturbation_of_energy}
E_1 =\\frac{\\left<\\psi_0 | V | \\psi_0 \\right>}{ ||\\psi_0||^2 }
\\end{equation}

In other words, if $E^{(m)}$ is the energy of
the unperturbed Hamiltonian, then the energy
of the corresponding state of the perturbed
system is $E^{(m)} + \\epsilon \\Delta E^{(m)}$
, where

\\begin{equation}
\\label{perturbation_of_En}
\\Delta E^{(m)} =\\frac{\\left<\\psi^{(m)} | V | \\psi^{(m)} \\right>}{ || \\psi^{(m)} ||^2 }
\\end{equation}

To find the wave functions for the perturbed
system, assume that $\\psi_0 = \\psi^{(n)}$
and take the inner product of
\\eqref{foperturbationequation} with
$\\psi^{(m)}$ for $m \\ne n$ . One obtains

\\begin{equation}
\\left< \\psi^{(m)} | H_0 | \\psi_1 \\right> + \\left< \\psi^{(m)} | V | \\psi_0 \\right>
  =
E_0\\left< \\psi^{(m)} | \\psi_1 \\right> + E_1\\left< \\psi^{(m)} | \\psi_0 \\right>
\\end{equation}

The first term on the left is $E_m\\left<
\\psi^{(m)} | \\psi_1 \\right>$ and the last term
on the right vanishes, so that we obtain

\\begin{equation}
\\label{perturbation_fourier_coefficients}
  \\left< \\psi^{(m)} | \\psi_1 \\right>
  = \\frac{\\left< \\psi^{(m)} | V | \\psi_1 \\right>}{E_0 - E_m}
\\end{equation}

The numbers are the Fourier coefficients of
the expansion of $\\psi$ :

\\begin{equation}
\\label{perturbation_fourier_expansion}
  \\psi = \\psi^{(n)}
+ \\epsilon \\sum_{m \\ne n} \\frac{\\left< \\psi^{(n)} | V | \\psi^{(m)} \\right>}{  E^{(n)} - E^{(m)}  }\\psi^{(m)}
\\end{equation}

\\subsection{Quartic perturbation by Gaussian
integrals}

Let us consider a quartic perturbation of the
harmonic oscillator, where

\\begin{equation}
H_0 = \\frac{1}{2m}(\\hat p^2 + m^2 \\omega^2 x^2) +  \\lambda g x^4,
\\end{equation}

where $\\lambda$ is a small dimensionless
parameter. Now $p^2/2m$ is a kinetic energy
term, so $[gx^4] = [E]$ , where $E$ is an
energy and $[\\ ]$ means "units of". Solving,
we have $[g] = [Ex^{-4}]$ . Let us try to cook
up a "natural value" for $g$ . A natural energy
is the zero point energy of the oscillator,
$\\omega\\hbar/2$ . In addition, we need a
natural length scale for $x$ . To this end,
consider the ground state wave function, which
is proportional to $e^{-m\\omega x^2/2\\hbar}$
. Solve for $m\\omega x^2/2\\hbar = 1$ . One
obtains $x_0^2 = 2\\hbar/m\\omega$ . At disance
$x = x_0$ , the value of the wave function
has decreased from its maximum at $x = 0$ by
a factor of $1/e$ . Thus a natural choice is

\\begin{equation}
g = \\frac{\\omega\\hbar}{2}\\left(\\frac{2\\hbar}{m\\omega}\\right)^{-2} = \\frac{m^2 \\omega^3}{8\\hbar}
\\end{equation}

Writing $H= H_0 + \\lambda g x^4$ , we find
ourselves in the context of perturbation
theory. Then the shift in the $n$ -th energy
level is given by

\\begin{equation}
\\label{DeltaEn]}
\\Delta E_n = \\lambda g \\left< \\psi_n | x^4 | \\psi_n \\right> ,
\\end{equation}

and where the $\\psi_n$ are normalized wave
functions for the harmonic oscillator.
Referring to the definition of the normalized
ground state wave function, we find that the
shift in energy levels is given by a Gaussian
integral:

\\begin{equation}
\\Delta E_0 = \\lambda g \\left(\\frac{m\\omega}{\\pi\\hbar}\\right)^{ 1/2 } \\int_{-\\infty}^\\infty x^4 e^{-m\\omega x^2 / \\hbar} dx
\\end{equation}

The integral to be evaluated has the form

\\begin{equation}
I_2 = \\int_{-\\infty}^\\infty x^2 e^{-\\alpha x^2} dx
\\end{equation}

To compute it, recall that

\\begin{equation}
\\int_{-\\infty}^\\infty e^{-\\alpha x^2} dx
= \\left( \\frac{\\pi}{\\alpha} \\right)^{1/2}
\\end{equation}

Now compare this derivative computation

\\begin{equation}
\\frac{d}{d\\alpha} \\int_{-\\infty}^\\infty e^{-\\alpha x^2} dx = - \\int_{-\\infty}^\\infty x^2 e^{-\\alpha x^2} dx
\\end{equation}

with this one:

\\begin{equation}
\\frac{d}{d\\alpha} \\left(\\frac{\\pi}{\\alpha}\\right)^{1/2} = -\\frac{1}{2}\\left(\\frac{\\pi}{ \\alpha^3 } \\right)^{1/2}
\\end{equation}

to conclude that

\\begin{equation}
\\int_{-\\infty}^\\infty x^2 e^{-\\alpha x^2} dx =  \\frac{1}{2}\\left(\\frac{\\pi}{ \\alpha^3 } \\right)^{1/2}
\\end{equation}

Similarly, one obtains

\\begin{equation}
\\int_{-\\infty}^\\infty x^4 e^{-\\alpha x^2} dx =  \\frac{3}{4}\\left(\\frac{\\pi}{ \\alpha^5 } \\right)^{1/2}
\\end{equation}

Working through the constants, one obtains at
long last the first order energy shift:

\\begin{equation}
\\label{anharmonic_correction}
\\Delta E_0 = \\frac{3}{16}\\,\\left( \\frac{\\omega \\hbar}{2}\\right)  \\lambda
\\end{equation}

\\subsection{Quartic perturbation by operator
calculus}

The operator "multiplication by $x$ " can
also be written in terms of creation and
annihilation operators. Adding the expressions
for these operators in the xref::225[last
section], we find that

\\begin{equation}
x = \\left(\\frac{ \\hbar }{  2m \\omega} \\right)^{1/2} (a + a^\\dagger )
\\end{equation}

Substituting this into (<<DeltaEn>>), we find
that

\\begin{align}
\\label{aa4}
\\Delta E_0 &= \\lambda g \\left(\\frac{ \\hbar }{  2m \\omega} \\right)^{2} \\left< \\psi_0 | ( a + a^\\dagger )^4 | \\psi_0 \\right> \\\\
&= \\lambda \\frac{1}{16}\\,\\frac{\\omega \\hbar}{2}\\,\\left< \\psi_0 | ( a + a^\\dagger )^4 | \\psi_0 \\right>
\\end{align}

The operator $(a + a^\\dagger)^4$ is a sum of
sixteen noncommutative monomials which can be
listed in lexicographical order as

\\begin{align}
& a^\\dagger a^\\dagger a^\\dagger a^\\dagger \\\\
& a^\\dagger a^\\dagger a^\\dagger a \\\\
& a^\\dagger a^\\dagger a  a^\\dagger \\\\
& a^\\dagger  a  a^\\dagger a^\\dagger \\\\
& etc
\\end{align}

We say that a monomial is in \\term{normal
order} if all of the creation operators appear
before the annihilation operators. In the list
above, the first, second, and fourth entries
are in normal order. Using the identity
$[a,a^\\dagger] = 1$ , any monomial can be
expressed as a sum of monomials in normal
order. One has, for instance, $aa^\\dagger =
a^\\dagger a + 1$ . Now consider the monomials
$M$ that might enter into the formula (<<aa4>>)
with nonzero coefficient. A bit of reflection
tells us that such a monomial must consist of
two creation operators and two annihilation
operators. This is because the expression
$M\\psi_0$ must be be a multiple of $\\psi_0$ .
That is, $M$ must raise the eigenvalue twice
and also lower it twice. There are six such
monomials. The monomial $M$ must also have a
creation operator on the right, since otherwise
$M\\psi_0 = 0$ . For essentially the same
reasons, it must have an annihilation operator
on the left. This constraint reduces the number
of admissible monomials to two: $aa^\\dagger
aa^\\dagger$ and $aaa^\\dagger a^\\dagger$ . Let
us give the beginning of the computation for
the first of these so that you see the pattern.
Then we will state the result. The computation
is a kind of game in which we move $a$ 's to
the right using the relation $ a a^\\dagger
= a^\\dagger a + 1$ . To win the game is to
express the monomial as a sum of monomials in
normal order. The first move is $aaa^\\dagger
a^\\dagger = aa^\\dagger a a^\\dagger +
aa^\\dagger$ . After a sequence of such moves,
you will find that

\\begin{equation}
aaa^\\dagger a^\\dagger = a^\\dagger a^\\dagger  aa + 4a^\\dagger a + 2
\\end{equation}

For the second monomial, you will find that

\\begin{equation}
aa^\\dagger a a^\\dagger =  a^\\dagger a^\\dagger  aa + 2a^\\dagger a + 1
\\end{equation}

We are led to the conclusion that

\\begin{equation}
(a + a^\\dagger )^4 = M' + 3,
\\end{equation}

where $M'$ is a sum of monomials different from
1. Now think about expressions $\\left< \\psi_0 |
M | \\psi_0 \\right>$ , where $M$ is a monomial in
normal order. It is zero if $M \\ne 1$ and is
1 if $M = 1$ . We can therefore read off the
value of the perturbation term for the energy:

\\begin{equation}
\\Delta E_0 = \\frac{3}{16}\\,\\left( \\frac{\\omega \\hbar}{2}\\right)  \\lambda
\\end{equation}

This is in agreement with the value computed
by doing a Gaussian integral.

\\begin{remark}
Let   $P(a,a^\\dagger)$  be  a  polynomial  in  the  creation  and  annihilation  operators.   Let   $m_M(P)$  be  the  multiplicity  with  which   $M$  appears  in  the  normal  order  expression  for   $P$ .  Then   $\\left< \\psi_0 | P(a,a^\\dagger) | \\psi_0 \\right> = m_1(P)$
\\end{remark}

Note the combinatorial flavor of the
computation of the energy shift by this method.
We will encounter it again in the theory of
Feynman diagrams.

\\subsection{References}

\\href{http://www2.ph.ed.ac.uk/~ldeldebb/docs/QM/lect17.pdf}{Perturbation Theory, Edinburgh}

\\href{http://www.cavendishscience.org/phys/tyoung/tyoung.htm}{Two-slit experiment}
"""
