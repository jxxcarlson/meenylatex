module RenderSuite2 exposing (..)

import MeenyLatex.Parser exposing (..)
import MeenyLatex.Render2 exposing (..)
import Parser exposing (run)
import MeenyLatex.LatexState
    exposing
        ( LatexState
        , TocEntry
        , emptyLatexState
        , getCounter
        , getCrossReference
        , getDictionaryItem
        )
import MeenyLatex.ParserHelpers as PH
import MeenyLatex.Parser exposing (..)


getLatexList str =
    case run latexList str of
        Ok ll ->
            ll

        _ ->
            LatexList ([ LXString "Error!" ])


emptyLS =
    MeenyLatex.LatexState.emptyLatexState


renderTest latexExpr =
    render MeenyLatex.LatexState.emptyLatexState latexExpr


r1 =
    renderTest <| LXString "foo, bar"
