module Internal.KeyValueUtilities exposing(..)

-- exposing (getKeyValueList, getValue)

import Char
import Parser.Advanced exposing (..)
-- import Internal.Parser exposing (word, itemList)

type alias KVParser a = Parser.Advanced.Parser Context Problem a


type Context
    = Definition String

type Problem
    = ExpectingColon
    | ExpectingInWord
    | ExpectingComma


-- type alias KeyValuePair =
--     { key : String
--     , value : String
--     }
--


type alias KeyValuePair =
    ( String, String )


keyValuePair :  KVParser KeyValuePair
keyValuePair =
    succeed Tuple.pair
        |. spaces
        |= word ExpectingColon (\c -> (c /= ':'))
        |. spaces
        |. symbol (Token ":" ExpectingColon)
        |. spaces
        |= word ExpectingComma (\c -> (c /= ','))
        |. oneOf [symbol (Token "," ExpectingComma), spaces]
        |> map (\( a, b ) -> ( String.trim a, String.trim b ))


keyValuePairs : KVParser (List KeyValuePair)
keyValuePairs =
    -- inContext "keyValuePairs" <|
    succeed identity
        |= itemList keyValuePair


getKeyValueList str =
    Parser.Advanced.run keyValuePairs str |> Result.withDefault []



-- getValue : List KeyValuePair -> String -> String


getValue key kvpList =
    kvpList
        |> List.filter (\x -> (Tuple.first x) == key)
        |> List.map (\x -> Tuple.second x)
        |> List.head
        |> Maybe.withDefault ""


--
-- HELPERS
--

{-| Use `inWord` to parse a word.

   import Parser

   inWord : Char -> Bool
   inWord c = not (c == ' ')

   KVParser.run word "this is a test"
   --> Ok "this"
-}
word : Problem -> (Char -> Bool) -> KVParser String
word problem inWord =
    succeed String.slice
        |. ws
        |= getOffset
        |. chompIf inWord problem
        |. chompWhile inWord
        |. ws
        |= getOffset
        |= getSource

ws : KVParser ()
ws =
    chompWhile (\c -> c == ' ' || c == '\n')
    
itemList : KVParser a -> KVParser (List a)
itemList itemParser =
    itemList_ [] itemParser


itemList_ : List a -> KVParser a -> KVParser (List a)
itemList_ initialList itemParser =
   loop initialList (itemListHelper itemParser)


itemListHelper : KVParser a -> List a -> KVParser (Step (List a) (List a))
itemListHelper itemParser revItems =
    oneOf
        [ succeed (\item_ -> Loop (item_ :: revItems))
            |= itemParser
        , succeed ()
            |> map (\_ -> Done (List.reverse revItems))
        ]
