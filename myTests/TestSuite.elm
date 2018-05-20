module TestSuite exposing (..)

import Parser exposing (run)
import MeenyLatex.ParserHelpers as PH
import MeenyLatex.Parser exposing (..)


test1 =
    run words "This is a test."


test2 =
    run (inlineMath PH.spaces) "$a^2 + b^2 = c^2$"


test3 =
    run latexList "Pythagoras said that $a^2 + b^2 = c^2$.  Yay!"


test4 =
    run latexList "\\[a^2 = b^4\\]"


test5 =
    run latexList "$$a^2 = b^4$$"


test6 =
    run latexList "This is a test:\n\\[\na^2 = b^5\n\\]\n ho ho ho!"


test7 =
    run latexList "This is a test:\n$$\na^2 = b^5\n$$\n ho ho ho!"


test8 =
    run latexList "\\begin{th}$a^2 = b^3$\\end{th}"


test9 =
    run latexList "\\begin{A}\\begin{B}$a^2 = b^3$\\end{B}\\end{A}"


test10 =
    run latexList "\\begin{A}$y^h = 4$\\begin{B}This is a formula: $a^2 = b^3$\\end{B}\\end{A}"


test11 =
    run latexList "\\begin{th}\n\nIt's gonna be OK!\n\n\\end{th}"


test12 =
    run latexList "% this is a comment\n"


basicSuite =
    [ test1
    , test2
    , test3
    , test4
    , test5
    , test6
    , test7
    , test8
    , test9
    , test10
    , test11
    , test12
    ]


macroSuite =
    [ macro1, macro2, macro3, macro4, macro5, macro6 ]


macro1 =
    run (macro PH.ws) "\\foo"


macro2 =
    run (macro PH.ws) "\\foo{}"


macro3 =
    run (macro PH.ws) "\\foo{bar}"


macro4 =
    run (macro PH.ws) "\\foo[1]{2}"


macro5 =
    run (macro PH.ws) "\\foo{bar baz}"


macro6 =
    run (macro PH.ws) "\\foo{bar baz $a^2 = b^3$ yada}"
