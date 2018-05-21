module EllieMacroTest2 exposing (main)

import Browser
import Html exposing (Html, text, pre)
import Dict exposing (Dict)
import Parser exposing (..)
import Set


line str =
    text <| str ++ "\n\n"


debug str expr =
    text <| str ++ ": " ++ (Debug.toString expr) ++ "\n\n"


main : Program () () msg
main =
    Browser.staticPage
        (pre []
            [ line <| "SSCCE"
            , debug "render, 1" <| render mxe1
            ]
        )



{- RENDERER -}


mxe1 =
    grabMacroExpression <| (run macro) "\\wasup{foo}{bar}"


mxe2 =
    grabMacroExpression <| (run macro) "\\wasup{\\lol{foo}}{bar}"


grabMacroExpression : Result (List DeadEnd) MacroExpression -> MacroExpression
grabMacroExpression result =
    case result of
        Ok macroExpression ->
            macroExpression

        Err err ->
            MXString "Oops, error!"


type alias MacroDict =
    Dict String (MacroExpression -> String)


macroDict : MacroDict
macroDict =
    Dict.fromList
        [ ( "wasup", renderWasup )
        , ( "lol", renderLol )
        ]


evalDict : MacroDict -> String -> List MacroExpression -> String
evalDict dict macroName_ argList =
    case (Dict.get macroName_ dict) of
        Just f ->
            (List.map f argList) |> String.join " "

        Nothing ->
            "Nothing"


renderWasup argList =
    "<wasup>" ++ render argList ++ "</wasup>"


renderLol argList =
    "<lol>" ++ render argList ++ "</lol>"


render : MacroExpression -> String
render macroExpression =
    case macroExpression of
        MXString str ->
            str

        Macro name argList ->
            evalDict macroDict name argList

        Arg argList ->
            List.map render argList |> String.join " "

        MXError _ ->
            "Error"



{- Macro Parser -}


type MacroExpression
    = MXString String
    | Macro String (List MacroExpression)
    | Arg (List MacroExpression)
    | MXError (List DeadEnd)


macro : Parser MacroExpression
macro =
    (succeed Macro
        |= macroName
        |= itemList arg
        |. spaces
    )


macroName : Parser String
macroName =
    variable
        { start = \c -> c == '\\'
        , inner = \c -> Char.isAlphaNum c
        , reserved = Set.fromList [ "\\begin", "\\end" ]
        }


arg : Parser MacroExpression
arg =
    (succeed identity
        |. symbol "{"
        |= itemList (oneOf [ macroArgWords, lazy (\_ -> macro) ])
        |. symbol "}"
        |> map Arg
    )


macroArgWords : Parser MacroExpression
macroArgWords =
    nonEmptyItemList macroArgWord
        |> map (String.join " ")
        |> map MXString


macroArgWord : Parser String
macroArgWord =
    word inMacroArg


inMacroArg : Char -> Bool
inMacroArg c =
    not (c == '\\' || c == '}' || c == ' ' || c == '\n')


word : (Char -> Bool) -> Parser String
word inWord =
    succeed String.slice
        |. spaces
        |= getOffset
        |. chompIf inWord
        |. chompWhile inWord
        |. spaces
        |= getOffset
        |= getSource


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
