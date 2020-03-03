module Internal.LatexState exposing (..)

import Dict
import Internal.Parser exposing (LatexExpression)
import Internal.MathMacro exposing(MathMacroDict)


{- TYPES AND DEFAULT VALUES -}


type alias InitialData =
    { mathMacroDictionary : MathMacroDict}


type alias Counters =
    Dict.Dict String Int


type alias CrossReferences =
    Dict.Dict String String


type alias TableOfContents =
    List TocEntry


type alias TocEntry =
    { name : String, label : String, level : Int }


type alias Dictionary =
    Dict.Dict String String


type alias MacroDictionary =
    Dict.Dict String LatexExpression


emptyDict : Dict.Dict k v
emptyDict =
    Dict.empty


type alias LatexState =
    { counters : Counters
    , crossReferences : CrossReferences
    , tableOfContents : TableOfContents
    , dictionary : Dictionary
    , macroDictionary : MacroDictionary
    , mathMacroDictionary : MathMacroDict
    }


addSection : String -> String -> Int -> LatexState -> LatexState
addSection sectionName label level latexState =
    let
        newEntry =
            TocEntry sectionName label level

        toc =
            latexState.tableOfContents ++ [ newEntry ]
    in
    { latexState | tableOfContents = toc }


getCounter : String -> LatexState -> Int
getCounter name latexState =
    case Dict.get name latexState.counters of
        Just k ->
            k

        Nothing ->
            0


getCrossReference : String -> LatexState -> String
getCrossReference label latexState =
    case Dict.get label latexState.crossReferences of
        Just ref ->
            ref

        Nothing ->
            "??"


getDictionaryItem : String -> LatexState -> String
getDictionaryItem key latexState =
    case Dict.get key latexState.dictionary of
        Just value ->
            value

        Nothing ->
            ""


setDictionaryItem : String -> String -> LatexState -> LatexState
setDictionaryItem key value latexState =
    let
        dictionary =
            latexState.dictionary

        newDictionary =
            Dict.insert key value dictionary
    in
    { latexState | dictionary = newDictionary }


setMathMacroDictionary : String -> LatexState -> LatexState
setMathMacroDictionary str latexState =
   { latexState | mathMacroDictionary = Internal.MathMacro.makeMacroDict str }

incrementCounter : String -> LatexState -> LatexState
incrementCounter name latexState =
    let
        maybeInc =
            Maybe.map (\x -> x + 1)

        newCounters =
            Dict.update name maybeInc latexState.counters
    in
    { latexState | counters = newCounters }


updateCounter : String -> Int -> LatexState -> LatexState
updateCounter name value latexState =
    let
        maybeSet =
            Maybe.map (\x -> value)

        newCounters =
            Dict.update name maybeSet latexState.counters
    in
    { latexState | counters = newCounters }


setCrossReference : String -> String -> LatexState -> LatexState
setCrossReference label value latexState =
    let
        crossReferences =
            latexState.crossReferences

        newCrossReferences =
            Dict.insert label value crossReferences
    in
    { latexState | crossReferences = newCrossReferences }


setMacroDefinition : String -> LatexExpression -> LatexState -> LatexState
setMacroDefinition macroName macroDefinition latexState =
    let
        macroDictionary =
            latexState.macroDictionary

        newMacroDictionary =
            Dict.insert macroName macroDefinition macroDictionary
    in
    { latexState | macroDictionary = newMacroDictionary }


initialCounters : Dict.Dict String number
initialCounters =
    Dict.fromList [ ( "s1", 0 ), ( "s2", 0 ), ( "s3", 0 ), ( "tno", 0 ), ( "eqno", 0 ) ]


emptyLatexState : LatexState
emptyLatexState =
    { counters = initialCounters
    , crossReferences = Dict.empty
    , dictionary = Dict.empty
    , tableOfContents = []
    , macroDictionary = Dict.empty
    , mathMacroDictionary = Dict.empty
    }
