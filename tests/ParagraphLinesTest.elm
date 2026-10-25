module ParagraphLinesTest exposing (suite)

import Expect
import Internal.Paragraph as P
import Test exposing (..)


ranges : String -> List ( Int, Int )
ranges s =
    P.logicalParagraphifyWithLines s
        |> List.map (\p -> ( p.startLine, p.lineCount ))


suite : Test
suite =
    describe "logicalParagraphifyWithLines"
        [ test "two one-line paragraphs separated by a blank line" <|
            \_ -> Expect.equal [ ( 0, 1 ), ( 2, 1 ) ] (ranges "a\n\nb")
        , test "leading blank lines are not attributed to the first paragraph" <|
            \_ -> Expect.equal [ ( 2, 1 ) ] (ranges "\n\na")
        , test "a two-line paragraph (no internal blank)" <|
            \_ -> Expect.equal [ ( 0, 2 ) ] (ranges "a\nb")
        , test "an environment block spanning an internal blank line keeps one range" <|
            \_ ->
                Expect.equal [ ( 0, 5 ) ]
                    (ranges "\\begin{itemize}\n\\item x\n\n\\item y\n\\end{itemize}")
        , test "NESTED environments group as one paragraph" <|
            \_ ->
                Expect.equal [ ( 0, 5 ) ]
                    (ranges "\\begin{theorem}\n\\begin{align}\na &= b\n\\end{align}\n\\end{theorem}")
        , test "paragraph after a nested block gets its own correct range" <|
            \_ ->
                Expect.equal [ ( 0, 4 ), ( 5, 1 ) ]
                    (ranges "\\begin{a}\n\\begin{b}\n\\end{b}\n\\end{a}\n\nnext")
        , test "text returned matches logicalParagraphify (same grouping/trim)" <|
            \_ ->
                Expect.equal
                    (P.logicalParagraphify "a\n\nb")
                    (P.logicalParagraphifyWithLines "a\n\nb" |> List.map .text)
        ]
