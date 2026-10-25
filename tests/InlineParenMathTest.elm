module InlineParenMathTest exposing (suite)

{-| `\(x^2\)` must parse to the same expression as `$x^2$` (inline math).
-}

import Expect
import Internal.Parser as P
import Test exposing (..)


suite : Test
suite =
    describe "inline math: \\(...\\) parses like $...$"
        [ test "\\(x^2\\) parses identically to $x^2$" <|
            \_ ->
                Expect.equal (P.parse "$x^2$") (P.parse "\\(x^2\\)")
        , test "\\(x^2\\) yields InlineMath \"x^2\"" <|
            \_ ->
                Expect.equal [ P.InlineMath "x^2" ] (P.parse "\\(x^2\\)")
        , test "inline paren math inside running text matches dollar form" <|
            \_ ->
                Expect.equal
                    (P.parse "Pythagoras: $a^2 + b^2 = c^2$ ok")
                    (P.parse "Pythagoras: \\(a^2 + b^2 = c^2\\) ok")
        , test "inside a macro argument matches dollar form" <|
            \_ ->
                Expect.equal
                    (P.parse "\\foo{$x^2$}")
                    (P.parse "\\foo{\\(x^2\\)}")
        , test "inside an optional argument matches dollar form" <|
            \_ ->
                Expect.equal
                    (P.parse "\\foo[$x^2$]{bar}")
                    (P.parse "\\foo[\\(x^2\\)]{bar}")
        ]
