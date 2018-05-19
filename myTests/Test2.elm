module Test2 exposing (..)

import Parser exposing (..)
import List.Extra


{-

   Below is a simplified version of the MiniLatex parser. The infinite recursion
   problem was solved by using `nonEmptyItemList` instead of `itemList` in defining
   the `words` parser.
-}


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
        [ words
        , inlineMath ws
        , lazy (\_ -> environment)
        ]



{- SOME TEST DATA -}


test1 =
    "This is a test."


test2 =
    "$a^2 + b^2 = c^2$"


test3 =
    "Pythagoras said that $a^2 + b^2 = c^2$.  Yay!"


test4 =
    "\\begin{th}$a^2 = b^3$\\end{th}"


test5 =
    "\\begin{A}\\begin{B}$a^2 = b^3$\\end{B}\\end{A}"


test6 =
    "\\begin{A}$y^h = 4$\\begin{B}$a^2 = b^3$\\end{B}\\end{A}"


test7 =
    "\\begin{th}\n\nIt's gonna be OK!\n\n\\end{th}"



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
    succeed String.slice
        |. ws
        |= getOffset
        |. chompIf inWord
        |. chompWhile inWord
        |. ws
        |= getOffset
        |= getSource


notSpaceOrSpecialCharacters : Char -> Bool
notSpaceOrSpecialCharacters c =
    not (c == ' ' || c == '\n' || c == '\\' || c == '$')


words : Parser LatexExpression
words =
    succeed identity
        |. ws
        |= words_
        |. ws


words_ =
    nonEmptyItemList (word notSpaceOrSpecialCharacters)
        |> map (String.join " ")
        |> map LXString



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



{- ITEM LIST: FOR REPEATED STRUCTURES -}


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



{- Char -> Bool (WHITE SPACE) -}


space : Parser ()
space =
    chompWhile (\c -> c == ' ')


ws : Parser ()
ws =
    chompWhile (\c -> c == ' ' || c == '\n')



{- For debugging -}


getCharAt : Int -> String -> Maybe String
getCharAt index str =
    str |> String.split "" |> List.Extra.getAt (index - 1)
