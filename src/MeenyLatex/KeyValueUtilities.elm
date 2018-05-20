module MeenyLatex.KeyValueUtilities exposing (getKeyValueList, getValue)

import Char
import Parser exposing (..)
import MeenyLatex.ParserHelpers exposing (itemList)
import MeenyLatex.Parser exposing (word)


-- type alias KeyValuePair =
--     { key : String
--     , value : String
--     }
--


type alias KeyValuePair =
    ( String, String )


keyValuePair : Parser KeyValuePair
keyValuePair =
    succeed Tuple.pair
        |. spaces
        |= word (\c -> (c /= ':'))
        |. spaces
        |. symbol ":"
        |. spaces
        |= word (\c -> (c /= ','))
        |> map (\( a, b ) -> ( String.trim a, String.trim b ))


keyValuePairs : Parser (List KeyValuePair)
keyValuePairs =
    -- inContext "keyValuePairs" <|
    succeed identity
        |= itemList keyValuePair


getKeyValueList str =
    Parser.run keyValuePairs str |> Result.withDefault []



-- getValue : List KeyValuePair -> String -> String


getValue key kvpList =
    kvpList
        |> List.filter (\x -> (Tuple.first x) == key)
        |> List.map (\x -> Tuple.second x)
        |> List.head
        |> Maybe.withDefault ""
