module MiniLatex.ParserHelpers exposing
    ( between
    , braces
    , brackets
    , itemList
    , itemListHelper
    , itemListWithSeparator
    , itemListWithSeparatorHelper
    , itemList_
    , many
    , manyHelp
    , nonEmptyItemList
    , parens
    , parseBetweenSymbols
    , parseToSymbol
    , parseUntil
    , some
    , spaces
    , transformWords
    , ws
    )

-- exposing
--     ( spaces
--     , ws
--     , parseUntil
--     , parseToSymbol
--     , parseBetweenSymbols
--     , nonEmptyItemList
--     , itemList
--     , itemListWithSeparator
--     , transformWords
--     )

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
parseToSymbol : String -> Parser String
parseToSymbol marker =
    (getChompedString <|
        succeed identity
            |= chompUntilEndOr marker
            |. symbol marker
    )
        |> map (String.dropRight (String.length marker))


parseBetweenSymbols : String -> String -> Parser String
parseBetweenSymbols startString endString =
    succeed identity
        |. symbol startString
        |. spaces
        |= parseUntil endString



{- ITEM LIST PARSERS -}


nonEmptyItemList : Parser a -> Parser (List a)
nonEmptyItemList itemParser =
    itemParser
        |> andThen (\x -> itemList_ [ x ] itemParser)


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



{- From Punie/elm-parser-extras -}


{-| Apply a parser zero or more times and return a list of the results.
-}
many : Parser a -> Parser (List a)
many p =
    loop [] (manyHelp p)


{-| Apply a parser one or more times and return a tuple of the first result parsed
and the list of the remaining results.
-}
some : Parser a -> Parser ( a, List a )
some p =
    succeed Tuple.pair
        |= p
        |. spaces
        |= many p


{-| Parse an expression between two other parsers
-}
between : Parser opening -> Parser closing -> Parser a -> Parser a
between opening closing p =
    succeed identity
        |. opening
        |. spaces
        |= p
        |. spaces
        |. closing


{-| Parse an expression between parenthesis.
parens p == between (symbol "(") (symbol ")") p
-}
parens : Parser a -> Parser a
parens =
    between (symbol "(") (symbol ")")


{-| Parse an expression between curly braces.
braces p == between (symbol "{") (symbol "}") p
-}
braces : Parser a -> Parser a
braces =
    between (symbol "{") (symbol "}")


{-| Parse an expression between square brackets.
brackets p == between (symbol "[") (symbol "]") p
-}
brackets : Parser a -> Parser a
brackets =
    between (symbol "[") (symbol "]")



-- HELPERS


manyHelp : Parser a -> List a -> Parser (Step (List a) (List a))
manyHelp p vs =
    oneOf
        [ succeed (\v -> Loop (v :: vs))
            |= p
            |. spaces
        , succeed ()
            |> map (\_ -> Done (List.reverse vs))
        ]
