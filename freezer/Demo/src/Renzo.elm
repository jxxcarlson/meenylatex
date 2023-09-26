module Renzo exposing (..)


text = """

\\begin{mathmacro}
\\newcommand{\\wt}[1]{\\widetilde{#1}}
\\newcommand{\\GL}{\\text{GL}}
\\end{mathmacro}

$$
\\text{GL} _2  \\neq \\text{GL} _4
$$


$$
\\frac{\\GL_2}{\\GL_3}
$$

Long ago, we learned that

$$
\\int_0^1 x^n dx = \\frac{1}{n+1}
$$


Renzo: $\\wt{\\Delta} \\xrightarrow{\\pi} \\Delta$


Today we will learn about commutative diagrams:


\\begin{CD}
A @>>> B @>{\\alpha}>> C \\\\
@VVV @VVV @VVV \\\\
D @>>> E @>{\\beta}>> F
\\end{CD}

"""


text0 = """


\\begin{CD}
\\require{amscd}
A @>>> B @>{\\text{very long label}}>> C \\
@VVV @VVV @VVV \\
D @>>> E @>{\\phantom{\\text{very long label}}}>> F
\\end{CD}


"""
--%\\begin{equation}
--%\\int_0^1 x^n dx = \\frac{1}{n+1}
--%\\end{equation}


text2 = """
\\begin{mathmacro}
\\newcommand{\\A}{\\mathbb{A}}
\\newcommand{\\B}{\\text{B}}
\\newcommand{\\C}{\\mathbb{C}}
\\newcommand{\\Dcal}{\\mathcal{D}}
\\newcommand{\\Ecal}{\\mathcal{E}}
\\newcommand{\\Fcal}{\\mathcal{F}}
\\newcommand{\\G}{\\mathbb{G}}
\\newcommand{\\g}{\\mathfrak{g}}
\\newcommand{\\Hcal}{\\mathcal{H}}
\\newcommand{\\Ical}{\\mathcal{I}}
\\newcommand{\\K}{\\mathbb{K}}
\\newcommand{\\Kcal}{\\mathcal{K}}
\\newcommand{\\Lcal}{\\mathcal{L}}
\\newcommand{\\Mcal}{\\mathcal{M}}
\\newcommand{\\N}{\\mathbb{N}}
\\newcommand{\\Ncal}{\\mathcal{N}}
\\newcommand{\\Ocal}{\\mathcal{O}}
\\newcommand{\\Pro}{\\mathbb{P}}
\\newcommand{\\Pcal}{\\mathcal{P}}
\\newcommand{\\Q}{\\mathbb{Q}}
\\newcommand{\\Qcal}{\\mathcal{Q}}
\\newcommand{\\R}{\\mathbb{R}}
\\newcommand{\\Scal}{\\mathcal{S}}
\\newcommand{\\Tcal}{\\mathcal{T}}
\\newcommand{\\Ucal}{\\mathcal{U}}
\\newcommand{\\Xcal}{\\mathcal{X}}
\\newcommand{\\Ycal}{\\mathcal{Y}}
\\newcommand{\\Z}{\\mathbb{Z}}
\\newcommand{\\Zcal}{\\mathcal{Z}}
\\newcommand{\\cart}{\\ar @{} [dr] |{\\Box}}
\\newcommand{\\Hom}{\\text{Hom}}
\\newcommand{\\Isom}{\\text{Isom}}
\\newcommand{\\Pic}{\\text{Pic}}
\\newcommand{\\GL}{\\text{GL}}
\\newcommand{\\PGL}{\\text{PGL}}
\\newcommand{\\SL}{\\text{SL}}
\\newcommand{\\Sym}{\\text{Sym}}
\\newcommand{\\Spec}{\\text{Spec}}
\\newcommand{\\un}{\\underline}
\\newcommand{\\pr}{\\text{pr}}
\\newcommand{\\ov}{\\overline}
\\newcommand{\\im}{\\text{Im}}
\\newcommand{\\wh}[1]{\\widehat{#1}}
\\newcommand{\\wt}[1]{\\widetilde{#1}}
\\newcommand{\\ev}{\\text{ev}} 
\\newcommand{\\Char}{\\text{char}} 
\\newcommand{\\Bl}{\\text{Bl}} 
\\newcommand{\\M}{\\text{M}}
\\newcommand{\\Sch}{\\text{Sch}}
\\newcommand{\\di}[1]{\\displaystyle}
\\end{mathmacro}


\\begin{textmacro}
\\newcommand{\\renzo}[1]{{\\color{blue} \\footnote{\\color{blue} Renzo: #1}}}
\\newcommand{\\rcolor}[1]{{\\color{blue}  #1}}
\\newcommand{\\damiano}[1]{{\\color{red} \\footnote{\\color{red} Damiano: #1}}}
\\newcommand{\\dcolor}[1]{{\\color{red}  #1}}
\\end{textmacro}

\\begin{comment}
%% \\newenvironment{dem}{\\begin{proof}[\\bf Proof]}{\\end{proof}}
\\newtheorem{theorem}{\\bf Theorem}[section]
\\newtheorem*{maintheorem}{\\bf Main Theorem}
\\newtheorem{lemma}[theorem]{\\bf Lemma}
\\newtheorem{propos}[theorem]{\\bf Proposition}
\\newtheorem{corol}[theorem]{\\bf Corollary}
\\newtheorem{claim}[theorem]{\\bf Claim}
\\newtheorem{conj}[theorem]{\\bf Conjecture}

\\theoremstyle{definition}
\\newtheorem{defi}[theorem]{\\bf Definition}
\\newtheorem{rmk}[theorem]{\\bf Remark}
\\newtheorem{exm}[theorem]{\\bf Example}
\\end{comment}

%\\input xy
%\\xyoption{all}

%\\oddsidemargin 0pt
%\\evensidemargin 0pt
%\\topmargin 0pt
%\\textwidth 470pt
%\\textheight 630pt
%\\textwidth 500pt
%\\textheight 630pt

\\title{The integral Chow ring of $\\Mcal_{0,0}(\\Pro^r, 2s+1)$}
\\author{Renzo Cavalieri, Damiano Fulghesu}
\\date{\\today}

 %\\thanks{The second author was partially supported by Simons  Foundation grant \\#360311.}
%\\address[Damiano Fulghesu]{Department of Mathematics, Minnesota State University, 1104 7th Ave South, Moorhead, MN 56563, U.S.A.}\\email{fulghesu@mnstate.edu}


%\\subjclass[2010]{14C15 (primary), 4L30, 14D23 (secondary)}

% \\begin{document}

\\begin{abstract}
We provide an algorithm for computing the integral Chow ring of the stack 
$\\Mcal_{0,0}(\\Pro^r, 2s+1)$, that is to say, the moduli stack of odd-degree stable maps of the projective line to projective space. We also determine explicitly the case $r=2$ and $s=1$, i.e. degree 3 regular maps to the projective plane.
\\end{abstract}

\\maketitle

%%%%%%%%%%
\\section{Kontsevich-Renzo}
%%%%%%%%%%

TO DO

\\begin{itemize}
\\item Explain why we restrict to odd degree
\\end{itemize}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\\section{A Presentation of the Stack $\\Mcal_{0,0}(\\Pro^r, 2s+1)$}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Let $k$ be an algebraically closed field of characteristic 0 or larger than $2s+1$\\note{damiano}{THIS IS THE SAFEST POSSIBLE ASSUMPTION ON THE CHARACTERISTIC IN CASE WE HAVE TO TAKE DERIVATIVES.}.

We refer the reader to \\cite{FP} for a general definition of the stack of stable maps $\\Mcal_{g,n}(X,\\beta)$ where $X$ is a projective variety and $\\beta$ is a class in $A_1(X,\\Z)$. In this paper we focus on the special case $\\Mcal_{0,0}(\\Pro^r,d)$. In particular, we adopt the following definition.

\\begin{defi}
Let $\\Mcal_{0,0}(\\Pro^r,d)$ be the category whose objects are diagrams

\\[
\\xymatrix{
C \\ar[d]_{\\pi}  \\ar[r]^{f} & \\Pro^r\\\\
S
}
\\]

such that:

\\begin{itemize}
\\item $S$ is a $k$-scheme,
\\item the morphism $\\pi: C \\to S$ is a projective flat family of curves isomorphic to $\\Pro^1$,
\\item the degree of $f^*\\Ocal_{\\Pro^r}(1)$ on the geometric fibers of $\\pi: C \\to S$ is $d$.
\\end{itemize}

As a consequence of the third bullet point,  the restriction of $f$ on the geometric fibers of $\\pi: C \\to S$ is in particular not constant. Arrows are cartesian diagrams:
\\[
\\xymatrix{
C_1 \\cart \\ar[r]^{\\psi} \\ar[d]_{\\pi_1} \\ar@/^2.0pc/[rr]^{f_1=f_2 \\circ \\psi}& C_2 \\ar[d]^{\\pi_2}  \\ar[r]^{f_2} & \\Pro^r\\\\
S_1 \\ar[r]^{\\varphi}& S_2
}
\\]
\\end{defi}

The category $\\Mcal_{0,0}(\\Pro^r,d)$ is naturally a category fibered in groupoids over the category $(\\Sch/k)$ of $k$-schemes. Moreover, $\\Mcal_{0,0}(\\Pro^r,d)$, is a proper Deligne-Mumford stack, see, for example, \\cite[Theorem 3.14]{BM}.

As an example of a moduli point with non-trivial isotropy, let $f_d: \\Pro^1 \\to \\Pro^1$ be defined as $f_d(x:y)  = (x^d:y^d)$, and let $\\iota_L:\\Pro^1\\to \\Pro^r$ be the inclusion of $\\Pro^1$ as a line in $\\Pro^r$; then $(\\Pro^1, \\iota_L\\circ f_d)\\in \\Mcal_{0,0}(\\Pro^r,d)$  has isotropy group $\\mu_d$.

The stack $\\Mcal_{0,0}(\\Pro^r,d)$ has a coarse moduli space $\\M_{0,0}(\\Pro^r,d)$, see \\cite[Theorem 1]{FP} for a more general result.

Our next goal is to give $\\Mcal_{0,0}(\\Pro^r,d)$ a structure of quotient by a linear algebraic group. Let $E$ be the standard representation of $\\GL_2$. We identify the projective line as
\\[
\\Pro^1 \\cong \\Pro(E).
\\]
We consider the vector space of homogeneous forms of degree $d$ over $\\Pro^1$
\\[
W_d:= H^0(\\Pro^1,\\Ocal_{\\Pro^1}(d)) = \\Sym^d(E^\\vee)
\\]
where $E^\\vee$ is the dual of the representation $E$.

The set of regular maps 
$
\\Pro^1 \\to \\Pro^r
$
of degree $d$ is an open subset $U_{r,d}$ of $\\Pro \\left( W_d^{\\oplus r+1} \\right)$.  More precisely, a general element $f$ of $U_{r,d}$ can be written as
\\[
f= \\left [ f_1(x,y), \\dots, f_{r+1} (x,y)  \\right]
\\]
where

\\begin{itemize}

\\item for all $i=1, \\dots, r+1$, the polynomial in two variables $f_i(x,y)$ is homogeneous of degree $d$;

\\item the map $f$ is free of base points, in other words, the polynomials $f_i(x,y)$ have no common factors.\\end{itemize}

We call $\\Delta_{r,d}$ the complement of $U_{r,d}$ in $\\Pro \\left( W_d^{\\oplus r+1} \\right)$, and $\\widehat{U}_{r,d}$ the affine cone over $U_{r,d}$, that is the preimage of $U_{r,d}$ via the tautological map
\\[ 
W_d^{\\oplus r+1} \\backslash 0 \\to \\Pro \\left( W_d^{\\oplus r+1} \\right).
\\]

\\end{itemize}

We have the following isomorphism of stacks (see \\cite[Section 2]{FP} for a more general result):

\\begin{equation}
\\label{basic.isom}
\\Mcal_{0,0}(\\Pro^r, d) \\cong \\left[ U_{r,d} / \\PGL_2 \\right]
\\end{equation}\\label{eq:actpgl2}

where the action of $\\PGL_2$ over $U_{r,d}$ is given by:

\\begin{equation}
(A \\cdot [f_1, f_2, \\dots, f_{r+1}])(x,y) = [f_1 (A^{-1}(x,y)), f_2(A^{-1}(x,y)), \\dots, f_{r+1}(A^{-1}(x,y))].
\\end{equation}

The use of the inverse matrix is necessary to have a well defined left action.

From now on, we restrict ourselves to the case of odd degree, that is $d=2s+1$ for some nonnegative integer $s$.

\\begin{lemma}\\label{lemma.normal.subgroup}
Let $H$ be a normal subgroup of a linear group $G$ and let $X$ be a quasi-projective scheme equipped with a $G$-action. Assume that $H$ acts freely on $X$ so that the quotient $X/H$ is a quasi-projective scheme as well. Then we have an isomorphism of quotient stacks:
\\[
\\left[ X / G \\right] \\cong \\left[ (X/H) / (G/H) \\right]
\\]
\\end{lemma}

\\begin{dem}
See, for example, \\cite[Example 3.3]{Hei05}.
\\end{dem}

\\begin{rmk} A consequence of Lemma \\ref{lemma.normal.subgroup} is the induced isomorphism of equivariant intersection rings:
\\[
A^*_G(X) \\cong A^*_{G/H}(X/H).
\\]
For a direct proof of this isomorphism see \\cite[Lemma 2.1]{MV}.
\\end{rmk}

\\begin{propos}\\label{prop.reduction.GL2}
Let $d=2s+1$ be a positive odd integer. The stack $\\Mcal_{0,0}(\\Pro^r, d)$ is isomorphic to the quotient stack
\\[
\\Mcal_{0,0}(\\Pro^r, d) \\cong \\left[ \\widehat{U}_{r,d} / \\GL_2 \\right]
\\]
where the action of $\\GL_2$ is
\\[
A \\cdot (f_0, f_1, \\dots, f_{r}) (x,y) = \\det{A}^{s+1} (f_0 (A^{-1}(x,y)), f_1(A^{-1}(x,y)), \\dots, f_{r}(A^{-1}(x,y))).
\\]
\\end{propos}

\\begin{dem}
We apply Lemma \\ref{lemma.normal.subgroup} with the substitutions:
\\[
X= \\widehat{U}_{r,d}; \\quad G=\\GL_2; \\quad H=\\G_m.
\\]
We know that $\\G_m$ is normal in $\\GL_2$, so we need to describe the induced action of $\\G_m$ on $\\widehat{U}_{r,d} \\subset W_d^{\\oplus r+1}$.

We refer to the exact sequence of groups:
\\[
1 \\to \\G_m \\xrightarrow{\\varphi} \\GL_2 \\xrightarrow{\\pi} \\PGL_2 \\to 1
\\]

Let $\\lambda \\in \\G_m$ and $\\varphi(\\lambda)= \\left [ \\begin{array}{cc} \\lambda & 0\\\\ 0 & \\lambda \\end{array} \\right ]=:A$, we have

\\begin{align}
A \\cdot (f_1, f_2, \\dots, f_{r+1}) (x,y) &=& \\det{A}^{s+1} (f_1 (A^{-1}(x,y)), f_2(A^{-1}(x,y)), \\dots, f_{r+1}(A^{-1}(x,y))) =\\\\
& = & \\lambda^{2(s+1)} \\frac{1}{\\lambda^{d}}(f_1, f_2, \\dots, f_{r+1}) (x,y) = \\lambda (f_1, f_2, \\dots, f_{r+1}) (x,y),
\\end{align}

therefore $\\widehat{U}_{r,d}/\\G_m = U_{r,d}$. Notice that the action of $\\G_m$ is free on $\\widehat{U}_{r,d}$. Applying Lemma \\ref{lemma.normal.subgroup} we get the following isomorphism:
\\[
\\left[ \\widehat{U}_{r,d} / \\GL_2 \\right] \\cong \\left[ U_{r,d} / \\PGL_2 \\right]
\\]
where the action of $\\PGL_2$ over $U_{r,d}$ is  as in \\eqref{eq:actpgl2}. We conclude thanks to isomorphism (\\ref{basic.isom}).
\\end{dem}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\\section{Generators and First Relations}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Thanks to Proposition \\ref{prop.reduction.GL2}, we are reduced to compute the equivariant intersection ring $A^*_{\\GL_2}\\left( \\widehat{U}_{r,d} \\right)$.  In this Section we reduce the computation to an application of the Atiyah-Bott localization theorem.

First, we recall some facts about equivariant Chow rings we will use, and set notation. Let $T$ denote the maximal torus for $\\GL_2$ represented by diagonal matrices, and consider the induced morphism $Bi: BT \\to B\\GL_2$.  We denote by $E$  the standard representation of $\\GL_2$, which we think of as (the pull-back to the point via the quotient map $pt \\to B\\GL_2$ of) a rank two vector bundle over $B\\GL_2$. Since  the Chern classes of $E$ will be frequently used, we denote $c_i(E)$ simply by $c_i$. The pull-back $Bi^\\ast(E^\\vee)$ splits as the direct sum of two line bundles on $BT$: the characters  $\\lambda_1, \\lambda_2$ given by the two coordinate projections of $T$.

Denoting $A^{*}_T = A^{ *}_T(pt.)$, it is known (see e.g.  \\cite[Chapter 4]{Mirror-symmetry-book}) that $A^{*}_T=\\Z\\left[  l_1, l_2  \\right]$, with $l_i =  c_1\\left( \\lambda_i \\right)$. By a slight abuse of notation we also denote by $l_i $  the Chern roots of the vector bundle $E^\\vee$, since we have

\\begin{align}
Bi^\\ast c_1&=&-(l_1+l_2)\\\\
Bi^\\ast  c_2 &=& l_1 l_2.
\\end{align}

 The Weyl group $S_2$  acts on $A^*_T$ by permuting the classes $l_i$ and we have $A^*_{\\GL_2}=\\left( A^*_T \\right)^{S_2}$ (see \\cite[Proposition 6]{EG}).

Consider the following commutative $\\GL_2$-equivariant diagram
\\[
\\xymatrix{
\\widehat{U}_{r,d} \\ar[r]^{j} \\ar[d]^{\\pi} & W_d^{\\oplus r+1} \\ar[d]^{\\pi} \\backslash 0\\\\
U_{r,d} \\ar[r]^{j} & \\Pro \\left( W_d^{\\oplus r+1} \\right)
}
\\]
where the horizontal arrows are the natural open inclusions and the vertical arrows are the natural quotient maps by the action of $\\G_m$. We can see the vertical maps also as principal $\\G_m$-bundles associated to the $\\GL_2$-equivariant line bundle $\\Dcal^{\\otimes s+1} \\otimes \\Ocal(-1)$, where $\\Ocal(-1)$ is the tautological bundle over $\\Pro \\left( W_d^{\\oplus r+1} \\right)$ and $\\Dcal$ is the one dimensional representation of $\\GL_2$ associated to the determinant $\\bigwedge^2 E$. The first Chern class of $\\Dcal$ is $c_1(\\Dcal)=c_1$, therefore we have

\\[
c_1 \\left( \\Dcal^{\\otimes s+1} \\otimes \\Ocal(-1) \\right)=(s+1)c_1 - H
\\]

where $H$ is the canonical equivariant lift of the hyperplane class of $\\Pro \\left( W_d^{\\oplus r+1} \\right)$. By arguing as in Lemma 3.2 of \\cite{EFh}, the pull-back morphism
\\[
\\pi^*: A^*_{\\GL_2} \\left( U_{r,d} \\right) \\to A^*_{\\GL_2} \\left( \\widehat{U}_{r,d} \\right)
\\]
is surjective and its kernel is generated by $H-(s+1)c_1$. We may therefore determine  $A^*_{\\GL_2} \\left( \\widehat{U}_{r,d} \\right)$ from a presentation of the ring $A^*_{\\GL_2} \\left( U_{r,d} \\right)$ by applying the substitution $H=(s+1)c_1$.

In order to compute $A^*_{\\GL_2} \\left( U_{r,d} \\right)$, we consider the following exact sequence of $A^*_{\\GL_2}$-modules:
\\[
A^*_{\\GL_2}\\left( \\Delta_{r,d} \\right) \\xrightarrow{i_*} A^*_{\\GL_2}\\left( \\Pro \\left( W_d^{\\oplus r+1} \\right) \\right) \\xrightarrow{j^*} A^*_{\\GL_2}\\left( U_{r,d} \\right) \\to 0.
\\]

Using standard techniques as in \\cite[Section 3.2]{Fu-Vi}, we have the following isomorphism:

\\begin{equation}
A^*_{\\GL_2}\\left( \\Pro \\left( W_d^{\\oplus r+1} \\right) \\right) \\cong \\frac{\\Z[c_1,c_2,H]}{(P_{r,d}(H))}
\\end{equation}

where

\\begin{equation}
P_{r,d}(H)= \\prod_{k=0}^d (H+(d-k)l_1 + kl_2)^{r+1}.
\\end{equation}

In conclusion, we have:

\\begin{equation}\\label{isom}
A^* \\left( \\Mcal_{0,0}(\\Pro^r, 2s+1) \\right) \\cong A^* \\left( [ U_{r,d} / \\PGL_2 ] \\right) \\cong \\frac{A^*_{\\GL_2}\\left( \\Pro \\left( W_d^{\\oplus r+1} \\right) \\right)}{(\\im(i_*), H-(s+1)c_1)} \\cong \\frac{\\Z[c_1,c_2,H]}{(\\im(i_*), H-(s+1)c_1,P_{r,d}((s+1)c_1))}
\\end{equation}

where $\\im(i_*)$ is the image of the push-forward $i_*$.

We start by defining a stratification of the locus of degenerate maps $\\Delta_{r,d}$.

\\begin{defi}
For every $i=1, \\dots, d$,   $Z_i$ is the subspace of $\\Pro \\left( W_d^{\\oplus r+1} \\right)$ representing $(r+1)$-tuples of polynomials with a common factor of degree $i$, but not $i+1$:
\\begin{equation}
 Z_i = \\{(f_1, \\ldots, f_{r+1}) | \\deg(\\gcd(f_1, \\ldots, f_{r+1}) = i \\}.
\\end{equation}
\\end{defi}

The family $\\{ Z_i\\}_{i=1, \\dots, d}$ is an equivariant stratification of $\\Delta_{r,d}$, in the sense of  \\cite[Definition 1.2]{DLFV}.

The goal is now to compute the ideal $\\im(i_*)$ explicitly; for this purpose, we construct an equivariant envelope for the locus of degenerate maps $\\Delta_{r,d}$.

Now, in general, let $X$ be a $G$-scheme and $\\Delta \\xrightarrow{i} X$ an equivariant closed embedding. A consolidated method to determine the image of the group homomorphism
\\[
A_G^*(\\Delta) \\xrightarrow{i_*} A_G^*(X),
\\]
is to use an equivariant envelope of $\\Delta$. Recall that an \\italic{envelope} 
$\\wt{\\Delta} \\xrightarrow{\\pi} \\Delta$, see \\cite[Definition 18.3]{Ful}, is a proper map such that for every subvariety $V$ of $\\Delta$, there is a subvariety $\\wt{V}$ of $\\wt{\\Delta}$ such that the morphism $\\pi$ maps $\\wt{\\Delta}$ birationally onto $V$. In the category of $G$-schemes, we say that $\\pi$ is an \\italic{equivariant envelope}, see \\cite[Section 2.6]{EG}, if $\\pi$ is $G$-equivariant and if we can choose $\\wt{V}$ to be $G$-invariant whenever $V$ is $G$-invariant. Having an equivariant envelope $\\wt{\\Delta} \\xrightarrow{\\pi} \\Delta$ for a closed subscheme $\\Delta \\xrightarrow{i} X$ is especially helpful when we can explicitly describe the Chow group of $\\wt{\\Delta}$ and the image of the group homomorphism
\\[
A_G^*(\\wt{\\Delta}) \\xrightarrow{(i \\circ \\pi)_*} A_G^*(X).
\\]

As a matter of fact, we have from \\cite[Lemma 3]{EG} and \\cite[Lemma 18.3(6)]{Ful} that the group homomorphism

\\[
A_G^*(\\wt{\\Delta}) \\xrightarrow{\\pi_*} A_G^*(\\Delta)
\\]

is surjective. Therefore, thanks to the functoriality of the push-forwards we have the following Theorem.

\\begin{theorem}\\label{thm:ipi}
Let $X$ be a $G$-scheme and $\\Delta \\xrightarrow{i} X$ an equivariant closed embedding. If $\\wt{\\Delta} \\xrightarrow{\\pi} \\Delta$ is an equivariant envelope of $\\Delta$, then we have the identity
\\[
(i \\circ \\pi)_* \\left( A_{G}^* ( \\wt{\\Delta}) \\right) = { i_* }\\left( A_{G}^* \\left( \\Delta \\right) \\right).
\\]
\\end{theorem}

Our next step is to provide a family of projective morphisms $\\{ \\wt{Z}_i \\xrightarrow{\\pi_i} \\Pro \\left( W_{d-i}^{\\oplus r + 1} \\right) \\}_{i=1, \\dots, d}$ whose disjoint union restricted to $\\Delta_{r,d}$ is an equivariant envelope. 

Let us define
\\[
\\wt{Z}_i := \\Pro(W_i) \\times \\Pro \\left( W_{d-i}^{\\oplus r + 1} \\right)
\\]

and the morphisms

\\begin{align}
\\label{eq:defincl}
\\pi_i: \\wt{Z}_i  &\\to & \\Pro \\left( W_d^{\\oplus r+1} \\right) \\nonumber \\\\
([c(x,y)],[g_1(x,y), g_2(x,y), \\dots, g_{r+1}(x,y)]) &\\mapsto & [c(x,y) \\cdot g_1(x,y), c(x,y) \\cdot g_2(x,y), \\dots, c(x,y) \\cdot g_{r+1}(x,y)].
\\end{align}

\\begin{rmk}{\\red Change into Prop/Lemma?}
Notice that each $\\wt{Z}_i$ maps to the closure $\\ov{Z}_i$ of a stratum of $\\Delta_{r,d}$.
\\end{rmk}

We can now define an equivariant envelope for $\\Delta_{r,d}$.

\\begin{propos}\\label{prop.equivariant.envelope}
Denote by $\\wt{Z} := \\bigsqcup_{i=1, \\dots, d} \\wt{Z}_i$ and by $\\pi := \\sqcup \\pi_i$. 
Denoting by $\\wt\\pi$ the restriction of $\\pi$ onto its image $\\Delta_{r,d}$, we have that $$\\wt\\pi: \\wt{Z}\\to \\Delta_{r,d}$$ is an equivariant envelope on $\\Delta_{r,d}$.
\\end{propos}

\\begin{dem}
{\\red [Add reference for the argument]}

First of all, notice that the morphism $\\wt{\\pi}$ is proper and $\\GL_2$-invariant. Moreover, to check the remaining equivariant envelope hypothesis, we can restrict to each $Z_i$. Let $V$ be a $\\GL_2$-invariant subvariety of $Z_i$. Let $\\omega$ be the generic point of $V$. The point $\\omega$ is represented by an $(r+1)$-tuple $[f]:=[f_1, \\dots, f_{r+1}]$ of forms of degree $d$ in $K[x,y]$ for some field extension $k \\subset K$. By definition of $Z_i$, the greatest common divisor of the forms in $[f]$ has degree $i$. Therefore, there is a unique $K$-valued point $\\wt{\\omega}$ in $\\wt{Z}_i$ mapping to $\\omega$. We define $\\wt{V}$ as the schematic closure of $\\wt{\\omega}$ in $\\wt{Z}_i$. Because of the uniqueness of the generic point, $\\wt{V}$ is in fact $\\GL_2$-invariant.
\\end{dem}


\\begin{corol} \\label{corol:ipi}
We have the identity:
\\[
\\pi_* \\left( A_{\\GL_2}^* ( \\wt{Z}) \\right) = { i_* }\\left( A_{\\GL_2}^* \\left( \\Delta_{r,d} \\right) \\right).
\\]
\\end{corol}

\\begin{dem}
This is a straightforward consequence of Proposition \\ref{prop.equivariant.envelope} and Theorem \\ref{thm:ipi}.
\\end{dem}

For the next definition, we adopt the notation in the following diagram:

\\begin{equation}\\label{eq:projs}
\\xymatrix{
& \\wt{Z}_i \\ar[rr]^{\\pi_i} \\ar[dl]_{p_1} \\ar[dr]^{p_2}& & \\Pro(W_{d}^{\\oplus r+1})\\\\
\\Pro(W_i) & & \\Pro(W_{d-i}^{\\oplus r+1})
}
\\end{equation}

\\begin{defi}
For all $i=1, \\dots, d$, { we denote by $h_{i} = p_1^\\ast c_1^{eq} (\\mathcal{O}_{\\Pro(W_i) }(1))$  the (pull-back via the first projection of) canonical equivariant lift} of the hyperplane class on the first  component of $\\wt{Z}_i = \\Pro(W_i) \\times \\Pro \\left( W_{d-i}^{\\oplus r + 1} \\right)$. We  define the classes:
\\[
\\alpha_{i,k}:= \\pi_* \\left( h_i^k\\right) \\in A_{\\GL_2}^* \\left( \\Pro(W_d^{\\oplus r+1} ) \\right).
\\]
\\end{defi}

\\begin{propos}\\label{prop.alpha}
We have the ideal identity:
\\[
i_* \\left( A_{\\GL_2 *} \\left( \\Delta_{r,d} \\right) \\right) = \\left( \\alpha_{i,k}\\right)_{i=1, \\dots, d; \\; k=0, \\dots, i}.
\\]
\\end{propos}

\\begin{dem}
Using Corollary \\ref{corol:ipi}, it suffices to show that  $\\pi_* \\left( A_{\\GL_2}^* ( \\wt{Z}) \\right) $ is contained in the ideal $I$ generated by the classes $\\alpha_{i,k}$. Denote by $H =  c_1^{eq} (\\mathcal{O}_{ \\Pro(W_d^{\\oplus r+1} ) }(1))$ and by $\\eta_i =  p_2^\\ast c_1^{eq} (\\mathcal{O}_{ \\Pro \\left( W_{d-i}^{\\oplus r + 1} \\right)}(1))$. From \\eqref{eq:defincl}, we have 

\\begin{equation} \\label{eq:pullb}
\\pi_i^\\ast(H) = h_i+\\eta_i.
\\end{equation}

We prove that any class of the form $\\pi_{i,\\ast} (h_i^{k} \\eta_i^{m})$ is in $I$ by induction on $m$. For $m=0$, $k>i$,  notice that the class $\\pi_{i,\\ast}(h_i^k)$ is a linear combination of the classes $\\alpha_{i,k}$,   $k\\leq i$, with coefficients in $\\Z[l_1, l_2]$; hence the base case $m = 0$ is established.

Using projection formula and \\eqref{eq:pullb} one obtains the following equalities.

\\[
H \\pi_{i,\\ast}(h_i^k \\eta_i^{m-1})  = \\pi_{i,\\ast}(h_i^k \\eta_i^{m-1} \\pi_i^\\ast H) = \\pi_{i,\\ast}(h_i^k \\eta_i^{m-1} (h_i+\\eta_i))  = \\pi_{i,\\ast}(h_i^{k+1} \\eta_i^{m-1} ) + \\pi_{i,\\ast}(h_i^{k} \\eta_i^{m} ) .
\\]

Solving

\\[
 \\pi_{i,\\ast}(h_i^{k} \\eta_i^{m}) = H \\pi_{i,\\ast}(h_i^k \\eta_i^{m-1})  - \\pi_{i,\\ast}(h_i^{k+1} \\eta_i^{m-1} )
\\]

completes the inductive step.
\\end{dem}

\\begin{rmk}
\\label{alpha.polynomials}
The classes $\\alpha_{i,k}$ are polynomials in the  class $H$ with coefficients in $A^*_{\\GL_2}$. For this reason, we  write such classes as $\\alpha_{i,k}(H)$ when we wish to emphasize the dependence on $H$.
\\end{rmk}

With reference to Proposition \\ref{prop.alpha}, Lemma \\ref{lemma.big.pol}, and Remark \\ref{alpha.polynomials}, we rewrite isomorphism (\\ref{isom}) as

\\begin{equation}
A^* \\left( \\Mcal_{0,0}(\\Pro^r, 2s+1) \\right) \\cong \\frac{\\Z[c_1,c_2]}{(\\alpha_{i,k}((s+1)c_1)_{i=1, \\dots, d, k=0, \\dots, i}}.
\\end{equation}

\\section{The Algorithm}\\label{section.algorithm}

\\begin{theorem}
%%JC%%[{\\cite[Theorem 2]{EGL}}]
\\label{thm.loc}
	Define the $A^*_T$-module $ \\Qcal:= ((A^*_T)^+)^{-1}A^*_T$, 
	where $(A^*_T)^+$ is the multiplicative system of homogeneous elements of $A^*_T$ of positive degree.
	
	Let $X$ be a smooth $T$-variety and consider the locus $F$ of fixed points for the action of $T$. Let $F=\\cup F_j$ be the decomposition of $F$ into irreducible components. For every $\\gamma$ in $A^*_T(X)\\otimes\\Qcal$, we have the identity
	\\[ \\gamma = \\sum_{j} \\frac{i_{F_j}^*(\\gamma)}{c_{top}^T(N_{F_{j}}X)} \\]
	where $i_{F_j}$ is the inclusion of $F_j$ in $X$ and $N_{F_j}X$ is the normal bundle of $F_j$ in $X$.
\\end{theorem}

\\begin{rmk}\\label{rmk.loc}
In particular, when $A^*_T(X)$ is torsion-free as $A^*_T$-module, the localization homomorphism $A^*_T(X)\\to A^*_T(X)\\otimes\\Qcal$ is injective, and for every $T$-equivariant morphism $f:Y\\to X$ of smooth $T$-varieties, we have a commutative diagram

\\[
 \\xymatrix{A^*_T(Y) \\ar[r]^{f_*} \\ar[d] & A^*_T(X) \\ar[d] \\\\ A^*_T(Y)\\otimes\\Qcal \\ar[r] & A^*_T(X)\\otimes\\Qcal } 
\\] 

Moreover, if $F_j$ is a point for every $j$, we have:

%%JC%%:
%\\begin{equation}
%\\label{eq:loc} 
%f_*\\gamma = \\sum_j \\frac{[f(F_j)]\\cdot p_j(\\gamma)}{c_{top}^T(T Y_{F_j})}
 %\\end{equation}

where  $\\gamma \\in A^*_T(Y)$, $p_j(\\gamma)=i_{F_j}^*\\gamma$ in $A^*_T(F_j)=A^*_T$, and $T Y_{F_j}$ is the tangent space of $Y$ at $F_j$. Notice that $c_{top}^T(T Y_{F_j}) \\in A^*_T$.
We will mostly use the localization formula in the form of (\\ref{eq:loc}).
\\end{rmk}

%We will refer to the following diagram:
%\\[
%\\xymatrix{
%& \\wt{Z}_i \\ar[rr]^{\\pi_i} \\ar[dl]_{p_1} \\ar[dr]^{p_2}& & \\Pro(W_{d}^{\\oplus r+1})\\\\
%\\Pro(W_i) & & \\Pro(W_{d-i}^{\\oplus r+1})
%}
%\\]

Refer to diagram \\eqref{eq:projs} for notation. Our goal is to apply formula (\\ref{eq:loc}) to the cases $Y=\\wt{Z}_i$, $X=\\Pro\\left(W_{d}^{\\oplus r+1}\\right)$, and $\\gamma=\\alpha_{i,j}$. However, when we consider the action of $T=\\G_m^{2}$, the fixed loci have positive dimension. Therefore, in order to apply the simplified formula (\\ref{eq:loc}) we formally add an action of $\\G_m^{r+1}$ whose fixed loci are isolated points. More precisely, we define the torus:
\\[
\\wh{T}:= T \\times \\G_m^{r+1}
\\]
and we label the weights of $\\G_m^{r+1}$ as $t_1, \\dots, t_{r+1}$. Therefore, we have the identity $A^*_{\\wh{T}}=\\Z[l_1,l_2, t_1, \\dots, t_{r+1}].$

We consider the following action of $\\wh{T}$ over $\\Pro(W_d^{r+1})$:

\\begin{align}
\\wh{T} \\cdot \\Pro(W_d^{r+1}) & \\to & \\Pro(W_d^{\\oplus r+1})\\\\
(\\lambda_1,\\lambda_2, \\mu_1, \\dots, \\mu_{r+1}) \\cdot \\left[
\\begin{array}{cccc}
a_{1}^{d,0} & a_{1}^{d-1,1} & \\dots & a_{1}^{0,d}\\\\
a_{2}^{d,0} & a_{2}^{d-1,1} & \\dots & a_{2}^{0,d}\\\\
\\vdots & \\vdots & \\ddots & \\vdots \\\\
a_{r+1}^{d,0} & a_{r+1}^{d-1,1} & \\dots & a_{r+1}^{0,d}\\\\
\\end{array}
\\right] & \\mapsto &
 \\left[
\\begin{array}{cccc}
\\frac{\\mu_1} {\\lambda_1^{d}}a_{1}^{d,0} & \\frac{\\mu_1}{\\lambda_1^{d-1}\\lambda_2} a_{1}^{d-1,1} & \\dots & \\frac{\\mu_1}{\\lambda_2^{d}}a_{1}^{0,d}\\\\
\\frac{\\mu_2} {\\lambda_1^{d}}a_{2}^{d,0} & \\frac{\\mu_2}{\\lambda_1^{d-1}\\lambda_2}a_{2}^{d-1,1} & \\dots &  \\frac{\\mu_2}{\\lambda_2^{d}}a_{2}^{0,d}\\\\
\\vdots & \\vdots & \\ddots & \\vdots \\\\
\\frac{\\mu_{r+1}} {\\lambda_1^{d}}a_{r+1}^{d,0} & \\frac{\\mu_{r+1}}{\\lambda_1^{d-1}\\lambda_2}a_{r+1}^{d-1,1} & \\dots &  \\frac{\\mu_{r+1}}{\\lambda_2^{d}}a_{r+1}^{0,d}\\\\
\\end{array}
\\right] 
\\end{align}

On $\\wt{Z}_{i}$ we have the action:
\\[
\\wh{T}\\cdot \\wt{Z}_i = (T \\cdot \\Pro(W_i)) \\times (\\wh{T} \\cdot \\Pro(W^{\\oplus r+1}_{d-i})).
\\]

These actions make the morphism $\\pi: \\wt{Z} \\to  \\Pro(W_d^{\\oplus r+1})$ $\\wh{T}$-equivariant. Let $F^{p,q}_{j}$ be the point in $ \\Pro\\left(W_d^{\\oplus r+1}\\right)$ whose only coordinate different from zero is $a^{p,q}_j$. For example, in $\\Pro\\left(W_6^{\\oplus 8}\\right)$ the point $F^{2,4}_5$ represents the monomial $X^2Y^4$ in the $5^{\\text{th}}$ entry. 

List of classes:

\\begin{align}
& & \\wh{P}_{r,d}(H)=\\prod_{k=0}^{d} \\prod_{j=1}^{r+1} (H+(d-k)l_1 + kl_2 + t_j)\\\\
& & \\left[ F^{p,q}_j \\right] = \\frac{\\wh{P}_{r,d}(H)}{(H+pl_1 + ql_2+t_j)}\\\\
& & e_{n,m|u,v;j}= \\prod_{(w,z)\\neq (n,m)}((w-n)l_1 + (z-m)l_2) \\prod_{(f,s;b) \\neq (u,v;j)} ((f-u)l_1 + (s-v)l_2 + t_b - t_j)\\\\
& & i^*_{n,m|u,v;j}(h_i^k)= (-nl_1-ml_2)^k\\\\
& & \\wh{\\alpha}_{i,k|r}(H,t_1,\\dots,t_{r+1})= \\sum_{n,m|u,v;j} \\frac{[F^{n+u,m+v}_j] (-nl_1-ml_2)^k}{e_{n,m|u,v;j}}
\\end{align}

\\bigskip

%%JC%% \\dcolor -> red
\\dcolor{Maybe we need also to check whether equivariantly:
\\[
N_{E(1,0 | 2,0)} \\wt{Z}_1 = p_1^*(N_{E(1,0)} \\Pro(W_1))  \\otimes p_2^*(N_{E(2,0)}  \\Pro(W_{2}^{\\oplus 3})
\\]
}

\\dcolor{Keep explaining the algorithm and define the classes $\\wh{\\alpha}_{i,k|r}(H)$}.

\\begin{lemma}\\label{lemma.big.pol}
We have the inclusion $P_{r,d}(H) \\in \\im(i_*)$.
\\end{lemma}

\\begin{dem}
(TO DO)
\\end{dem}

\\section{The Case $d=1$}

In this section we apply the algorithm to the case of linear maps. The space $\\Mcal_{0,0}(\\Pro^{r},1)$ is  the Grassmannian of lines in $\\Pro^r$. The integral Chow ring of Grassmannians is well known (see for example \\cite[Theorem 5.26]{3264}), therefore the result we determine in this section is not original but allows us to illustrate the algorithm in the simplest case.
Thanks to Section \\ref{section.algorithm},  the integral Chow ring of $\\Mcal_{0,0}(\\Pro^{r},1)$ has the form:
\\[
\\Z[c_1,c_2]/I
\\]
where $I$ is the ideal generated by the classes $\\wh{\\alpha}_{1,0|r}(-(l_1+l_2),0,\\dots,0)$ and $\\wh{\\alpha}_{1,1|r}(-(l_1+l_2),0,\\dots,0)$. Our next goal is to write the rigidified classes $ \\wh{\\alpha}_{1,0|r}(-(l_1+l_2),t_1,\\dots,t_{r+1})$ and $ \\wh{\\alpha}_{1,1|r}(-(l_1+l_2),t_1,\\dots,t_{r+1})$ explicitly.

We have:

\\begin{align}
& & \\wh{P}_{r,1}(-(l_1+l_2))=\\prod_{b=1}^{r+1}(t_b-l_1)(t_b-l_2)\\\\
& & \\left. \\left[ F^{1,0}_j \\right] \\right |_{H=-(l_1+l_2)}=\\frac{\\di \\prod_{b=1}^{r+1}(t_b-l_1)(t_b-l_2)}{(t_j-l_2)}\\\\
& & \\left. \\left[ F^{0,1}_j \\right] \\right |_{H=-(l_1+l_2)}=\\frac{\\di \\prod_{b=1}^{r+1}(t_b-l_1)(t_b-l_2)}{(t_j-l_1)}\\\\
& & e_{1,0|0,0;j} =(l_2 - l_1) \\prod_{b \\neq j} (t_b - t_j)\\\\
& & e_{0,1|0,0;j} =(l_1 - l_2) \\prod_{b \\neq j} (t_b - t_j)\\\\
\\end{align}

We now write the classes $\\wh{\\alpha}$:

\\begin{align}
\\wh{\\alpha}_{1,0|r}(-(l_1+l_2),t_1,\\dots,t_{r+1})  & = & \\sum_{j=1}^{r+1} \\left( \\frac{ \\left[ F^{1,0}_j \\right]}{e_{1,0|0,0;j}}+\\frac{ \\left[ F^{0,1}_j \\right]}{e_{0,1|0,0;j}} \\right)= \\\\
& = & \\sum_{j=1}^{r+1} \\left( \\frac{\\di \\prod_{b=1}^{r+1}(t_b-l_1)(t_b-l_2)}{\\di (t_j-l_2)(l_2 - l_1) \\prod_{b \\neq j} (t_b - t_j)}-\\frac{\\di \\prod_{b=1}^{r+1}(t_b-l_1)(t_b-l_2)}{\\di (t_j-l_1)(l_2 - l_1) \\prod_{b \\neq j} (t_b - t_j)} \\right)=\\\\
& = & \\sum_{j=1}^{r+1} \\prod_{b \\neq j} \\frac{(t_b-l_1)(t_b-l_2)}{(t_b - t_j)}\\\\
\\wh{\\alpha}_{1,1|r}(-(l_1+l_2),t_1,\\dots,t_{r+1})  & = & \\sum_{j=1}^{r+1} \\left( \\frac{ \\left[ F^{1,0}_j \\right] \\cdot (-l_1)}{e_{1,0|0,0;j}}+\\frac{ \\left[ F^{0,1}_j \\right] \\cdot (-l_2)}{e_{0,1|0,0;j}} \\right)= \\\\
& = & \\sum_{j=1}^{r+1} \\left( \\frac{\\di (-l_1)\\prod_{b=1}^{r+1}(t_b-l_1)(t_b-l_2)}{\\di (t_j-l_2)(l_2 - l_1) \\prod_{b \\neq j} (t_b - t_j)}-\\frac{\\di (-l_2)\\prod_{b=1}^{r+1}(t_b-l_1)(t_b-l_2)}{\\di (t_j-l_1)(l_2 - l_1) \\prod_{b \\neq j} (t_b - t_j)} \\right)=\\\\
& = & \\sum_{j=1}^{r+1} (t_j-l_1-l_2) \\prod_{b \\neq j} \\frac{(t_b-l_1)(t_b-l_2)}{(t_b - t_j)}\\\\
\\end{align}

By setting $t_i=0$ for all $i=1, \\dots, r+1$, we get the classes $\\alpha_{1,0|r}(-(l_1+l_2))$ and $\\alpha_{1,1|r}(-(l_1+l_2))$. Thanks to the extra subtitution $c_1=-(l_1+l_2)$ and $c_2=l_1l_2$ we can get our final answer. However, we would like to write the classes $\\alpha_{1,0|r}(-(l_1+l_2))$ and $\\alpha_{1,1|r}(-(l_1+l_2))$ in a more explicit way. This is done in Theorem \\ref{thm.Chow.linear} where the classes $\\alpha_{1,0|r}(-(l_1+l_2))$ and $\\alpha_{1,1|r}(-(l_1+l_2))$ are respectively the formal terms of total degree $r$ and $r+1$ in the power series expansion of the function
\\[
\\frac{1}{1-c_1+c_2}.
\\]

The method we adopt to prove Theorem \\ref{thm.Chow.linear} is quite straightforward. We just need to show the following formal identities\\damiano{Do we need to explicitly explain why the following two identities are enough?}:

\\begin{itemize}

\\item $\\alpha_{1,1|r}(-(l_1+l_2))=\\alpha_{1,0|r+1}(-(l_1+l_2))$;

\\item $\\alpha_{1,0|r+2}(-(l_1+l_2)) - c_1\\alpha_{1,0|r+1}(-(l_1+l_2)) + c_2\\alpha_{1,0|r}(-(l_1+l_2)) = 0$.

\\end{itemize}

Notice that the identities are formal because the classes $\\alpha$ live in different Chow rings.

The proofs of the above identities are straightforward computations that make use of the following Lemma.

\\begin{lemma}\\label{lemma.rec.prod}
We have the identity\\damiano{I would ask an algebraic combinatorial whether this is a known identity}:
\\[
\\sum_{j=1}^{n}\\frac{1}{\\di t_j \\prod_{b \\neq j} (t_b-t_j)}=\\frac{1}{t_1 t_2 \\dots t_n}.
\\]
\\end{lemma}
\\begin{dem}
It is enough to prove the identity:
\\[
\\sum_{j=1}^{n}\\prod_{b \\neq j} \\frac{t_b}{\\di t_b-t_j}=1.
\\]
Let us consider the polynomial $P(x)$ with coefficients in the field $\\Q(t_1, t_2, \\dots, t_n)$:
\\[
P(x):= \\sum_{j=1}^{n}\\prod_{b \\neq j} \\frac{t_b-x}{\\di t_b-t_j}.
\\]
Notice that $P(x)$ is a polynomial of degree at most $n-1$, therefore $P(x)$ is uniquely determined by its evaluations at $n$ different elements of $\\Q(t_1, t_2, \\dots, t_n)$. Now, for every $i=1, \\dots, n$ we have $P(t_i)=1$, therefore $P(x)$ is the constant polynomial 1. In particular, we have:
\\[
P(0)= \\sum_{j=1}^{n}\\prod_{b \\neq j} \\frac{t_b}{\\di t_b-t_j}=1.
\\]
\\end{dem}

\\begin{propos}\\label{reduction.deg.0}
For every positive integer $r$, we have the identity:
\\[
\\alpha_{1,1|r}(-(l_1+l_2))=\\alpha_{1,0|r+1}(-(l_1+l_2)).
\\]
\\end{propos}

\\begin{dem}
It is enough to show the following identity for every positive integer $r$:
\\[
\\wh{\\alpha}_{1,1|r}(-(l_1+l_2),t_1,\\dots,t_{r+1})=\\wh{\\alpha}_{1,0|r+1}(-(l_1+l_2),t_1,\\dots,t_{r+1}, 0).
\\]
In particular we substitute $t_{r+2}=0$ on the right side of the equation in order to have the same set of variables on both sides. Therefore, we need to show the following identity:
\\[
\\sum_{j=1}^{r+1} \\left( \\frac{\\di (t_j-l_1-l_2) \\prod_{b \\neq j}(t_b-l_1)(t_b-l_2)}{\\di \\prod_{b \\neq j} (t_b - t_j)} \\right) =  \\sum_{j=1}^{r+1} \\left(\\frac{\\di  l_1l_2 \\prod_{b \\neq j}(t_b-l_1)(t_b-l_2)}{\\di (-t_j)\\prod_{b \\neq j} (t_b - t_j)} \\right) + \\frac{\\di \\prod_{b=1}^{r+1}(t_b-l_1)(t_b-l_2)}{t_1 \\dots t_{r+1}}
\\]
By combining the two summations and dividing by $\\di \\prod_{b=1}^{r+1}(t_b-l_1)(t_b-l_2)$ on both sides we get:

\\[
\\sum_{j=1}^{r+1} \\left [ \\frac{t_j-l_1-l_2}{(t_j-l_1)(t_j-l_2)} + \\frac{l_1l_2}{t_j(t_j-l_1)(t_j-l_2)}\\right]\\frac{1}{\\di \\prod_{b \\neq j} (t_b - t_j)} =  \\frac{1}{t_1 \\dots t_{r+1}}
\\]

We then further simplify to get:

\\[
\\sum_{j=1}^{r+1} \\frac{1}{\\di t_j \\prod_{b \\neq j} (t_b - t_j)} =  \\frac{1}{t_1 \\dots t_{r+1}}
\\]
which is exactly the identity from Lemma \\ref{lemma.rec.prod}.
\\end{dem}

\\begin{propos}\\label{recursive.linear}
For every positive integer $r$, we have the following recurrence relation:
\\[
\\alpha_{1,0|r+2}(-(l_1+l_2)) - c_1\\alpha_{1,0|r+1}(-(l_1+l_2)) + c_2\\alpha_{1,0|r}(-(l_1+l_2)) = 0
\\]
\\end{propos}

\\begin{dem}
It is enough to show that, for every positive integer $r$, the expression:
\\[
\\wh{\\alpha}_{1,0|r+2}(-(l_1+l_2),t_1,\\dots,t_{r+3}) + (l_1+l_2)\\wh{\\alpha}_{1,0|r+1}(-(l_1+l_2),t_1,\\dots,t_{r+2}) +(l_1l_2)\\wh{\\alpha}_{1,0|r}(-(l_1+l_2),t_1,\\dots,t_{r+1})
\\]
is in the ideal generated by $t_1, t_2, \\dots, t_{r+3}$. We will actually be able to show that the above expression is in the ideal generated by $t_{r+2}$ and $t_{r+3}$. Before diving into the computations, let us simplify our notation:
\\[
\\gamma_{r}:=\\wh{\\alpha}_{1,0|r}(-(l_1+l_2),t_1,\\dots,t_{r+1})= \\sum_{j=1}^{r+1}\\prod_{b \\neq j} \\frac{(t_b-l_1)(t_b-l_2)}{(t_b - t_j)}.
\\]
We are now going to show that the expression $\\gamma_{r+2}+(l_1+l_2)\\gamma_{r+1}+(l_1l_2)\\gamma_r$, which explicitly is equal to:
\\begin{equation}\\label{equation.recursive}
\\sum_{j=1}^{r+3} \\prod_{b \\neq j} \\frac{(t_b-l_1)(t_b-l_2)}{(t_b - t_j)} +(l_1+l_2)\\sum_{j=1}^{r+2}  \\prod_{b \\neq j}\\frac{(t_b-l_1)(t_b-l_2)}{(t_b - t_j)} +(l_1l_2) \\sum_{j=1}^{r+1}\\prod_{b \\neq j} \\frac{(t_b-l_1)(t_b-l_2)}{(t_b - t_j)},
\\end{equation}
is in the ideal generated by $t_{r+3}$ and $t_{r+2}$. First, we set $t_{r+3}=0$:
\\[
\\prod_{b=1}^{r+2}\\frac{(t_b-l_1)(t_b-l_2)}{t_b} +\\sum_{j=1}^{r+2}\\frac{(l_1l_2)}{(-t_j)} \\prod_{b \\neq j} \\frac{(t_b-l_1)(t_b-l_2)}{(t_b - t_j)}+\\sum_{j=1}^{r+2}(l_1+l_2) \\prod_{b \\neq j} \\frac{(t_b-l_1)(t_b-l_2)}{(t_b - t_j)} +(l_1l_2) \\gamma_{r}.
\\]
Let us now simplify the first three terms of the expression by factoring out $\\di \\prod_{b=1}^{r+2}(t_b-l_1)(t_b-l_2)$ and applying Lemma \\ref{lemma.rec.prod}:
\\[
 \\prod_{b=1}^{r+2}(t_b-l_1)(t_b-l_2) \\left[ \\sum_{j=1}^{r+2}\\frac{1}{t_j}\\frac{1}{\\di \\prod_{b \\neq j} (t_b-t_j)} + \\sum_{j=1}^{r+2} \\frac{(l_1l_2)}{(-t_j)(t_j-l_1)(t_j-l_2)}\\frac{1}{\\di \\prod_{b \\neq j} (t_b-t_j)} + \\sum_{j=1}^{r+2} \\frac{(l_1+l_2)}{(t_j-l_1)(t_j-l_2)}\\frac{1}{\\di \\prod_{b \\neq j} (t_b-t_j)}\\right],
\\]
straightforward computations show that the above expression is equal to:
 \\[
 \\sum_{j=1}^{r+2} t_j \\prod_{b \\neq j} \\frac{(t_b-l_1)(t_b-l_2)}{(t_b-t_j)}.
 \\]
 It is now enough to show that $\\di  \\sum_{j=1}^{r+2} t_j \\prod_{b \\neq j} \\frac{(t_b-l_1)(t_b-l_2)}{(t_b-t_j)}+(l_1l_2)\\gamma_r$ is in the ideal generated by $t_{r+2}$. By setting $t_{r+2}=0$ we get:

\\begin{align}
&& \\sum_{j=1}^{r+2} t_j \\prod_{b \\neq j} \\frac{(t_b-l_1)(t_b-l_2)}{(t_b-t_j)} + \\sum_{j=1}^{r+1} (l_1l_2) \\prod_{b \\neq j} \\frac{(t_b-l_1)(t_b-l_2)}{(t_b - t_j)} =\\\\
&& = \\sum_{j=1}^{r+1} \\frac{t_j(l_1l_2)}{(-t_j)} \\prod_{b \\neq j} \\frac{(t_b-l_1)(t_b-l_2)}{(t_b-t_j)} + \\sum_{j=1}^{r+1} (l_1l_2) \\prod_{b \\neq j} \\frac{(t_b-l_1)(t_b-l_2)}{(t_b-t_j)}=\\\\
&& = 0.
\\end{align}
\\end{dem}

By combining Propositions \\ref{reduction.deg.0} and \\ref{recursive.linear} we get the following result.

\\begin{theorem}\\label{thm.Chow.linear}
The integral Chow ring of $\\Mcal_{0,0}(\\Pro^{r},1)$ has the form:
\\[
\\Z[c_1,c_2]/I,
\\]
where $I$ is the ideal generated by the terms of total degree $r$ and $r+1$ in the power series expansion:
\\[
\\frac{1}{1 - c_1 + c_2} = 1 - (- c_1 + c_2) + (- c_1+c_2)^2 - \\dots
\\]
\\end{theorem}

The above result is consistent with \\cite[Theorem 5.26]{3264} up to replacing our $c_1$ with $-c_1$.

\\newpage

\\section{The case $d=3$}

\\dcolor{Add short intro if and when we get final result.}

We have:

\\begin{align}
\\wh{P}_{r,3}(-2(l_1+l_2)) &=& \\prod_{b=1}^{r+1}(t_b+l_1 - 2l_2)(t_b-l_1)(t_b-l_2)(t_b-2l_1+l_2)\\\\
\\left. \\left[ F^{3,0}_j \\right] \\right |_{H=-2(l_1+l_2)} &=& \\frac{\\di \\prod_{b=1}^{r+1}(t_b+l_1 - 2l_2)(t_b-l_1)(t_b-l_2)(t_b-2l_1+l_2)}{(t_j +l_1-2l_2)}\\\\
\\left. \\left[ F^{2,1}_j \\right] \\right |_{H=-2(l_1+l_2)} &=& \\frac{\\di \\prod_{b=1}^{r+1}(t_b+l_1 - 2l_2)(t_b-l_1)(t_b-l_2)(t_b-2l_1+l_2)}{(t_j - l_2)}\\\\
\\left. \\left[ F^{1,2}_j \\right] \\right |_{H=-2(l_1+l_2)} &=& \\frac{\\di \\prod_{b=1}^{r+1}(t_b+l_1 - 2l_2)(t_b-l_1)(t_b-l_2)(t_b-2l_1+l_2)}{(t_j - l_1)}\\\\
\\left. \\left[ F^{0,3}_j \\right] \\right |_{H=-2(l_1+l_2)} &=& \\frac{\\di \\prod_{b=1}^{r+1}(t_b+l_1-2l_2)(t_b-l_1)(t_b-l_2)(t_b-2l_1+l_2)}{(t_j-2l_1+l_2)}\\\\
e_{1,0|2,0;j} &=& (l_2 - l_1) \\prod_{b \\neq j} (t_b - t_j)\\prod_{b=1}^{r+1}(l_2 - l_1+ t_b - t_j)\\prod_{b=1}^{r+1}(2(l_2-l_1)+t_b-t_j)=\\\\
& = & 2(l_2 - l_1)^3 \\prod_{b \\neq j} (t_b - t_j)(l_2 - l_1+ t_b - t_j)(2(l_2-l_1)+t_b-t_j) \\\\
e_{0,1|2,0;j} &=& -2(l_2 - l_1)^3 \\prod_{b \\neq j} (t_b - t_j)(l_2 - l_1+ t_b - t_j)(2(l_2-l_1)+t_b-t_j) \\\\
e_{1,0|1,1;j} &=& (l_2-l_1)\\prod_{b=1}^{r+1}(l_1-l_2 + t_b - t_j)\\prod_{b \\neq j} (t_b-t_j)\\prod_{b=1}^{r+1}(l_2 - l_1+t_b-t_j) =\\\\
&=& -(l_2-l_1)^3\\prod_{b \\neq j}(l_1-l_2 + t_b - t_j)(t_b-t_j)(l_2 - l_1+t_b-t_j) \\\\
e_{0,1|1,1;j} & = & (l_2-l_1)^3\\prod_{b \\neq j}(l_1-l_2 + t_b - t_j)(t_b-t_j)(l_2 - l_1+t_b-t_j)\\\\
e_{1,0|0,2;j} &=& (l_2-l_1)\\prod_{b=1}^{r+1}(2(l_1-l_2)+t_b-t_j)\\prod_{b=1}^{r+1}(l_1-l_2+t_b-t_j)\\prod_{b \\neq j}(t_b-t_j)=\\\\
& = & 2(l_2-l_1)^3\\prod_{b \\neq j}(2(l_1-l_2)+t_b-t_j)(l_1-l_2+t_b-t_j)(t_b-t_j)\\\\
e_{0,1|0,2;j} &=& - 2(l_2-l_1)^3\\prod_{b \\neq j}(2(l_1-l_2)+t_b-t_j)(l_1-l_2+t_b-t_j)(t_b-t_j)\\\\
\\end{align}

\\begin{align}
\\wh{\\alpha}_{1,0|r}(-(l_1+l_2),t_1, t_2, \\dots, t_{r+1}) & = & \\sum_{j=1}^{r+1} \\left( \\frac{\\left[ F^{3,0}_j \\right] } {e_{1,0|2,0;j}} + \\frac{\\left[ F^{2,1}_j \\right] } {e_{0,1|2,0;j}}+\\frac{\\left[ F^{2,1}_j \\right] } {e_{1,0|1,1;j}}+\\frac{\\left[ F^{1,2ñ}_j \\right] } {e_{0,1|1,1;j}} + \\frac{\\left[ F^{1,2}_j \\right] } {e_{1,0|0,2;j}}+\\frac{\\left[ F^{0,3}_j \\right] } {e_{0,1|0,2;j}}\\right) = \\\\
&=& \\sum_{j=1}^{r+1}\\frac{\\di  D_j \\cdot \\prod_{b \\neq j}(t_b+l_1 - 2l_2)(t_b-l_1)(t_b-l_2)(t_b-2l_1+l_2)}{\\di 2(l_2-l_1)^2 \\prod_{b \\neq j}(t_b-t_j)\\left( (t_b-t_j)^2-(l_2-l_1)^2\\right)\\left( (t_b-t_j)^2 - 4(l_2-l_1)^2 \\right)}
\\end{align}

where

\\begin{align}
D_j &=& (t_j - l_1)(t_j-2l_1+l_2)\\prod_{b \\neq j} \\left( (t_b - t_j)^2 - 3(t_b-t_j)(l_2-l_1) + 2(l_2-l_1)^2 \\right) +\\\\
& & - 2 (t_j + l_1 - 2l_2)(t_j-2l_1+l_2) \\prod_{b \\neq j} \\left( (t_b - t_j)^2 - 4(l_2-l_1)^2 \\right) +\\\\
& & + (t_j + l_1 -2l_2)(t_j-l_2) \\prod_{b \\neq j} \\left( (t_b - t_j)^2 + 3(t_b-t_j)(l_2-l_1) + 2(l_2-l_1)^2 \\right)
\\end{align}

\\dcolor{$D_j$ seems to be a multiple of $6(l_2-l_1)^2$ for every $r$, I have a very rough proof that $D_j$ is a multiple of $(l_2-l_1)^2$, but I have no way to write the quotient in an explicit form, by the way $6(l_2-l_1)^2$ is equal to $D_j$ with the $\\prod=1$, in some sense for $r=0$.}

[TO FINISH]

\\section{The Case $r=2$ and $d=3$}

In this section we write explicitly the case of rational cubics in $\\Pro^2$ and we reduce the generators as much as possible.

\\begin{tabular}{l|l}
Classes & Reduction\\\\
\\hline
& \\\\
$Z[1,0]=9 c_1^2 - 27c_2$ & \\fbox{$9 c_1^2 - 27c_2$}\\\\
& \\\\
$Z[1,1]=c_1(8c_1^2 - 27c_2)$ & $\\text{\\fbox{$c_1^3$}}=c_1\\cdot Z[1,0]-Z[1,1]$\\\\
& moreover, $27c_1 c_2$ is generated by $c_1^3$ and $Z[1,1]$\\\\
& \\\\
$Z[2,0]=3(4c_1^4 - 30c_1^2 c_2 + 63c_2^2)$ & $\\text{\\fbox{$81c_2^2$}} = 12c_1^4 - Z[2,0]-10c_2\\cdot Z[1,0]$ \\\\ 
& \\\\
$Z[2,1]=8c_1(2c_1^4 - 14c_1^2 c_2 + 27c_2^2)$ & $Z[2,1]=16c_1^3(c_1^2-7c_2) +27c_1c_2(8c_2)$ \\\\ 
& therefore, $Z[2,1]$ is already in the ideal \\\\
& \\\\
$Z[2,2]=24c_1^6 - 164c_1^4 c_2 +306c_1^2c_2^2 - 27c_2^4$ & $Z[2,2]=4c_1^3(6c_1^3-41c_1 c_2) + 34c_2^2\\cdot Z[1,0]+ (11c_2)(81c_2^2)$\\\\
& therefore, $Z[2,2]$ is already in the ideal\\\\
& \\\\
$Z[3,0]=4c_1^6 - 42c_1^4c_2+129c_1^2c_2^2 - 90c_2^3$ &\\fbox{$3c_2^2(7c_1^2-3c_2)$}$= Z[3,0]-2c_1^3(2c_1^3-21c_1c_2) - 27c_1 c_2(4c_1c_2) + 81c_2^3$ \\\\
& \\\\
$Z[3,1]=2c_1(4c_1^6-44c_1^4c_2 +148c_1^2c_2^2 - 135c_2^3)$ & $Z[3,1]=8c_1^3(c_1^4-11c_1^2c_2 +37c_2^2) - 270c_1c_2^3$\\\\
& therefore, $Z[3,1]$ is already in the ideal\\\\
& \\\\
\\begin{tabular}{rcl}
$Z[3,2]$ &$=$&$16c_1^8-184c_1^6c_2+672c_1^4c_2 +$\\\\
&& $- (27 \\cdot 28)c_1^2 c_2^3 + 81c_2^4$
\\end{tabular}
& therefore, $Z[3,2]$ is already in the ideal\\\\
& \\\\
\\begin{tabular}{rcl}
$Z[3,3]$ &$=$&$32c_1^9+384c_1^7c_2-1512c_1^5c_2^2+$\\\\
&& $+2016c_1^3c_2^3 - (18 \\cdot 27)c_1c_2^4$
\\end{tabular}
& therefore, $Z[3,3]$ is already in the ideal\\\\
& \\\\
\\end{tabular}

In conclusion:

\\begin{theorem}
We have the isomorphism:
\\[
A^* \\left( \\Mcal_{0,0}\\left( \\Pro^2, 3 \\right) \\right) \\cong \\frac{\\Z[c_1,c_2]}{(9c_1^2 - 27c_2,c_1^3,81c_2^2, 3c_2^2(7c_1^2-3c_2))}
\\]
\\end{theorem}


\\section{Combinatorial formula for relations}

We use the following notation:

\\begin{itemize}

\\item $d$ is the degree of the curves;

\\item $r$ is the dimension of the ambient space;

\\item $\\Pro (W_{d}^{\\oplus r+1})= \\mathbb{P}^{N}$, with $N = rd+r+d$;

\\item $Z_i = \\Pro (W_{i})\\times \\Pro (W_{d-i}^{\\oplus r+1}) = \\Pro^{i}\\times \\Pro^{N_{d-i}}$, with $N_{d-i} = rd+r+d-ri-i$;

\\item $P_d(x) = (x+ d\\alpha_1)\\cdot (x+ (d-1)\\alpha_1+ \\alpha_2)\\cdot \\ldots \\cdot (x+ (d-1)\\alpha_1+ \\alpha_2)\\cdot (x+ d\\alpha_2) = x^{d+1}+ b(d)_1x^d +\\ldots +b(d)_{d+1}$;

\\item $Q_d(x) = P_d(x)^{r+1} = x^{(d+1)(r+1)}+ a(d)_1x^{dr+d+r} +\\ldots +a(d)_{(d+1)(r+1)}$;

\\item $\\rho(d)_k  = \\left[x^{d+k} \\textbf{mod $P_d(x)$} \\right]_{x^d}$;

\\item $\\sigma(d)_k  = \\left[x^{dr+d+r+k} \\textbf{mod $Q_d(x)$} \\right]_{x^{dr+d+r}}$.

\\item In $Z_i$, we have $p_{i \\ast}(h^j) = \\sum p_{i,j,k} H^{ri+j -k}$
\\end{itemize}

\\begin{lemma}
\\begin{equation}
\\sum \\rho(d)_k y^k =\\frac{1}{1+ b(d)_1y+ \\ldots + b(d)_{d+1}y^{d+1}} =  \\frac{1}{y^{d+1}P_d(\\frac{1}{y})}.
\\end{equation}
\\end{lemma}
\\begin{proof}
We start from the equality:
\\begin{equation}\\label{eq:div}
x^{d+k} = P_d(x)Q_k(x) + R_k(x),
\\end{equation}
where $Q_k$ is a polynomial of degree $k-1$, and $R_k(x) = \\rho(d)_k x^d+l.o.t.$.
Multiply \\eqref{eq:div} by $x^2$ and divide by $P_d(x)$ to obtain:
\\begin{equation}\\label{eq:div2}
\\frac{x^{d+k+2}}{P_d(x)} = x^2 Q_k(x) + \\frac{x^2R_k(x)}{P_d(x)}.
\\end{equation}
Now think of \\eqref{eq:div2} as an equality of meromorphic functions on $\\mathbb{P}^1$ and switch to chart around infinity with $\\tilde{x} = 1/x$:
\\begin{equation}\\label{eq:div3}
\\frac{1}{\\tilde{x}^{d+k+2}P_d(1/\\tilde{x})} = \\frac{1}{\\tilde x^2} Q_k(1/\\tilde{x}) + \\frac{R_k(1/\\tilde{x})}{\\tilde x^2P_d(1/\\tilde{x})}.
\\end{equation}
Now take a loop around $\\tilde x = 0$, small enough to miss all roots of  $P_d$, and integrate:
\\begin{equation}\\label{eq:div4}
\\int_\\gamma \\frac{d \\tilde x }{\\tilde{x}^{d+k+2}P_d(1/\\tilde{x})} = \\int_\\gamma  d \\tilde x \\left[\\frac{1}{\\tilde x^2} Q_k(1/\\tilde{x}) + \\frac{R_k(1/\\tilde{x})}{\\tilde x^2P_d(1/\\tilde{x})}\\right].
\\end{equation}
We evaluate the right hand side of \\eqref{eq:div4} using the residue theorem to obtain (ignoring the factor of $2\\pi i$):
\\begin{equation}\\label{eq:div5}
 \\int_\\gamma  d \\tilde x \\left[\\frac{1}{\\tilde x^2} Q_k(1/\\tilde{x}) + \\frac{R_k(1/\\tilde{x})}{\\tilde x^2P_d(1/\\tilde{x})}\\right] = \\rho(d)_k.
\\end{equation}
We see \\eqref{eq:div5} as follows: the  term $\\frac{1}{\\tilde x^2} Q_k(1/\\tilde{x})$ is already in Laurent expansion and has no residue. For the other term:
\\begin{equation}\\label{eq:div6}
 \\frac{R_k(1/\\tilde{x})}{\\tilde x^2P_d(1/\\tilde{x})} = \\frac{\\tilde x^{d+1}}{\\tilde x^2 \\tilde x ^d} \\frac{\\tilde x^d R_k(1/\\tilde{x})}{\\tilde x^{d+1}P_d(1/\\tilde{x})} =\\frac{1}{\\tilde x} \\frac{\\rho(d)_k+ \\tilde x \\varphi(\\tilde x)}{1+ \\tilde x \\psi(\\tilde x)},
\\end{equation}
where $\\varphi, \\psi$ are regular at $\\tilde x = 0$. The residue statement follows.
With this information we return to \\eqref{eq:div4} and sum over all powers $k$:
\\begin{equation}\\label{eq:div6}
\\sum_k \\int_\\gamma \\frac{y^k d \\tilde x  }{\\tilde{x}^{d+k+2}P_d(1/\\tilde{x})} = \\sum_k \\rho(d)_k y^k.
\\end{equation}
We now manipulate the left hand side by collecting a geometric series in $y/\\tilde x$: 
\\begin{equation}\\label{eq:div7}
\\sum_k \\int_\\gamma \\frac{y^k d \\tilde x  }{\\tilde{x}^{d+k+2}P_d(1/\\tilde{x})} =  \\int_\\gamma \\frac{ d \\tilde x  }{(\\tilde x -y)\\tilde{x}^{d+1}P_d(1/\\tilde{x})}.
\\end{equation}
And finally evaluate the integral by computing the residue at $\\tilde x = y$ to obtain (again neglecting the $2\\pi i$):
\\begin{equation}\\label{eq:div7}
  \\int_\\gamma \\frac{ d \\tilde x  }{(\\tilde x -y)\\tilde{x}^{d+1}P_d(1/\\tilde{x})} =  \\frac{ 1 }{\\tilde{y}^{d+1}P_d(1/y)}.
\\end{equation}
\\end{proof}
We have a similar relation for the $\\sigma$'s:

\\begin{equation}
\\sum \\sigma(d)_k x^k =\\frac{1}{1+ a(d)_1x+ \\ldots + a(d)_{(d+1)(r+1)}x^{(d+1)(r+1)}} =  \\frac{1}{x^{(d+1)(r+1)}Q_d(\\frac{1}{x})}.
\\end{equation}

The equality in the two above lines is given by the expansion at $0$ of the analytic functions on the right hand sides.

The formula for the $p_{i,j,k}$ should, now be:

\\begin{equation} \\label{coeffform}
p_{i,j,k}  = \\sum_{e+f+g = k}  a(d)_e \\cdot \\rho(i)_f \\cdot \\sigma(d-i)_g {{N_{d-i} +i-j+f+g}\\choose{i-j+f}}
\\end{equation}

Towards a generating function formulation of this computation.
Consider:

\\begin{equation}
R_d \\left(\\frac{1}{z}\\right) =  \\frac{z^{d+1}}{P_d(z)} = \\sum  \\frac{\\rho(d)_k}{ z^k}
\\end{equation}

The quantized operator acts on the element $e^{tz}$ of $H^+$ (Tom Coates thesis page 35):

\\begin{equation}
\\widehat{R_d}(e^{tz})_{|\\frac{1}{\\hbar} =0} = \\left[R_d \\left(\\frac{1}{z}\\right)  e^{tz} \\right]_+ = \\sum_{f, k \\geq 0} \\rho(d)_f \\frac{t^{f+k}}{(f+k)!} z^k
\\end{equation}

And similarly for the polynomial $Q_d$:

\\begin{equation}
S_d \\left(\\frac{1}{z}\\right) =  \\frac{z^{(d+1)(r+1)}}{Q_d(z)} = \\sum  \\frac{\\sigma(d)_k}{ z^k}
\\end{equation}
\\begin{equation}
\\widehat{S_d}(e^{tz})_{|\\frac{1}{\\hbar} =0} = \\left[S_d \\left(\\frac{1}{z}\\right)  e^{tz} \\right]_+ = \\sum_{g, k \\geq 0} \\sigma(d)_f \\frac{t^{g+k}}{(g+k)!} z^k
\\end{equation}

Next we multiply:

\\begin{equation}
\\left(\\widehat{R_i}(e^{tz_1})_{|\\frac{1}{\\hbar} =0} \\right)\\left(\\widehat{S_{d-i}}(e^{tz_2})_{|\\frac{1}{\\hbar} =0} \\right) = \\sum_{f,g,k_1, k_2\\geq 0}  \\rho(i)_f  \\sigma(d-i)_g\\frac{t^{f+g+k_1+k_2}}{(f+k_1)!(g+k_2)!} z_1^{k_1}z_2^{k_2}
\\end{equation}

We now take the Laplace transform with respect to the variable $t$:

\\begin{equation}
\\mathcal{L}\\left[\\left(\\widehat{R_i}(e^{tz_1})_{|\\frac{1}{\\hbar} =0} \\right)\\left(\\widehat{S_{d-i}}(e^{tz_2})_{|\\frac{1}{\\hbar} =0} \\right)\\right] = \\sum_{f,g,k_1, k_2\\geq 0}  \\rho(i)_f  \\sigma(d-i)_g {{f+g+k_1+k_2}\\choose{f+k_1,g+k_2}} \\frac{z_1^{k_1}z_2^{k_2}}{s^{f+g+k_1+k_2+1}}.
\\end{equation}

Multiply by  ${Q_d({s})}$:

\\begin{align}
\\mathfrak{P}_{i,d,r}(s,z_1,z_2)&= Q_d\\left(s\\right) \\mathcal{L}\\left[\\left(\\widehat{R_i}(e^{tz_1})_{|\\frac{1}{\\hbar} =0} \\right)\\left(\\widehat{S_{d-i}}(e^{tz_2})_{|\\frac{1}{\\hbar} =0} \\right)\\right] \\\\ & = \\sum_{e,f,g,k_1, k_2\\geq 0} a(d)_e \\rho(i)_f  \\sigma(d-i)_g {{f+g+k_1+k_2}\\choose{f+k_1,g+k_2}} \\frac{z_1^{k_1}z_2^{k_2}}{s^{e+f+g+k_1+k_2+1-(r+1)(d+1)}}.
\\end{align}

Now let us look at the coefficient of $z_1^{i-j}z_2^{N_{d-i}}$ and evaluate $s = H$:

\\begin{equation}
\\left[\\mathfrak{P}_{i,d,r}(H,z_1,z_2)\\right]_{\\tiny z_1^{i-j}z_2^{N_{d-i}}}  = \\sum_{e,f,g\\geq 0} a(d)_e \\rho(i)_f  \\sigma(d-i)_g {{f+g+i-j+N_{d-i}}\\choose{f+i-j,g+N_{d-i}}} {H^ {ri +j-e-f-g  }}.
\\end{equation}
Comparing with \\eqref{coeffform}, we have:

\\begin{equation}
\\left[\\left[\\mathfrak{P}_{i,d,r}(H,z_1,z_2)\\right]_{\\tiny z_1^{i-j}z_2^{N_{d-i}}} \\right]_+ = p_{i\\ast}(h^j).
\\end{equation}


\\section{Relationology}

Consider the function:
$$
F(c_1, c_2, d)  = \\sum_r \\pi_{1, \\ast} [1],
$$
i.e. the relations obtained from pushing forward the fundamental class from the first component of the envelope (common lines). 

\\begin{conj}

\\[
F(c_1, c_2, d)  = \\frac{d}{(1+\\frac{d-1}{2}c_1)(1-\\frac{d+1}{2}c_1)+d^2c_2}
\\]

Supporting evidence:

\\begin{itemize}
\\item $F(c_1, c_2, 1) = \\frac{1}{1-c_1+c_2}$, which is the Grassmannian case.
\\item $F(c_1,0,d)$, $F(0,c_2,d)$ agree with experimental computations.
\\item All mixed terms checked for $d=3, r\\leq 9$ and $d=7, r\\leq 9$.
\\end{itemize}

\\end{conj}

Consider the function:
$$
G(c_1, c_2, d)  = \\sum_r \\pi_{1, \\ast} [h],
$$
i.e. the relations obtained from pushing forward the class of a point from the first component of the envelope (common lines). 

\\begin{conj}
\\[
G(c_1, c_2, d)  = \\frac{1+\\frac{d-1}{2}c_1}{(1+\\frac{d-1}{2}c_1)(1-\\frac{d+1}{2}c_1)+d^2c_2}
\\]

Supporting evidence:
\\begin{itemize}
\\item $G(c_1,0,d)$, $G(0,c_2,d)$ agree with experimental computations.
\\item All mixed terms checked for $d=3, r\\leq 8$ and $d=11, r\\leq 8$.
\\end{itemize}
\\end{conj}

\\begin{thebibliography}{99999999}

\\bibitem[\\textbf{At-Ma}]{AM}M.~Atiyah, I.~Macdonald: \\emph{Introduction to commutative algebra.} Addison-Wesley Publishing Co., Reading, Mass.-London-Don Mills, Ont. 1969.

\\bibitem[\\textbf{Be-Ma96}]{BM} K.~Behrend, Y.~I.~Manin: Stacks of stable maps and Gromow-Witten invariants; Duke Math. J. \\textbf{85} (1996), no.1, pp.~1-60.

%\\bibitem[\\textbf{Ed-Fu1}]{EF} D.~Edidin, D.~Fulghesu: The integral Chow ring of the stack of at most 1-nodal rational curves. Comm. in Alg. \\textbf{36} (2008), no. 2, pp. 581-594.

\\bibitem[\\textbf{Ed-Fu09}]{EFh} D.~Edidin, D.~Fulghesu: The integral Chow ring of the stack of hyperelliptic curves of even genus; Math. Res. Lett. \\textbf{16} (2009), no.1, pp.~27-40.

\\bibitem[\\textbf{Ed-Gr98-1}]{EG} D.~Edidin, W.~Graham: Equivariant intersection theory; Inv. Math. \\textbf{131} (1998), pp.~595-634.

\\bibitem[\\textbf{Ed-Gr98-2}]{EGL} D.~Edidin, W.~Graham: Localization in equivariant intersection theory and the Bott residue formula. Amer. J. Math. \\textbf{120} no. 3 (1998), pp.~619-636.

\\bibitem[\\textbf{Ei-Ha16}]{3264} D.~Eisenbud, J.~Harris: \\emph{3264 \\& All That Intersection Theory in Algebraic Geometry} pdf available at: https://scholar.harvard.edu/files/joeharris/files/000-final-3264.pdf

%\\bibitem[\\textbf{Fab}]{Fab} Chow rings of moduli spaces of curves II: Some results on the Chow ring of $\\overline{\\mathcal M}_{4}$; Ann. of Math. \\textbf{132}, (1990), 421--449

\\bibitem[\\textbf{DL-Fu-Vi20}]{DLFV} A.~Di~Lorenzo, D.~Fulghesu, A.~Vistoli: The integral Chow ring of the stack of smooth non-hyperelliptic curves of genus three. Preprint: arXiv:2004.00052.

\\bibitem[\\textbf{Fu-Vi18}]{Fu-Vi} D.~Fulghesu, A.~Vistoli: The {C}how ring of the stack of smooth plane cubics; Michigan Math. J. \\textbf{67} (2018), 3--29.

\\bibitem[\\textbf{Fu-Vi11}]{FViv} D.~Fulghesu, F.~Viviani: The Chow ring of the stack of cyclic covers of the projective line. Ann. Inst. Fourier (Grenoble) \\textbf{61} no. 6 (2011), pp.~2249-2275.

\\bibitem[\\textbf{Fu-Pa97}]{FP} W.~Fulton, R.~Pandharipande: Notes on stable maps and quantum cohomology. In Algebraic geometry, Santa Cruz 1995, \\textbf{62} Part 2 of Proc. Sympos. Pure Math., pp. 45-96. Amer. Math. Soc., 1997.

\\bibitem[\\textbf{Ful}]{Ful} W.~Fulton: \\emph{Intersection theory.} Second Edition. Springer-Verlag, Berlin, 1998.

%\\bibitem[\\textbf{Gil}]{Gil} H. Gillet, Intersection theory on algebraic stacks and $Q$-varieties, J. Pure Appl. Alg., \\textbf{34} (1984), 193--240.

\\bibitem[\\textbf{Hei05}]{Hei05} J.~Heinloth: Notes on differentiable stacks. In Mathematisches Institut, Seminars, (Y. Tschinkel, ed.), p.1-32 Universit\\"at G\\"ottingen, 2004-05.

Mirror-symmetry-book
\\bibitem[\\textbf{HKKPTVVZ03}]{Mirror-symmetry-book} K.~Hori, S.~Kats, A.~Klemm, R.~Pandharipande, R.~Thomas, C.~Vafa, R.~Vakil, E.~Zaslow: \\emph{Mirror Symmetry.} Clay Mathematics Monographs, AMS Clay Mathematical Institute 2003.

%\\bibitem[\\textbf{Iza}]{Iza} E. Izadi, The Chow ring of the moduli space of curves of genus 5; in The Moduli Space of Curves, R. Dijkgraaf, C. Faber, and G. van der Geer (eds), Progress in Math.
%129, Birkh\\"auser, Boston, 1995.

\\bibitem[\\textbf{MR-Vi06}]{MV} L.A.~Molina Rojas, A.~Vistoli: On the Chow rings of classifying spaces for classical groups. In Rendicont del Seminarion Matematico della Universit\\`a di Padova \\text{116} (2006), pp.~271-298.

%\\bibitem[\\textbf{Mum}]{Mum} D.~Mumford, Towards An Enumerative Geometry of the Moduli Space of Curves, Progress in Math., Vol. II (1983), pp. 271--328.

%\\bibitem[\\textbf{Ho-Ea}]{HE} M.~Hochster, J.~Eagon: Cohen-Macaulay rings, invariant theory, and the generic perfection of determinantal loci; Amer. J. Math. \\textbf{93} (1971), pp.~1020-1058.

%\\bibitem[\\textbf{Pan}]{Pan} R.~Pandharipande: Equivariant Chow rings of $O(k), SO(2k+1)$ and $SO(4)$; J. Reine Angew. Math. \\textbf{496} (1998), pp.~131-148.

%\\bibitem[\\textbf{PV}]{PV} N.~Penev and R.~Vakil: The Chow ring of the moduli space of curves of genus six; Algebr. Geom. 2 (2015) \\textbf{1}, 123--136. 

%\\bibitem[\\textbf{Vis89}]{Vis89} A.~Vistoli,  Intersection theory on algebraic stacks and on their moduli spaces; Invent. Math. \\textbf{97} (1989), 613--670.

\\bibitem[\\textbf{Vis98}]{Vis98} A.~Vistoli, {\\em The Chow ring of {${\\mathcal M}\\sb 2$}}, Invent. Math. \\textbf{131} (1998), no.~3, 635--644.

\\end{thebibliography}


%\\end{document}
"""
