module Test2 exposing (..)

import Parser exposing (..)
import List.Extra


{-

   > run latexList "$1$ $2$\\begin{a}\\begin{b}$11$\\end{b}\\end{a}$3$"
   Ok (LatexList ([InlineMath "1",InlineMath "2",Environment "a" [] (LatexList ([Environment "b" [] (LatexList ([InlineMath "11"]))])),InlineMath "3"]))

-}


getCharAt : Int -> String -> Maybe String
getCharAt index str =
    str |> String.split "" |> List.Extra.getAt index


latexList : Parser LatexExpression
latexList =
    (succeed identity
        |. ws
        |= itemList latexExpression
        |> map LatexList
    )


latexExpression : Parser LatexExpression
latexExpression =
    oneOf
        [ inlineMath ws
        , lazy (\_ -> environment)

        --, words
        ]


env1 =
    "\\begin{th}$a^2 = b^3$\\end{th}"


env2 =
    "\\begin{A}\\begin{B}$a^2 = b^3$\\end{B}\\end{A}"


env2b =
    "\\begin{A}$y^h = 4$\\begin{B}$a^2 = b^3$\\end{B}\\end{A}"


env3 =
    "\\begin{th}\nIt's all gonna be OK!\n\\end{th}"



{- Data type for AST -}


type LatexExpression
    = LXString String
    | InlineMath String
    | Environment String (List LatexExpression) LatexExpression -- Environment name optArgs body
    | LatexList (List LatexExpression)
    | LXError String



{- MATH -}


inlineMath : Parser () -> Parser LatexExpression
inlineMath wsParser =
    succeed InlineMath
        |. ws
        |. symbol "$"
        |= parseTo "$"
        |. wsParser



{- WORDS -}


word : (Char -> Bool) -> Parser String
word inWord =
    getChompedString <|
        succeed ()
            |. chompIf (\c -> Char.isAlphaNum c)
            |. chompWhile inWord


notSpecialCharacter : Char -> Bool
notSpecialCharacter c =
    not (c == ' ' || c == '\n' || c == '\\' || c == '$')


words : Parser LatexExpression
words =
    ws
        |> andThen
            (\_ ->
                itemListWithSeparator ws (word notSpecialCharacter)
                    |> map (String.join " ")
                    |> map LXString
            )



{- ENVIRONMENT -}


environment : Parser LatexExpression
environment =
    -- vvv lazy??
    envName |> andThen environmentOfType


envName : Parser String
envName =
    (succeed identity
        |. spaces
        |. symbol "\\begin{"
        |= parseTo "}"
    )


environmentOfType : String -> Parser LatexExpression
environmentOfType envType =
    let
        theEndWord =
            "\\end{" ++ envType ++ "}"

        envKind =
            envType
    in
        environmentParser theEndWord envType


environmentParser : String -> String -> Parser LatexExpression
environmentParser endWord_ envType =
    (succeed identity
        |. ws
        |= itemList latexExpression
        |. ws
        |. symbol endWord_
        |. ws
        |> map LatexList
        |> map (Environment envType [])
    )



{- PARSER HELPERS -}


parseTo : String -> Parser String
parseTo marker =
    (getChompedString <|
        succeed identity
            |= chompUntilEndOr marker
            |. symbol marker
    )
        |> map (String.dropRight (String.length marker))



{- ITEM LIST -}


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


itemListWithSeparator : Parser () -> Parser a -> Parser (List a)
itemListWithSeparator separatorParser itemParser =
    Parser.loop [] (itemListWithSeparatorHelper separatorParser itemParser)


itemListWithSeparatorHelper : Parser () -> Parser a -> List a -> Parser (Step (List a) (List a))
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
