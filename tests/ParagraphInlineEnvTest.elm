module ParagraphInlineEnvTest exposing (suite)

{-| Regression test for the logicalParagraphify fix: a self-contained
environment written entirely on one line (e.g. a matrix
`\begin{pmatrix} a & b \\ c & d \end{pmatrix}`) must NOT be treated as
opening a block. Before the fix, such a line pushed onto the block stack
without ever popping, so the "paragraph" swallowed the rest of the document.
-}

import Expect
import Internal.Paragraph as Paragraph
import Test exposing (..)


{-| An `equation` block containing one-line matrices, followed by more content.
-}
doc : String
doc =
    "\\begin{equation}\n\\begin{pmatrix} a & b \\\\ c & d \\end{pmatrix}\n\\begin{bmatrix} 1 & 0 \\\\ 0 & 1 \\end{bmatrix}\n\\end{equation}\n\n\\section{After}\n\nFollowing text.\n"


suite : Test
suite =
    describe "logicalParagraphify: self-contained one-line environments"
        [ test "an inline begin/end environment does not swallow following content" <|
            \_ ->
                Paragraph.logicalParagraphify doc
                    |> List.any (\p -> String.contains "equation" p && String.contains "Following text" p)
                    |> Expect.equal False
        , test "the equation block is split from the following section" <|
            \_ ->
                Paragraph.logicalParagraphify doc
                    |> List.length
                    |> Expect.atLeast 2
        ]
