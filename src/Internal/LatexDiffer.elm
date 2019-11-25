module Internal.LatexDiffer exposing (createRecord, createRecordWithSeed, update)

import Internal.Accumulator as Accumulator
import Internal.Differ as Differ exposing (EditRecord)
import Internal.LatexState exposing (LatexState, emptyLatexState)
import Internal.Paragraph as Paragraph
import Internal.Parser exposing (LatexExpression)
import MiniLatex.Render2 as Render exposing (render)


createRecord : (LatexState -> List LatexExpression -> a) -> LatexState -> String -> EditRecord a
createRecord renderer latexState text =
    createRecordWithSeed 0 renderer latexState text


createRecordWithSeed : Int -> (LatexState -> List LatexExpression -> a) -> LatexState -> String -> EditRecord a
createRecordWithSeed seed renderer latexState text =
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

        idList =
            makeIdListWithSeed seed paragraphs
    in
        EditRecord paragraphs renderedParagraphs latexState2 idList Nothing Nothing


makeIdList : List String -> List String
makeIdList paragraphs =
    List.range 1 (List.length paragraphs) |> List.map (Differ.prefixer 0)


makeIdListWithSeed : Int -> List String -> List String
makeIdListWithSeed seed paragraphs =
    List.range 1 (List.length paragraphs) |> List.map (Differ.prefixer seed)


update :
    Int
    -> (LatexState -> List LatexExpression -> a)
    -> (LatexState -> String -> a)
    -> EditRecord a
    -> String
    -> EditRecord a
update seed renderLatexExpression renderString editRecord content =
    -- ### LatexDiffer.update
    if Differ.isEmpty editRecord then
        createRecord renderLatexExpression emptyLatexState content
    else
        content
            |> Differ.update seed (renderString editRecord.latexState) editRecord
