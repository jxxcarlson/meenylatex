module Internal.LatexDiffer exposing (init, initWithSeed, update)

import Dict
import Internal.Accumulator as Accumulator
import Internal.Differ exposing (EditRecord)
import Internal.LatexState exposing (LatexState, emptyLatexState)
import Internal.MathMacro
import Internal.Paragraph as Paragraph
import Internal.Parser exposing (LatexExpression)
import Internal.Render as Render exposing (render)
import Internal.SourceMap as SourceMap


init : (String -> List LatexExpression) -> (LatexState -> List LatexExpression -> a) -> LatexState -> String -> EditRecord a
init parser renderer latexState text =
    initWithSeed 0 parser renderer latexState text


initWithSeed :
    Int
    -> (String -> List LatexExpression)
    -> (LatexState -> List LatexExpression -> a)
    -> LatexState
    -> String
    -> EditRecord a
initWithSeed seed parser renderer latexState text =
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

        -- Use latexExpression list to compute renderedParagraphs
        ( _, renderedParagraphs ) =
            latexExpressionList
                |> Accumulator.render renderer latexState2

        idList =
            makeIdListWithSeed seed paragraphs

        sourceMap =
            -- TODO: this can be improved by diffing
            SourceMap.generate paragraphs idList
    in
    EditRecord paragraphs latexExpressionList idList renderedParagraphs latexState2 sourceMap


makeIdList : List String -> List String
makeIdList paragraphs =
    List.range 1 (List.length paragraphs) |> List.map (Internal.Differ.prefixer 0)


makeIdListWithSeed : Int -> List String -> List String
makeIdListWithSeed seed paragraphs =
    List.range 1 (List.length paragraphs) |> List.map (Internal.Differ.prefixer seed)


update :
    Int
    -> (String -> List LatexExpression)
    -> (LatexState -> List LatexExpression -> a)
    -> (LatexState -> String -> a)
    -> EditRecord a
    -> String
    -> EditRecord a
update seed parser renderLatexExpression renderString editRecord source =
    if Internal.Differ.isEmpty editRecord then
        init parser renderLatexExpression emptyLatexState source

    else
        source
            |> Internal.Differ.update seed parser (renderString editRecord.latexState) editRecord
