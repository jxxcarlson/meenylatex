module MiniLatex.ParserTools exposing (..)

{- Some of these functoins are used by MiniLatex.Accumulator -}

import MiniLatex.Parser as MP exposing (LatexExpression(..))
import MiniLatex.Utility as Utility


{-| List.filter (isMacro "label") latexList returns
a list of macros with name "label"
-}
isMacro : String -> LatexExpression -> Bool
isMacro macroName latexExpression =
    case latexExpression of
        Macro name _ _ ->
            name
                == macroName

        _ ->
            False


filterMacro : String -> List LatexExpression -> List LatexExpression
filterMacro macroName list =
    List.filter (isMacro macroName) list



-- smaroArgs : LatexExpression -> Maybe (Liat LatexExpression)
-- macroArgs  latexExpression =
--   case latexExpression of
--      (Macro _ _ list) -> Just list
--      _ -> Nothing
{- PT.filterMacro "label" list |> List.head |> Maybe.map PT.getMacroArgs2 -}
{- PT.filterMacro "label" list |> List.head |> Maybe.map PT.getMacroArgs2 |> Maybe.andThen  List.head -}


macroValue : String -> LatexExpression -> Maybe String
macroValue macroName envBody =
    case envBody of
        LatexList list ->
            macroValue_ macroName list

        _ ->
            Nothing


macroValue_ : String -> List LatexExpression -> Maybe String
macroValue_ macroName list =
    list
        |> filterMacro macroName
        |> List.head
        |> Maybe.map getMacroArgs2
        |> Maybe.andThen List.head
        |> Maybe.andThen List.head
        |> Maybe.map getString


{-|

> pp
> Macro "setcounter" [][LatexList [LXString "section"],LatexList [LXString "3"]]

> getMacroArgs2 pp
> [[LXString "section"],[LXString "3"]]

    : List (List LatexExpression)

getMacroArgs2 pp |> getAt 1 == Just [LXString "3"]

-}
addToNumberAsString : Int -> String -> String
addToNumberAsString k str =
    case String.toInt str of
        Nothing ->
            str

        Just n ->
            n + k |> String.fromInt



-- decrementSetCounter : LatexExpression -> List LatexExpression


decrementArg1 : LatexExpression -> List LatexExpression
decrementArg1 macro =
    getMacroArgs2 macro
        |> Utility.getAt 1
        |> Maybe.map (List.map (transformLXString (addToNumberAsString -1)))
        |> Maybe.withDefault []


{-|

> pp
> Macro "setcounter" [][LatexList [LXString "section"],LatexList [LXString "3"]]

> decrementSetCounter pp
> Macro "setcounter" [][LatexList [LXString "section"],LatexList [LXString "2"]]

-}
decrementSetCounter : LatexExpression -> LatexExpression
decrementSetCounter macro =
    case macro of
        Macro "setcounter" [] args ->
            let
                arg1 =
                    (Macro "setcounter" [] args)
                        |> decrementArg1
            in
                Macro "setcounter" [] [ LatexList [ LXString "section" ], LatexList arg1 ]

        _ ->
            macro


{-|

> transformLXString (addToNumberAsString -1) (LXString "5")
> LXString "4" : LatexExpression
-}
transformLXString : (String -> String) -> LatexExpression -> LatexExpression
transformLXString f latexExpr =
    case latexExpr of
        LXString str ->
            LXString (f str)

        _ ->
            latexExpr


transformLXList : (String -> String) -> LatexExpression -> LatexExpression
transformLXList f latexExpr =
    case latexExpr of
        LatexList list ->
            LatexList <| (List.map (transformLXString f) list)

        _ ->
            latexExpr


{-|

> pp
> Macro "setcounter" [][LatexList [LXString "section"],LatexList [LXString "3"]]

> args |> List.map (transformLXList (addToNumberAsString -1))
> [LatexList [LXString "section"],LatexList [LXString "2"]]

-}
decrementSetCounterArgs : List LatexExpression -> List LatexExpression
decrementSetCounterArgs args =
    args |> List.map (transformLXList (addToNumberAsString -1))


getDecrementedSetCounterArg : List LatexExpression -> Maybe String
getDecrementedSetCounterArg args =
    args
        |> decrementSetCounterArgs
        |> Utility.getAt 1
        |> Maybe.map latexList2List
        |> Maybe.andThen List.head
        |> Maybe.map getString


getMacroArgs2 : LatexExpression -> List (List LatexExpression)
getMacroArgs2 latexExpression =
    case latexExpression of
        Macro name optArgs args ->
            args
                |> List.map latexList2List

        _ ->
            []


getMacroArgs macroName latexExpression =
    case latexExpression of
        Macro name optArgs args ->
            if name == macroName then
                args
                    |> List.map latexList2List
            else
                []

        _ ->
            []


getSimpleMacroArgs macroName latexExpression =
    latexExpression |> getMacroArgs macroName |> List.map list2LeadingString


getFirstMacroArg macroName latexExpression =
    let
        arg =
            getSimpleMacroArgs macroName latexExpression |> List.head
    in
        case arg of
            Just value ->
                value

            _ ->
                ""


list2LeadingString list =
    let
        head_ =
            list |> List.head

        value =
            case head_ of
                Just value_ ->
                    value_

                Nothing ->
                    LXString ""
    in
        case value of
            LXString str ->
                str

            _ ->
                ""


latexList2List latexExpression =
    case latexExpression of
        LatexList list ->
            list

        _ ->
            []


getString : LatexExpression -> String
getString latexString =
    case latexString of
        LXString str ->
            str

        _ ->
            ""



-- getMacros : String -> List LatexExpression -> List LatexExpression
-- getMacros macroName expressionList =
--     expressionList
--         |> List.filter (\expr -> isMacro macroName expr)
-- unpack : List LatexExpression -> LatexExpression


headLatexExpression : List LatexExpression -> LatexExpression
headLatexExpression list =
    let
        he =
            case List.head list of
                Just expr ->
                    expr

                Nothing ->
                    LatexList []
    in
        he


valueOfLatexList : LatexExpression -> List LatexExpression
valueOfLatexList latexList =
    case latexList of
        LatexList value ->
            value

        _ ->
            [ LXString "Error getting value of LatexList" ]


valueOfLXString : LatexExpression -> String
valueOfLXString expr =
    case expr of
        LXString str ->
            str

        _ ->
            "Error getting value of LatexString"


{-| Get string arg
-}
unpackString : List LatexExpression -> String
unpackString expr =
    expr |> headLatexExpression |> valueOfLatexList |> headLatexExpression |> valueOfLXString
