module MeenyLatex.LatexDiffer exposing (createEditRecord, update)

import MeenyLatex.Accumulator as Accumulator
import MeenyLatex.Differ as Differ exposing (EditRecord)
import MeenyLatex.LatexState exposing (LatexState, emptyLatexState)
import MeenyLatex.Paragraph as Paragraph
import MeenyLatex.Render2 as Render exposing (render, renderLatexList)
import MeenyLatex.Parser exposing (LatexExpression)


createEditRecord : (LatexState -> List LatexExpression -> a) -> LatexState -> String -> EditRecord a
createEditRecord renderer latexState text =
    let
        paragraphs =
            text
                |> Paragraph.logicalParagraphify

        ( latexExpressionList, latexState1 ) =
            paragraphs
                |> Accumulator.parseParagraphs emptyLatexState

        latexState2 =
            { emptyLatexState
                | crossReferences = latexState1.crossReferences
                , tableOfContents = latexState1.tableOfContents
                , dictionary = latexState1.dictionary
            }

        ( renderedParagraphs, _ ) =
            latexExpressionList
                |> (Accumulator.renderParagraphs renderer) latexState2

        idList =
            makeIdList paragraphs
    in
        EditRecord paragraphs renderedParagraphs latexState2 idList Nothing Nothing


makeIdList : List String -> List String
makeIdList paragraphs =
    List.range 1 (List.length paragraphs) |> List.map (Differ.prefixer 0)


update_ : Int -> (LatexState -> String -> a) -> EditRecord a -> String -> EditRecord a
update_ seed renderer editorRecord text =
    text
        |> Differ.update seed (renderer editorRecord.latexState) editorRecord


update : Int -> (LatexState -> List LatexExpression -> a) -> (LatexState -> String -> a) -> EditRecord a -> String -> EditRecord a
update seed renderLatexExpression renderString editRecord content =
    if Differ.isEmpty editRecord then
        (createEditRecord renderLatexExpression) emptyLatexState content
    else
        update_ seed renderString editRecord content
