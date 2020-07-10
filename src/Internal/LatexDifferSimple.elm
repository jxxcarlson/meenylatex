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


init : (String -> List LatexExpression) -> LatexState -> String -> EditRecord
init parser latexState text =
    initWithSeed 0 parser latexState text


initWithSeed : Int -> (String -> List LatexExpression) -> LatexState -> String -> EditRecord
initWithSeed seed parser latexState text =
    let
        paragraphs =
            text
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

        sourceMap =
            -- TODO: this can be improved by diffing
            SourceMap.generate paragraphs idList
    in
    EditRecord paragraphs latexExpressionList idList latexState2 sourceMap


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
    -> EditRecord
update seed parser editRecord source =
    if Internal.DifferSimple.isEmpty editRecord then
        init parser emptyLatexState source

    else
        source
            |> Internal.DifferSimple.update seed parser editRecord
