module MiniLatexParagraphTest exposing (suite)


import Expect exposing (Expectation)
import Internal.Paragraph exposing (logicalParagraphify)
import Test exposing (..)


doTest comment inputExpression outputExpression =
    test comment <|
        \_ ->
            Expect.equal inputExpression outputExpression


suite : Test
suite =
    describe "paragraphify"
        [ doTest
            "normal paragraphs"
            (logicalParagraphify "abc\n\ndef")
            [ "abc\n\n", "def\n\n" ]
        , doTest
            "normal paragraphs, length test"
            (logicalParagraphify "abc\n\ndef" |> List.length)
            2
        , doTest
            "nested paragraphs"
            (logicalParagraphify "abc\n\n\\begin{a}\nxyz\n\\begin{a}\nHHH\n\\end{a}\n\n\\end{a}\n\nhohoho")
            [ "abc\n\n", "\\begin{a}\nxyz\n\\begin{a}\nHHH\n\\end{a}\n\n\\end{a}\n\n", "hohoho\n\n" ]
        , doTest
            "nested paragraphs II"
            (logicalParagraphify "\\begin{enumerate}\n\\item One\n\\item Two\n\\begin{itemize}\n\\item Foo\n\\end{itemize}\n\\end{enumerate}\n\n")
            [ "\\begin{enumerate}\n\\item One\n\\item Two\n\\begin{itemize}\n\\item Foo\n\\end{itemize}\n\\end{enumerate}\n\n" ]
        ]
