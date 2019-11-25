module Internal.TestParser exposing (bracketIntBlock, intBlock, intItem)

import Internal.ParserHelpers exposing (..)
import Parser exposing (..)


intItem : Parser Int
intItem =
    succeed identity
        |= Parser.int
        |. ws


intBlock : Parser (List Int)
intBlock =
    Parser.sequence
        { start = ""
        , separator = ","
        , end = ""
        , spaces = ws
        , item = Parser.int
        , trailing = Forbidden -- no trailing commma
        }


bracketIntBlock : Parser (List Int)
bracketIntBlock =
    Parser.sequence
        { start = "["
        , separator = ","
        , end = "]"
        , spaces = ws
        , item = Parser.int
        , trailing = Forbidden -- no trailing commma
        }
