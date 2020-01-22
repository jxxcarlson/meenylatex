module Internal.LatexDiffer exposing (init, initWithSeed, update)

import Internal.Accumulator as Accumulator
import Internal.Differ as Differ exposing (EditRecord)
import Internal.LatexState exposing (LatexState, emptyLatexState)
import Internal.Paragraph as Paragraph
import Internal.Parser exposing (LatexExpression)
import Internal.Render2 as Render exposing (render)
import Internal.SourceMap as SourceMap
import Dict


init : (String -> List LatexExpression) -> (LatexState -> List LatexExpression -> a) -> LatexState -> String -> EditRecord a
init parser renderer latexState text =
    initWithSeed 0 parser renderer latexState text


initWithSeed : Int -> (String -> List LatexExpression) -> (LatexState -> List LatexExpression -> a) -> LatexState -> String -> EditRecord a
initWithSeed seed parser renderer latexState text =
    let
        paragraphs =
            text
                |> Paragraph.logicalParagraphify

        ( latexState1, latexExpressionList ) =
            paragraphs
                |> Accumulator.parse emptyLatexState

        latexState2 =
            { emptyLatexState
                | crossReferences = latexState1.crossReferences
                , tableOfContents = latexState1.tableOfContents
                , dictionary = latexState1.dictionary
            }

        ( _, renderedParagraphs ) =
            latexExpressionList
                |> Accumulator.render renderer latexState2

        astList = List.map parser paragraphs

        idList =
            makeIdListWithSeed seed paragraphs

        sourceMap = SourceMap.generate (List.concat astList) idList
    in
    EditRecord paragraphs renderedParagraphs latexState2 astList idList sourceMap


makeIdList : List String -> List String
makeIdList paragraphs =
    List.range 1 (List.length paragraphs) |> List.map (Differ.prefixer 0)


makeIdListWithSeed : Int -> List String -> List String
makeIdListWithSeed seed paragraphs =
    List.range 1 (List.length paragraphs) |> List.map (Differ.prefixer seed)


update :
    Int
    -> (String -> List LatexExpression)
    -> (LatexState -> List LatexExpression -> a)
    -> (LatexState -> String -> a)
    -> EditRecord a
    -> String
    -> EditRecord a
update seed parser renderLatexExpression renderString editRecord source =
    -- ### LatexDiffer.update
    if Differ.isEmpty editRecord then
        init parser renderLatexExpression emptyLatexState source

    else
        source
            |> Differ.update seed parser (renderString editRecord.latexState) editRecord
