module MeenyLatex.ParserHelpers
    exposing
        ( spaces
        , ws
        , parseUntil
        , parseTo
        , parseFromTo
        , nonEmptyItemList
        , itemList
        , itemListWithSeparator
        , transformWords
        )

import Parser exposing (..)


{- PARSER HELPERS

   These have varaous types, e.g.,

     - Parser ()
     - String -> Parser String
     - Parser a -> Parser a
     - Parser a -> Parser ()

-}


spaces : Parser ()
spaces =
    chompWhile (\c -> c == ' ')


ws : Parser ()
ws =
    chompWhile (\c -> c == ' ' || c == '\n')


parseUntil : String -> Parser String
parseUntil marker =
    getChompedString <| chompUntil marker


{-| chomp to end of the marker and return the
chomped sring minus the makrder.
-}
parseTo : String -> Parser String
parseTo marker =
    (getChompedString <|
        succeed identity
            |= chompUntilEndOr marker
            |. symbol marker
    )
        |> map (String.dropRight (String.length marker))


parseFromTo : String -> String -> Parser String
parseFromTo startString endString =
    succeed identity
        |. symbol startString
        |. spaces
        |= parseUntil endString



{- ITEM LIST PARSERS -}


nonEmptyItemList : Parser a -> Parser (List a)
nonEmptyItemList itemParser =
    itemParser
        |> andThen (\x -> (itemList_ [ x ] itemParser))


itemList : Parser a -> Parser (List a)
itemList itemParser =
    itemList_ [] itemParser


itemList_ : List a -> Parser a -> Parser (List a)
itemList_ initialList itemParser =
    Parser.loop initialList (itemListHelper itemParser)


itemListHelper : Parser a -> List a -> Parser (Step (List a) (List a))
itemListHelper itemParser revItems =
    oneOf
        [ succeed (\item -> Loop (item :: revItems))
            |= itemParser
        , succeed ()
            |> Parser.map (\_ -> Done (List.reverse revItems))
        ]


itemListWithSeparator : Parser () -> Parser String -> Parser (List String)
itemListWithSeparator separatorParser itemParser =
    Parser.loop [] (itemListWithSeparatorHelper separatorParser itemParser)


itemListWithSeparatorHelper : Parser () -> Parser String -> List String -> Parser (Step (List String) (List String))
itemListWithSeparatorHelper separatorParser itemParser revItems =
    oneOf
        [ succeed (\w -> Loop (w :: revItems))
            |= itemParser
            |. separatorParser
        , succeed ()
            |> Parser.map (\_ -> Done (List.reverse revItems))
        ]



{-
   notSpecialTableOrMacroCharacter : Char -> Bool
   notSpecialTableOrMacroCharacter c =
       not (c == ' ' || c == '\n' || c == '\\' || c == '$' || c == '}' || c == ']' || c == '&')


   notMacroSpecialCharacter : Char -> Bool
   notMacroSpecialCharacter c =
       not (c == '{' || c == '[' || c == ' ' || c == '\n')

-}


{-| Transform special words
-}
transformWords : String -> String
transformWords str =
    if str == "--" then
        "\\ndash"
    else if str == "---" then
        "\\mdash"
    else
        str
