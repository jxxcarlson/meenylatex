-- https://staging.ellie-app.com/fvkGQjXWcra1/1
{- TEST 1

   > import Parser as P exposing(run)
   > import Test1 exposing(..)
   > run latexExpression "$a^2 = b^3$"
   Ok (InlineMath ("a^2 = b^3"))
       : Result (List.List P.DeadEnd) LatexExpression
   > run latexExpression "one two three"
   Ok (LXString ("one two three"))
       : Result (List.List P.DeadEnd) LatexExpression

-}


module Test1 exposing (..)

import Parser exposing (..)


{- Data type for AST -}


type LatexExpression
    = LXString String
    | InlineMath String
    | Environment String (List LatexExpression) LatexExpression -- Environment name optArgs body
    | LatexList (List LatexExpression)
    | LXError String


latexExpression : Parser LatexExpression
latexExpression =
    oneOf
        [ -- lazy (\_ -> environment)
          inlineMath ws
        , words
        ]



{- MATH -}


inlineMath : Parser () -> Parser LatexExpression
inlineMath wsParser =
    succeed InlineMath
        |. symbol "$"
        |= parseTo "$"
        |. wsParser



{- WORDS -}


word : Parser String
word =
    getChompedString <|
        succeed ()
            |. chompIf (\c -> Char.isAlphaNum c)
            |. chompWhile notSpecialCharacter


notSpecialCharacter : Char -> Bool
notSpecialCharacter c =
    not (c == ' ' || c == '\n' || c == '\\' || c == '$')


words : Parser LatexExpression
words =
    itemListWithSeparator ws word
        |> map (String.join " ")
        |> map LXString



{- PARSER HELPERS -}


parseTo : String -> Parser String
parseTo marker =
    (getChompedString <|
        succeed identity
            |= chompUntilEndOr marker
            |. symbol marker
    )
        |> map (String.dropRight (String.length marker))


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



{- Char -> Bool -}


space : Parser ()
space =
    chompWhile (\c -> c == ' ')


ws : Parser ()
ws =
    chompWhile (\c -> c == ' ' || c == '\n')
