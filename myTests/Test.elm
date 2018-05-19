-- https://staging.ellie-app.com/fvkGQjXWcra1/1


module Test exposing (..)

import Parser exposing (..)


symbolPair : String -> String -> Parser String
symbolPair a b =
    getChompedString (symbol a |> andThen (\_ -> symbol b))



{- Data type for AST -}


env1 =
    "\\begin{th}$a^2 = b^3$\\end{th}"


type LatexExpression
    = LXString String
    | InlineMath String
    | Environment String (List LatexExpression) LatexExpression -- Environment name optArgs body
    | LatexList (List LatexExpression)
    | LXError String


{-| Simplified MiniLatex parser
-}
latexParse : String -> List LatexExpression
latexParse text =
    let
        expr =
            Parser.run latexList text
    in
        case expr of
            Ok (LatexList list) ->
                list

            Err error ->
                [ LXString (deadEndsToString error) ]

            _ ->
                [ LXString "yada!" ]


latexList : Parser LatexExpression
latexList =
    (succeed identity
        |. ws
        |= nonEmptyItemList latexExpression
        |> map LatexList
    )


latexExpression : Parser LatexExpression
latexExpression =
    oneOf
        [ -- lazy (\_ -> environment)
          inlineMath ws
        , words
        ]


{-| Parse things like

    \begin{theorem}
      If $a$ is not divisible by a prime $p$,
      then $a^{p-1}$ is congruent to 1 mod $p$.
    \end{theorem}

-}



-- baz : Parser LatexExpression


baz =
    -- lazy (\_ -> envName |> andThen (\_ -> symbol "xxx"))
    getChompedString (envName |> andThen (\_ -> symbol "xxx"))



{- ENVIRONMENT -}


environment : Parser LatexExpression
environment =
    lazy (\_ -> envName |> andThen environmentOfType)


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



{- ITEM LISTERS -}


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



{- Char -> Bool -}


space : Parser ()
space =
    chompWhile (\c -> c == ' ')


ws : Parser ()
ws =
    chompWhile (\c -> c == ' ' || c == '\n')
