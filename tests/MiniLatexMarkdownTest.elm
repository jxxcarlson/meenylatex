module MiniLatexMarkdownTest exposing (suite)

{-| Tests for `MiniLatex.API.toMarkdown`: MiniLaTeX source converted to Markdown.
-}

import Expect
import MiniLatex.API as API
import Test exposing (..)


doc : String
doc =
    "\\section{Introduction}\n\nInline math $a^2 + b^2 = c^2$ in a sentence."


suite : Test
suite =
    describe "MiniLatex.API.toMarkdown"
        [ test "a section becomes a Markdown heading" <|
            \_ ->
                API.toMarkdown doc
                    |> String.lines
                    |> List.any (\line -> String.startsWith "#" line && String.contains "Introduction" line)
                    |> Expect.equal True
        , test "no LaTeX section command is left" <|
            \_ ->
                API.toMarkdown doc
                    |> String.contains "\\section"
                    |> Expect.equal False
        , test "inline math is kept" <|
            \_ ->
                API.toMarkdown doc
                    |> String.contains "$a^2 + b^2 = c^2$"
                    |> Expect.equal True
        , test "plain text is kept (word for word: the converter may double spaces, which Markdown ignores)" <|
            \_ ->
                API.toMarkdown "Just some text."
                    |> String.words
                    |> Expect.equal [ "Just", "some", "text." ]
        ]
