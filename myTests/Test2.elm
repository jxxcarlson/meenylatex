{- TEST 1

   Hi Evan, there is some kind of weird intereaction going on
   inside of

   ```
   latexExpression : Parser LatexExpression
   latexExpression =
       oneOf
           [  lazy (\_ -> environment)  -- (1)
           ,  inlineMath ws             -- (2)
           ,  words                     -- (3)
           ]
   ```

   If 1,2,3 are active, the commands

       > run environment env1
       > run environtment env2

       where env1 = "\\begin{th}$a^2 = b^3$\\end{th}"
       and env2 = "\\begin{th}\nIt's all gonna be OK!\n\\end{th}"

   blow the stack. But the commands

       > run latexExpression "$a^2 = b^3$"
       > run latexExpression "one two three"


   succeed. If 1,2 are active, then `run environment env1`
   command works  -- weird.

   To the extent that I've been able to fix problems,
   they have all had to do with the diffrence between\
   chomping _up to_ a string versus chomping _up through_
   a string.  Here I don't see what is going on.
-}


module Test2 exposing (..)

import Parser exposing (..)


latexExpression : Parser LatexExpression
latexExpression =
    oneOf
        [ lazy (\_ -> environment)
        , inlineMath ws

        -- , words
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
    ws
        |> andThen
            (\_ ->
                itemListWithSeparator ws word
                    |> map (String.join " ")
                    |> map LXString
            )



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
