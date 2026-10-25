module TabularFinalRowTest exposing (suite)

{-| Regression test: the trailing `\\` on the final row of a `tabular` is
optional (standard LaTeX does not require it). A plain-text final cell's word
parser chomps the row-ending newline via its trailing whitespace, so the row
terminator now also recognizes a following `\end{...}` as a valid row end.
-}

import Expect
import Internal.Parser as P
import Test exposing (..)


rowCount : String -> Maybe Int
rowCount s =
    case P.parse s of
        [ P.Environment "tabular" _ (P.LatexList rows) ] ->
            Just (List.length rows)

        _ ->
            Nothing


suite : Test
suite =
    describe "tabular: trailing backslash on the final row is optional"
        [ test "final row WITHOUT trailing backslash parses as 2 rows" <|
            \_ ->
                rowCount "\\begin{tabular}{ll}\nA & B \\\\\nC & D\n\\end{tabular}"
                    |> Expect.equal (Just 2)
        , test "final row WITH trailing backslash still parses as 2 rows" <|
            \_ ->
                rowCount "\\begin{tabular}{ll}\nA & B \\\\\nC & D \\\\\n\\end{tabular}"
                    |> Expect.equal (Just 2)
        , test "single row without trailing backslash parses as 1 row" <|
            \_ ->
                rowCount "\\begin{tabular}{ll}\nA & B\n\\end{tabular}"
                    |> Expect.equal (Just 1)
        , test "final row with inline math and no trailing backslash parses" <|
            \_ ->
                rowCount "\\begin{tabular}{ll}\nPi & $\\pi$ \\\\\nE & $e$\n\\end{tabular}"
                    |> Expect.equal (Just 2)
        ]
