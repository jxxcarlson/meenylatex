module RenderSuite exposing (..)

import MeenyLatex.Parser exposing (..)
import MeenyLatex.Render exposing (..)
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


{-

    renderItalic : LatexState -> List LatexExpression -> String
    renderItalic latexState args =
        " <span class=italic>" ++ renderArg 0 latexState args ++ "</span>"

    renderArg : Int -> LatexState -> List LatexExpression -> String
    renderArg k latexState args =
        render latexState (getElement k args) |> String.trim

   render : LatexState -> LatexExpression -> String
   render latexState latexExpression =
       case latexExpression of
           Comment str ->
               renderComment str

           Macro name optArgs args ->
               renderMacro latexState name optArgs args

           SMacro name optArgs args le ->
               renderSMacro latexState name optArgs args le

           Item level latexExpr ->
               renderItem latexState level latexExpr

           InlineMath str ->
               "$" ++ str ++ "$"

           DisplayMath str ->
               "$$" ++ str ++ "$$"

           Environment name args body ->
               renderEnvironment latexState name args body

           LatexList args -> -- ****** --
               renderLatexList latexState args

           LXString str ->
               str

           LXError error ->
               List.map ErrorMessages.renderError error |> String.join "; "


       renderLatexList : LatexState -> List LatexExpression -> String
       renderLatexList latexState args =
           args |> List.map (render latexState) |> JoinStrings.joinList |> postProcess


-}


getLatexList str =
    case run latexList str of
        Ok ll ->
            ll

        _ ->
            LatexList ([ LXString "Error!" ])


emptyLS =
    MeenyLatex.LatexState.emptyLatexState


me =
    Macro "\\italic" [] ([ LatexList ([ LXString "foo" ]) ])


args =
    [ LatexList ([ LXString "foo" ]) ]


x1 =
    renderArg 0 emptyLS args


x2 =
    renderMacro emptyLS "italic" [] [ LXString "foo" ]


renderTest str =
    renderString latexList MeenyLatex.LatexState.emptyLatexState str


r1 =
    renderTest "This is a test.\n\n\nAnd so is this."


r2 =
    renderTest "$a^2 = b^3$"


r3 =
    renderTest "$$a^2 = b^3$$"


r4 =
    renderTest "\\[a^2 = b^3\\]"


r5 =
    renderTest "% This is a comment\n"


r6 =
    renderTest "\\bozo{yada}"


renderSuite =
    [ r1, r2, r3, r4, r5, r6 ]
