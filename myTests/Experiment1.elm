module Experiment1 exposing (..)

import Parser exposing (..)


{-

   > import Parser exposing(..)
   > import Experiment1 exposing(..)
   > run (itemList mySymbol) "ABBA"
   Ok ["A","B","B","A"]

-}


symbolA : Parser String
symbolA =
    getChompedString <|
        symbol "A"


symbolB : Parser String
symbolB =
    getChompedString <|
        symbol "B"


mySymbol =
    oneOf [ symbolA, symbolB ]


itemList : Parser a -> Parser (List a)
itemList itemParser =
    Parser.loop [] (itemListHelper itemParser)


itemListHelper : Parser a -> List a -> Parser (Step (List a) (List a))
itemListHelper itemParser revItems =
    oneOf
        [ succeed (\item -> Loop (item :: revItems))
            |= itemParser
        , succeed ()
            |> Parser.map (\_ -> Done (List.reverse revItems))
        ]
