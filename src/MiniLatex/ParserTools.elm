module MiniLatex.ParserTools exposing (..)

{- Some of these functoins are used by MiniLatex.Accumulator -}

import MiniLatex.Parser exposing (LatexExpression(..))


{-| 
List.filter (isMacro "label") latexList returns
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

{- PT.filterMacro "label" list |> List.head |> Maybe.map PT.getMacroArgs2
-}
{- PT.filterMacro "label" list |> List.head |> Maybe.map PT.getMacroArgs2 |> Maybe.andThen  List.head  -}

macroValue macroName envBody = 
  case envBody of 
    LatexList list -> macroValue_ macroName list 
    _ -> Nothing

macroValue_ macroName list = 
  list
    |> filterMacro macroName 
    |> List.head 
    |> Maybe.map getMacroArgs2 
    |> Maybe.andThen  List.head
    |> Maybe.andThen List.head  
    |> Maybe.map getString



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


{-| Get string arg -}
unpackString : List LatexExpression -> String
unpackString expr =
    expr |> headLatexExpression |> valueOfLatexList |> headLatexExpression |> valueOfLXString
