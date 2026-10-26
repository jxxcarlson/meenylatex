module MiniLatexExportTest exposing (suite)

{-| Tests for `MiniLatex.API.toLaTeX` / `toLaTeXBody`: MiniLaTeX source mapped
to standard LaTeX that xelatex can compile.
-}

import Expect
import MiniLatex.API as API
import Test exposing (..)


doc : String
doc =
    String.join "\n\n"
        [ "\\section{Introduction}"
        , "Inline math $a^2 + b^2 = c^2$ in a sentence."
        , "\\begin{equation}\n\\int_0^1 x\\, dx = \\frac{1}{2}\n\\end{equation}"
        ]


contains : String -> String -> Expect.Expectation
contains needle haystack =
    if String.contains needle haystack then
        Expect.pass

    else
        Expect.fail ("Expected the output to contain\n\n    " ++ needle ++ "\n\nbut it was\n\n" ++ haystack)


suite : Test
suite =
    describe "MiniLatex.API export"
        [ test "toLaTeX is a complete document" <|
            \_ ->
                API.toLaTeX doc
                    |> Expect.all
                        [ String.trim >> String.startsWith "\\documentclass" >> Expect.equal True
                        , contains "\\begin{document}"
                        , String.trim >> String.endsWith "\\end{document}" >> Expect.equal True
                        ]
        , test "toLaTeXBody has no preamble" <|
            \_ ->
                API.toLaTeXBody doc
                    |> Expect.all
                        [ String.contains "\\documentclass" >> Expect.equal False
                        , String.contains "\\begin{document}" >> Expect.equal False
                        ]
        , test "toLaTeX is the preamble around toLaTeXBody" <|
            \_ ->
                API.toLaTeX doc |> contains (API.toLaTeXBody doc)
        , test "sections are kept" <|
            \_ ->
                API.toLaTeXBody doc |> contains "\\section{Introduction}"
        , test "inline math is kept" <|
            \_ ->
                API.toLaTeXBody doc |> contains "$a^2 + b^2 = c^2$"
        , test "math environments are kept" <|
            \_ ->
                API.toLaTeXBody doc
                    |> Expect.all
                        [ contains "\\begin{equation}"
                        , contains "\\frac{1}{2}"
                        , contains "\\end{equation}"
                        ]
        , test "a \\newcommand defined in the document is kept, so its uses compile" <|
            \_ ->
                API.toLaTeXBody "\\newcommand{\\hello}[1]{Hello \\strong{#1}!}\n\n\\hello{World}"
                    |> Expect.all
                        [ contains "\\newcommand{\\hello}[1]{Hello \\strong{#1}!}"
                        , contains "\\hello{World}"
                        ]
        , test "images lists each image's url and the file name the export refers to" <|
            \_ ->
                let
                    source =
                        "Text.\n\n\\image{https://example.com/pics/beats.png}{Beats}{width: 300}\n\nMore."
                in
                Expect.all
                    [ \_ ->
                        API.images source
                            |> Expect.equal [ { url = "https://example.com/pics/beats.png", filename = "beats.png" } ]
                    , \_ -> API.toLaTeXBody source |> contains "image/beats.png"
                    ]
                    ()
        , test "a document without images has none" <|
            \_ ->
                API.images doc |> Expect.equal []
        ]
