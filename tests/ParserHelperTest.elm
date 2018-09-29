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
            "parseToSymbol"
            (run (parseUntil "!") "one two! three")
            (Ok "one two")
        , doTest
            "parseBetweenSymbols (1)"
            (run (parseBetweenSymbols "[" "]") "[one two] three")
            (Ok "one two")
        , doTest
            "parseBetweenSymbols (2)"
            (run (parseBetweenSymbols "[[[" "]]]") "[[[one [and] two]]] three")
            (Ok "one [and] two")
        ]
