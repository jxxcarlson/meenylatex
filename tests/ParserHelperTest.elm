module ParserHelperTest exposing (suite)

-- http://package.elm-lang.org/packages/elm-community/elm-test/latest

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import MiniLatex.ParserHelpers exposing (..)
import Parser exposing (run)
import Test exposing (..)


doTest comment inputExpression outputExpression =
    test comment <|
        \_ ->
            Expect.equal inputExpression outputExpression


suite : Test
suite =
    describe "MiniLatex ParserHelpers"
        [ doTest
            "parseUntil"
            (run (parseUntil "!") "one two! three")
            (Ok "one two")
        , doTest
            "parseTo"
            (run (parseUntil "!") "one two! three")
            (Ok "one two")
        , doTest
            "parseFromTo (1)"
            (run (parseFromTo "[" "]") "[one two] three")
            (Ok "one two")
        , doTest
            "parseFromTo (2)"
            (run (parseFromTo "[[[" "]]]") "[[[one [and] two]]] three")
            (Ok "one [and] two")
        ]
