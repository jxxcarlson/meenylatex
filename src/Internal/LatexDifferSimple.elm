module Internal.LatexDifferSimple exposing (..)

import Dict
import Internal.Accumulator as Accumulator
import Internal.DifferSimple exposing (EditRecord)
import Internal.LatexState exposing (LatexState, emptyLatexState)
import Internal.MathMacro
import Internal.Paragraph as Paragraph
import Internal.Parser exposing (LatexExpression)
import Internal.Render as Render exposing (render)
import Internal.SourceMap as SourceMap

addPreamble : String -> Maybe String -> String
addPreamble text mpreamble =
    case mpreamble of
        Nothing -> text
        Just str -> str ++ "\n\n" ++ text

init : (String -> List LatexExpression) -> LatexState -> String -> Maybe String -> EditRecord
init parser latexState text mpreamble =
    initWithSeed 0 parser latexState text mpreamble


initWithSeed : Int -> (String -> List LatexExpression) -> LatexState -> String -> Maybe String -> EditRecord
initWithSeed seed parser latexState text mpreamble =
    let

        paragraphs =
            (addPreamble text mpreamble)
                |> Paragraph.logicalParagraphify

        -- Compute
        ( latexState1, latexExpressionList ) =
            paragraphs
                |> Accumulator.parse emptyLatexState

        -- Save computed LatexState
        latexState2 =
            { emptyLatexState
                | crossReferences = latexState1.crossReferences
                , tableOfContents = latexState1.tableOfContents
                , dictionary = latexState1.dictionary
                , macroDictionary = latexState1.macroDictionary
                , mathMacroDictionary = latexState1.mathMacroDictionary
            }

        idList =
            makeIdListWithSeed seed paragraphs
    in
    EditRecord text mpreamble paragraphs latexExpressionList idList latexState2


makeIdList : List String -> List String
makeIdList paragraphs =
    List.range 1 (List.length paragraphs) |> List.map (Internal.DifferSimple.prefixer 0)


makeIdListWithSeed : Int -> List String -> List String
makeIdListWithSeed seed paragraphs =
    List.range 1 (List.length paragraphs) |> List.map (Internal.DifferSimple.prefixer seed)


update :
    Int
    -> (String -> List LatexExpression)
    -> EditRecord
    -> String
    -> Maybe String
    -> EditRecord
update seed parser editRecord source mpreamble =
    if Internal.DifferSimple.isEmpty editRecord then
        init parser emptyLatexState source mpreamble

    else
        Internal.DifferSimple.update seed parser editRecord source mpreamble
