module PassThroughTextTest exposing (suite)

{-| Regression tests for the text pass-through environments (`verbatim`,
`listing`, `verse`). Their body must reach the renderer as written: only blank
lines at the very start and end are dropped. Previously `passThroughEnv` trimmed
the body, deleted every empty line, and read the first line as optional
arguments, so code lost blank lines and first-line indentation, stanzas ran
together, and a first line such as `[1, 2, 3]` vanished.
-}

import Expect
import Internal.Parser exposing (..)
import Parser.Advanced exposing (run)
import Test exposing (..)


parsesTo : String -> String -> LatexExpression -> Test
parsesTo label source expected =
    test label <|
        \_ ->
            run latexExpression source
                |> Expect.equal (Ok expected)


suite : Test
suite =
    describe "text pass-through environments keep their body"
        [ parsesTo "verbatim keeps an interior blank line"
            "\\begin{verbatim}\ndef f():\n    x = 1\n\n    return x\n\\end{verbatim}"
            (Environment "verbatim" [] (LXString "def f():\n    x = 1\n\n    return x"))
        , parsesTo "verbatim keeps first-line indentation"
            "\\begin{verbatim}\n    indented\nflush\n\\end{verbatim}"
            (Environment "verbatim" [] (LXString "    indented\nflush"))
        , parsesTo "verbatim treats a first line starting with [ as body"
            "\\begin{verbatim}\n[1, 2, 3]\nfoo\n\\end{verbatim}"
            (Environment "verbatim" [] (LXString "[1, 2, 3]\nfoo"))
        , parsesTo "listing keeps an interior blank line"
            "\\begin{listing}\na\n\nb\n\\end{listing}"
            (Environment "listing" [] (LXString "a\n\nb"))
        , parsesTo "verse keeps the break between stanzas"
            "\\begin{verse}\nRoses are red\n\nViolets are blue\n\\end{verse}"
            (Environment "verse" [] (LXString "Roses are red\n\nViolets are blue"))
        , parsesTo "colored still reads its language option"
            "\\begin{colored}[python]\nx = 1\n\\end{colored}"
            (Environment "colored" [ LatexList [ LXString "python" ] ] (LXString "x = 1"))
        ]
