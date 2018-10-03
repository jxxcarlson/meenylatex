module MiniLatex.LatexDiffer exposing (createEditRecord, update)

import MiniLatex.Accumulator as Accumulator
import MiniLatex.Differ as Differ exposing (EditRecord)
import MiniLatex.LatexState exposing (LatexState, emptyLatexState)
import MiniLatex.Paragraph as Paragraph
import MiniLatex.Parser exposing (LatexExpression)
import MiniLatex.Render2 as Render exposing (render)


createEditRecord : (LatexState -> List LatexExpression -> a) -> LatexState -> String -> EditRecord a
createEditRecord renderer latexState text =
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
            makeIdList paragraphs
    in
    EditRecord paragraphs renderedParagraphs latexState2 idList Nothing Nothing


makeIdList : List String -> List String
makeIdList paragraphs =
    List.range 1 (List.length paragraphs) |> List.map (Differ.prefixer 0)


update_ :
    Int
    -> (LatexState -> String -> a)
    -> EditRecord a
    -> String
    -> EditRecord a
update_ seed renderer editorRecord text =
    text
        |> Differ.update seed (renderer editorRecord.latexState) editorRecord


update :
    Int
    -> (LatexState -> List LatexExpression -> a)
    -> (LatexState -> String -> a)
    -> EditRecord a
    -> String
    -> EditRecord a
update seed renderLatexExpression renderString editRecord content =
    if Differ.isEmpty editRecord then
        createEditRecord renderLatexExpression emptyLatexState content

    else
        update_ seed renderString editRecord content
