module ParserHelperTest exposing (suite)

-- http://package.elm-lang.org/packages/elm-community/elm-test/latest

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Internal.ParserHelpers exposing (..)
import Internal.TestParser exposing (..)
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
        , doTest
            "itemList (1)"
            (run (itemList intItem) "1 2 3")
            (Ok [ 1, 2, 3 ])
        , doTest
            "itemList (2)"
            (run (itemList intItem) "")
            (Ok [])
        , doTest
            "nonEmptyItemList (1)"
            (run (nonEmptyItemList intItem) "1 2 3")
            (Ok [ 1, 2, 3 ])
        , doTest
            "nonEmptyItemList (2)"
            (run (nonEmptyItemList intItem) "")
            (Err [ { col = 1, problem = Parser.ExpectingInt, row = 1 } ])
        , doTest
            "intBlock"
            (run intBlock "1, 2, 3")
            (Ok [ 1, 2, 3 ])
        , doTest
            "bracketIntBlock"
            (run bracketIntBlock "[1, 2, 3]")
            (Ok [ 1, 2, 3 ])
        ]
