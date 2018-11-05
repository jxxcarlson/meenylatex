module MiniLatex.StateReducerHelpers2 exposing(..)

import MiniLatex.Parser as Parser exposing(LatexExpression(..))
import MiniLatex.Utility as Utility
import Parser as P 
import MiniLatex.ParserHelpers as ParserHelpers   

import MiniLatex.LatexState
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

import MiniLatex.ParserTools as PT 

updateSectionNumber : (List LatexExpression) -> LatexState -> LatexState
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


updateSubsectionNumber : (List LatexExpression) -> LatexState -> LatexState
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


updateSubsubsectionNumber : (List LatexExpression) -> LatexState -> LatexState
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

setSectionCounters : (List LatexExpression) -> LatexState -> LatexState
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
                |> P.run (Parser.macro ParserHelpers.ws)
    in
        case maybeMacro of
            Ok macro ->
                macro |> PT.getFirstMacroArg "label"

            _ ->
                ""
