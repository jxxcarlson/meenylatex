module StringsV2 exposing (initialText, macros, mathExampleText)


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




\\maketitle

% EXAMPLE 1

\\begin{comment}
This multi-line comment
should also not
be visible in the
rendered text.
\\end{comment}


\\tableofcontents

\\strong{Note.} This version of the MiniLaTeX demo uses MathJax 3,
which is much faster than the 2.7.* versions and which gives
a much better experience when doing live editing.  There is one
temporary downside \\mdash some more work needs to be done
to enable math-mode macros.  Coming soon!

\\section{Introduction}

MiniLatex is a subset of LaTeX that can be
rendered live in the browser using a custom parser.
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
your own text. For more information about
the MiniLaTeX project, please go to
\\href{https://minilatex.io}{minilatex.io},
or write to jxxcarlson at gmail.



\\italic{Try editing formula \\eqref{integral:xn} or \\eqref{integral:exp} below.}

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

\\section{Math-mode macros}

\\begin{mathmacro}
\\newcommand{\\bt}[1]{\\bf{#1}}
\\newcommand{\\mca}[0]{\\mathcal{A}}
\\end{mathmacro}


You can add math mode macros to your document
as in the example below.

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

\\newcommand{\\hello}[1]{Hello \\strong{#1}!}

As illustrated by the examples below, one can define new text-mode macros
in MiniLaTeX.
For example, if we add the text

\\newcommand{\\boss}{Phineas Fogg}

\\begin{verbatim}
\\newcommand{\\boss}{Phineas Fogg}
\\end{verbatim}

then saying

\\begin{verbatim}
\\italic{My boss is \\boss.}
\\end{verbatim}

produces \\italic{My boss is \\boss.}
Likewise, if one says

\\begin{verbatim}
\\newcommand{\\hello}[1]{Hello \\strong{#1}!}
\\end{verbatim}

then the macro \\backslash{hello}\\texarg{John} renders as \\hello{John}
For one more example,  make the definition

\\begin{verbatim}
\\newcommand{\\reverseconcat}[3]{#3#2#1}
\\end{verbatim}

\\newcommand{\\reverseconcat}[3]{#3#2#1}

Then \\backslash{reverseconcat}\\texarg{A}\\texarg{B}\\texarg{C} = \\reverseconcat{A}{B}{C}

The macro expansion feature will need a lot more work and testing.
We also plan to add a feature so that authors can define new environments.



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

\\section{Lists and Tables}

A list

\\begin{itemize}

\\item This is \\strong{just} a test.

\\item \\italic{And so is this:} $a^2 + b^2 = c^2$

\\begin{itemize}

\\item Items can be nested

\\item And you can do this: $ \\frac{1}{1 + \\frac{2}{3}} $

\\end{itemize}

\\end{itemize}

A table

\\begin{indent}
\\strong{Light Elements}
\\begin{tabular}{ l l l l }
Hydrogen & H & 1 & 1.008 \\\\
Helium & He & 2 & 4.003 \\\\
Lithium& Li & 3 & 6.94 \\\\
Beryllium& Be& 4& 9.012 \\\\
\\end{tabular}
\\end{indent}

\\section{Errors and related matters}

Errors, as illustrated below, are rendered in real time and are reported in red, in place. For example, suppose the user types the  text

\\begin{verbatim}
  $$
  a^2 + b^2 = c^2
\\end{verbatim}

Then she will see this:

\\image{http://jxxcarlson.s3.amazonaws.com/miniLaTeXErrorMsg-2020-02-22.png}{Fig 2. Error message}{width: 200}


We plan to make further improvements in error reporting.
Note, by the way, what happens when a nonexistent macro like \\italic{hohoho } is used:

\\begin{indent}
\\hohoho{123}
\\end{indent}

This is intentional.  Note also what happens when we use a nonexistent environment like \\italic{joke}:

\\begin{joke}
Did you hear the one about the mathematician, the philosopher, and the engineer?
\\end{joke}

This default treatment of unknown environments is also intentional, and can be useful placeholders: an
exported MiniLaTeX document can, of course, define such environments to suit the author's needs.

\\section{Technology}

MiniLatex is written in \\href{http://elm-lang.org}{Elm}, the statically typed functional
programming language created by Evan Czaplicki for building web applications.  Because of its excellent
\\href{http://package.elm-lang.org/packages/elm-tools/parser/latest}{parser combinator library},
Elm is a good fit for a project like the present one.


For an overview of the design of MiniLatex, see
\\href{https://hackernoon.com/towards-latex-in-the-browser-2ff4d94a0c08}{Towards Latex in the Browser}.
Briefly, \\href{https://www.mathjax.org/}{MathJax} is used inside dollar signs, and Elm is used outside.

\\href{https://github.com/jxxcarlson/meenylatex}{Github repo}

\\bigskip


\\section{References}

\\begin{thebibliography}

\\bibitem{D} \\href{https://ocw.mit.edu/courses/physics/8-05-quantum-physics-ii-fall-2013/lecture-notes/MIT8_05F13_Chap_04.pdf}{On Dirac's bra-ket notation}, MIT Courseware.

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
