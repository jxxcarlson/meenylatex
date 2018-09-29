module ParserTest exposing (suite)

-- http://package.elm-lang.org/packages/elm-community/elm-test/latest

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import MiniLatex.Parser exposing (..)
import Parser exposing (Problem(..), run)
import Test exposing (..)


doTest comment inputExpression outputExpression =
    test comment <|
        \_ ->
            Expect.equal inputExpression outputExpression


suite : Test
suite =
    describe "MiniLatex Parser"
        [ doTest
            "(1) Comment"
            (run latexExpression "% This is a comment\n")
            (Ok (Comment "% This is a comment\n"))
        , doTest
            "(2) InlineMath"
            (run latexExpression "$a^2 = 7$")
            (Ok (InlineMath "a^2 = 7"))
        , doTest
            "(3) DisplayMath"
            (run latexExpression "$$b^2 = 3$$")
            (Ok (DisplayMath "b^2 = 3"))
        , doTest
            "(4) DisplayMath (Brackets)"
            (run latexExpression "\\[b^2 = 3\\]")
            (Ok (DisplayMath "b^2 = 3"))
        , doTest
            "(5) latexList words and macros"
            (run latexList "a b \\foo \\bar{1} \\baz{1}{2}")
            (Ok (LatexList [ LXString "a  b ", Macro "foo" [] [], Macro "bar" [] [ LatexList [ LXString "1" ] ], Macro "baz" [] [ LatexList [ LXString "1" ], LatexList [ LXString "2" ] ] ]))
        , doTest
            "(6) Environment"
            (run latexExpression "\\begin{theorem}\nInfinity is \\emph{very} large: $\\infinity^2 = \\infinity$. \\end{theorem}")
            (Ok (Environment "theorem" [] (LatexList [ LXString "Infinity  is ", Macro "emph" [] [ LatexList [ LXString "very" ] ], LXString "large: ", InlineMath "\\infinity^2 = \\infinity", LXString ". " ])))
        , doTest
            "(7) Nested Environment"
            (run latexExpression "\\begin{th}  \\begin{a}$$hahah$$\\begin{x}yy\\end{x}\\end{a}\\begin{a} a{1}{2} b c yoko{1} $foo$ yada $$bar$$ a b c \\begin{u}yy\\end{u} \\end{a}\n\\end{th}")
            (Ok (Environment "th" [] (LatexList [ Environment "a" [] (LatexList [ DisplayMath "hahah", Environment "x" [] (LatexList [ LXString "yy" ]) ]), Environment "a" [] (LatexList [ LXString "a{1}{2}  b  c  yoko{1} ", InlineMath "foo", LXString "yada ", DisplayMath "bar", LXString "a  b  c ", Environment "u" [] (LatexList [ LXString "yy" ]) ]) ])))
        , doTest
            "(8) Itemized List"
            (run latexList "\\begin{itemize} \\item aaa.\n \\item bbb.\n \\itemitem xx\n\\end{itemize}")
            (Ok (LatexList [ Environment "itemize" [] (LatexList [ Item 1 (LatexList [ LXString "aaa.\n " ]), Item 1 (LatexList [ LXString "bbb.\n ", Macro "itemitem" [] [], LXString "xx\n" ]) ]) ]))
        , doTest
            "(9) tablerow"
            (run tableRow "1 & 2 & 3 \\\\\n")
            (Ok (LatexList [ LXString "1", LXString "2", LXString "3" ]))
        , doTest
            "(10) tablerow"
            (run tableRow "Hydrogen & H & 1 & 1.008 \\\\\n")
            (Ok (LatexList [ LXString "Hydrogen", LXString "H", LXString "1", LXString "1.008" ]))
        , doTest
            "(11) table"
            (run latexExpression "\\begin{tabular}\n1 & 2 \\\\\n 3 & 4 \\\\\n\\end{tabular}")
            (Ok (Environment "tabular" [] (LatexList [ LatexList [ LXString "1", LXString "2" ], LatexList [ LXString "3", LXString "4" ] ])))
        , doTest
            "(12) table"
            (run latexExpression "\\begin{tabular}{l l l l}\nHydrogen & H & 1 & 1.008 \\\\\nHelium & He & 2 & 4.003 \\\\\nLithium & Li & 3 &  6.94 \\\\\nBeryllium & Be & 4 & 9.012 \\\\\n\\end{tabular}")
            (Ok (Environment "tabular" [ LatexList [ LXString "l  l  l  l" ] ] (LatexList [ LatexList [ LXString "Hydrogen", LXString "H", LXString "1", LXString "1.008" ], LatexList [ LXString "Helium", LXString "He", LXString "2", LXString "4.003" ], LatexList [ LXString "Lithium", LXString "Li", LXString "3", LXString "6.94" ], LatexList [ LXString "Beryllium", LXString "Be", LXString "4", LXString "9.012" ] ])))
        , doTest
            "(13) table"
            (run latexExpression "\\begin{tabular}\nHydrogen & H & 1 & 1.008 \\\\\nHelium & He & 2 & 4.003 \\\\\nLithium & Li & 3 &  6.94 \\\\\nBeryllium & Be & 4 & 9.012 \\\\\n\\end{tabular}")
            (Ok (Environment "tabular" [] (LatexList [ LatexList [ LXString "Hydrogen", LXString "H", LXString "1", LXString "1.008" ], LatexList [ LXString "Helium", LXString "He", LXString "2", LXString "4.003" ], LatexList [ LXString "Lithium", LXString "Li", LXString "3", LXString "6.94" ], LatexList [ LXString "Beryllium", LXString "Be", LXString "4", LXString "9.012" ] ])))
        , doTest
            "(14) table with inline math"
            (run latexExpression "\\begin{tabular}\n$ \\int x^n dx $ & $ \\frac{x^{n+1}}{n+1} $ \\\\\n$ \\int e^x dx $ & $ e^x $ \\\\\n\\end{tabular}")
            (Ok (Environment "tabular" [] (LatexList [ LatexList [ InlineMath " \\int x^n dx ", InlineMath " \\frac{x^{n+1}}{n+1} " ], LatexList [ InlineMath " \\int e^x dx ", InlineMath " e^x " ] ])))
        , doTest
            "(15) table with display math"
            (run latexExpression "\\begin{tabular}\n$$ \\int x^n dx $$ & $$ \\frac{x^{n+1}}{n+1} $$ \\\\\n$$ \\int e^x dx $$ & $$ e^x $$ \\\\\n\\end{tabular}")
            (Ok (Environment "tabular" [] (LatexList [ LatexList [ DisplayMath " \\int x^n dx ", DisplayMath " \\frac{x^{n+1}}{n+1} " ], LatexList [ DisplayMath " \\int e^x dx ", DisplayMath " e^x " ] ])))
        , doTest
            "(16) table with display math: brackets"
            (run latexExpression "\\begin{tabular}\n\\[ \\int x^n dx \\] & $$ \\frac{x^{n+1}}{n+1} $$ \\\\\n$$ \\int e^x dx $$ & $$ e^x $$ \\\\\n\\end{tabular}")
            (Ok (Environment "tabular" [] (LatexList [ LatexList [ DisplayMath " \\int x^n dx ", DisplayMath " \\frac{x^{n+1}}{n+1} " ], LatexList [ DisplayMath " \\int e^x dx ", DisplayMath " e^x " ] ])))
        , doTest
            "(17) label"
            (run latexExpression "\\begin{equation}\n\\label{uncertaintyPrinciple}\n\\left[ \\hat p, x\\right] = -i \\hbar\n\\end{equation}")
            (Ok (Environment "equation" [] (LXString "\n\\label{uncertaintyPrinciple}\n\\left[ \\hat p, x\\right] = -i \\hbar\n")))
        , doTest
            "(18) punctuation"
            (run latexList "test \\code{foo}.")
            (Ok (LatexList [ LXString "test ", Macro "code" [] [ LatexList [ LXString "foo" ] ], LXString "." ]))
        , doTest "(19) verse"
            (run latexList "\\begin{verse}\nTest\n\nTest\n\\end{verse}")
            (Ok (LatexList [ Environment "verse" [] (LXString "\nTest\n\nTest\n") ]))
        , doTest
            "(20) verbatim"
            (run latexList "\\begin{verbatim}\nTest\n\nTest\n\\end{verbatim}")
            (Ok (LatexList [ Environment "verbatim" [] (LXString "\nTest\n\nTest\n") ]))
        ]
