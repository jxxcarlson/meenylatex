module MiniLatexParserHelperTest exposing (suite)

{-| Ported from meenylatex 14.1.1 `tests/ParserHelperTest.elm`.

Upstream's item-list tests used `Internal.TestParser`, which was never updated
when the parser moved to `Parser.Advanced`, no longer compiled, and has been removed. Since
`Internal.ParserHelpers` does not expose its `Problem` type, the item-list tests
here use `parseToSymbol ";"` as the item parser instead of an integer parser.
The `intBlock` / `bracketIntBlock` tests are dropped: they only exercised
`elm/parser`'s `sequence`, not MiniLaTeX code.

-}

import Expect
import Internal.ParserHelpers exposing (..)
import Parser.Advanced exposing (run)
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
            (run (parseToSymbol "!") "one two! three")
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
            (run (itemList (parseToSymbol ";")) "a;b;c;")
            (Ok [ "a", "b", "c" ])
        , doTest
            "itemList (2)"
            (run (itemList (parseToSymbol ";")) "")
            (Ok [])
        , doTest
            "nonEmptyItemList (1)"
            (run (nonEmptyItemList (parseToSymbol ";")) "a;b;c;")
            (Ok [ "a", "b", "c" ])
        , test "nonEmptyItemList (2)" <|
            \_ ->
                run (nonEmptyItemList (parseToSymbol ";")) ""
                    |> Expect.err
        ]
