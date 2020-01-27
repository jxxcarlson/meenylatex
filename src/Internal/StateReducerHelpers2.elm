module Internal.StateReducerHelpers2 exposing (..)

import Internal.LatexState
    exposing
        ( Counters
        , CrossReferences
        , LatexState
        , addSection
        , getCounter
        , incrementCounter
        , setCrossReference
        , setDictionaryItem
        , updateCounter
        )
import Internal.Parser as LXParser exposing (LatexExpression(..))
import Internal.ParserHelpers as ParserHelpers
import Internal.ParserTools as PT
import Internal.Utility as Utility
import Parser as P
import Parser.Advanced


updateSectionNumber : List LatexExpression -> LatexState -> LatexState
updateSectionNumber macroArgs latexState =
    let
        label =
            getCounter "s1" latexState |> (\x -> x + 1) |> String.fromInt
    in
    latexState
        |> incrementCounter "s1"
        |> updateCounter "s2" 0
        |> updateCounter "s3" 0
        |> addSection (PT.unpackString macroArgs) label 1


updateSubsectionNumber : List LatexExpression -> LatexState -> LatexState
updateSubsectionNumber macroArgs latexState =
    let
        s1 =
            getCounter "s1" latexState |> String.fromInt

        s2 =
            getCounter "s2" latexState |> (\x -> x + 1) |> String.fromInt

        label =
            s1 ++ "." ++ s2
    in
    latexState
        |> incrementCounter "s2"
        |> updateCounter "s3" 0
        |> addSection (PT.unpackString macroArgs) label 2


updateSubsubsectionNumber : List LatexExpression -> LatexState -> LatexState
updateSubsubsectionNumber macroArgs latexState =
    let
        s1 =
            getCounter "s1" latexState |> String.fromInt

        s2 =
            getCounter "s2" latexState |> String.fromInt

        s3 =
            getCounter "s3" latexState |> (\x -> x + 1) |> String.fromInt

        label =
            s1 ++ "." ++ s2 ++ "." ++ s3
    in
    latexState
        |> incrementCounter "s3"
        |> addSection (PT.unpackString macroArgs) label 2


setSectionCounters : List LatexExpression -> LatexState -> LatexState
setSectionCounters macroArgs latexState =
    let
        argList =
            macroArgs |> List.map PT.latexList2List |> List.map PT.list2LeadingString

        arg1 =
            getAt 0 argList

        arg2 =
            getAt 1 argList

        initialSectionNumber =
            if arg1 == "section" then
                arg2 |> String.toInt |> Maybe.withDefault 0

            else
                -1
    in
    if initialSectionNumber > -1 then
        latexState
            |> updateCounter "s1" (initialSectionNumber - 1)
            |> updateCounter "s2" 0
            |> updateCounter "s3" 0

    else
        latexState


setDictionaryItemForMacro : String -> List LatexExpression -> LatexState -> LatexState
setDictionaryItemForMacro name args latexState =
    let
        value =
            PT.unpackString args
    in
    setDictionaryItem name value latexState


setTheoremNumber : LatexExpression -> LatexState -> LatexState
setTheoremNumber body latexState =
    let
        label =
            case body |> PT.macroValue "label" of
                Just str ->
                    str

                Nothing ->
                    ""

        latexState1 =
            incrementCounter "tno" latexState

        tno =
            getCounter "tno" latexState1

        s1 =
            getCounter "s1" latexState1

        latexState2 =
            if label /= "" then
                setCrossReference label (String.fromInt s1 ++ "." ++ String.fromInt tno) latexState1

            else
                latexState1
    in
    latexState2


setEquationNumber : LatexExpression -> LatexState -> LatexState
setEquationNumber body latexState =
    let
        label =
            case body of
                LXString str ->
                    getLabel str

                _ ->
                    ""

        latexState1 =
            incrementCounter "eqno" latexState

        eqno =
            getCounter "eqno" latexState1

        s1 =
            getCounter "s1" latexState1

        latexState2 =
            if label /= "" then
                setCrossReference label (String.fromInt s1 ++ "." ++ String.fromInt eqno) latexState1

            else
                latexState1
    in
    latexState2


setBibItemXRef : List LatexExpression -> List LatexExpression -> LatexState -> LatexState
setBibItemXRef optionalArgs args latexState =
    let
        label =
            PT.unpackString args

        value =
            if optionalArgs == [] then
                label

            else
                PT.unpackString optionalArgs
    in
    setDictionaryItem ("bibitem:" ++ label) value latexState


setMacroDefinition : String -> LatexExpression -> LatexState -> LatexState
setMacroDefinition name body latexState =
    --    let
    --      maybeDefinition = body -- |> PT.latexList2List |> List.head |> Maybe.map PT.getString
    --    in
    --  case maybeDefinition of
    --    Nothing -> latexState
    --    Just definition ->
    Internal.LatexState.setMacroDefinition name (NewCommand name 0 body) latexState



{- Helpers -}


getAt : Int -> List String -> String
getAt k list_ =
    Utility.getAt k list_ |> Maybe.withDefault "xxx"


getElement : Int -> List LatexExpression -> String
getElement k list =
    let
        lxString =
            Utility.getAt k list |> Maybe.withDefault (LXString "xxx")
    in
    case lxString of
        LXString str ->
            str

        _ ->
            "yyy"


getLabel str =
    let
        maybeMacro =
            str
                |> String.trim
                |> Parser.Advanced.run (LXParser.macro LXParser.eatWhiteSpace)
    in
    case maybeMacro of
        Ok macro ->
            macro |> PT.getFirstMacroArg "label"

        _ ->
            ""
