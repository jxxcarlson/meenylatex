module Internal.ParserHelpers exposing
    ( between
    , braces
    , brackets
    , getTag
    , itemList
    , many
    , manyHelp
    , nonEmptyItemList
    , parens
    , parseBetweenSymbols
    , parseToSymbol
    , parseUntil
    , removeLabel
    , some
    , spaces
    , transformWords
    , ws
    )

import Parser.Advanced exposing (..)


type alias HParser a =
    Parser.Advanced.Parser Context Problem a


type Context
    = Definition String


type Problem
    = ExpectingMarker
    | ExpectingLeftBrace
    | ExpectingRightBrace
    | ExpectingLeftBracket
    | ExpectingRightBracket
    | ExpectingLeftParen
    | ExpectingRightParen
    | ExpectingLabel


removeLabel : String -> String
removeLabel str =
    case getArg "label" str of
        Nothing ->
            str

        Just word ->
            String.replace ("\\label{" ++ word ++ "}") "" str


getTag : String -> Maybe String
getTag str =
    getArg "tag" str


parseArg : String -> HParser String
parseArg macroName =
    succeed identity
        |. symbol (Token ("\\" ++ macroName ++ "{") ExpectingLabel)
        |= getChompedString (chompWhile (\c -> c /= '}'))
        |. symbol (Token "}" ExpectingRightBrace)


getArg : String -> String -> Maybe String
getArg macroName str =
    case Parser.Advanced.run (parseArg macroName) str of
        Ok str_ ->
            Just str_

        Err _ ->
            Nothing



{- PARSER HELPERS

   These have varaous types, e.g.,

     - Parser ()
     - String -> Parser String
     - Parser a -> Parser a
     - Parser a -> Parser ()

-}


spaces : HParser ()
spaces =
    chompWhile (\c -> c == ' ')


ws : HParser ()
ws =
    chompWhile (\c -> c == ' ' || c == '\n')


parseUntil : String -> HParser String
parseUntil marker =
    getChompedString <| chompUntil (Token marker ExpectingMarker)


{-| chomp to end of the marker and return the
chomped string minus the marker.
-}
parseToSymbol : String -> HParser String
parseToSymbol marker =
    (getChompedString <|
        succeed identity
            |= chompUntilEndOr marker
            |. symbol (Token marker ExpectingMarker)
    )
        |> map (String.dropRight (String.length marker))


parseBetweenSymbols : String -> String -> HParser String
parseBetweenSymbols startSymbol endSymbol =
    succeed identity
        |. symbol (Token startSymbol ExpectingMarker)
        |. spaces
        |= parseUntil endSymbol



{- ITEM LIST PARSERS -}


nonEmptyItemList : HParser a -> HParser (List a)
nonEmptyItemList itemParser =
    itemParser
        |> andThen (\x -> itemList_ [ x ] itemParser)


itemList : HParser a -> HParser (List a)
itemList itemParser =
    itemList_ [] itemParser


itemList_ : List a -> HParser a -> HParser (List a)
itemList_ initialList itemParser =
    loop initialList (itemListHelper itemParser)


itemListHelper : HParser a -> List a -> HParser (Step (List a) (List a))
itemListHelper itemParser revItems =
    oneOf
        [ succeed (\item -> Loop (item :: revItems))
            |= itemParser
        , succeed ()
            |> map (\_ -> Done (List.reverse revItems))
        ]



-- itemListWithSeparator : Parser () -> Parser a -> Parser (List a)
-- itemListWithSeparator separatorParser itemParser =
--     Parser.loop [] (itemListWithSeparatorHelper separatorParser itemParser)
-- itemListWithSeparatorHelper : Parser () -> Parser a -> List a -> Parser (Step (List a) (List a))
-- itemListWithSeparatorHelper separatorParser itemParser revItems =
--     oneOf
--         [ succeed (\w -> Loop (w :: revItems))
--             |= itemParser
--             |. separatorParser
--         , succeed ()
--             |> Parser.map (\_ -> Done (List.reverse revItems))
--         ]
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
many : HParser a -> HParser (List a)
many p =
    loop [] (manyHelp p)


{-| Apply a parser one or more times and return a tuple of the first result parsed
and the list of the remaining results.
-}
some : HParser a -> HParser ( a, List a )
some p =
    succeed Tuple.pair
        |= p
        |. spaces
        |= many p


{-| Parse an expression between two other parser

    import Parser exposing(symbol)

    Parser.run (between (symbol "<<") (symbol ">>") Parser.int) "<<4>>"
    --> Ok 4

-}
between : HParser opening -> HParser closing -> HParser a -> HParser a
between opening closing p =
    succeed identity
        |. opening
        |. spaces
        |= p
        |. spaces
        |. closing


{-| Parse an expression between parenthesis.

    import Parser

    Parser.run (parens Parser.int) "(4)"
    --> Ok 4

-}
parens : HParser a -> HParser a
parens =
    between (symbol (Token "(" ExpectingLeftParen)) (symbol (Token ")" ExpectingRightParen))


{-| Parse an expression between curly braces.

    import Parser

    Parser.run (braces Parser.int) "{4}"
    --> Ok 4

-}
braces : HParser a -> HParser a
braces =
    between (symbol (Token "{" ExpectingLeftBrace)) (symbol (Token "}" ExpectingRightBrace))


{-| Parse an expression between square brackets.
brackets p == between (symbol "[") (symbol "]") p
-}
brackets : HParser a -> HParser a
brackets =
    between (symbol (Token "[" ExpectingLeftBracket)) (symbol (Token "]" ExpectingRightBracket))



-- HELPERS


manyHelp : HParser a -> List a -> HParser (Step (List a) (List a))
manyHelp p vs =
    oneOf
        [ succeed (\v -> Loop (v :: vs))
            |= p
            |. spaces
        , succeed ()
            |> map (\_ -> Done (List.reverse vs))
        ]
