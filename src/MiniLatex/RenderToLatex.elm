module MiniLatex.RenderToLatex
    exposing
        ( render
        , renderBackToLatex
        , renderBackToLatexTest
        , renderBackToLatexTestModSpace
        , renderLatexList
        , renderString
        )

import List.Extra
import MiniLatex.JoinStrings as JoinStrings
import MiniLatex.Paragraph
import MiniLatex.Parser exposing (LatexExpression(..), defaultLatexList, latexList)
import Parser
import String.Extra


{-| parse a stringg and render it back into Latex
-}
renderBackToLatex : String -> String
renderBackToLatex str =
    str
        |> MiniLatex.Paragraph.logicalParagraphify
        |> List.map MiniLatex.Parser.parse
        |> List.map renderLatexList
        |> List.foldl (\par acc -> acc ++ par ++ "\n\n") ""


renderBackToLatexTest : String -> Bool
renderBackToLatexTest str =
    str == renderBackToLatex str


renderBackToLatexTestModSpace : String -> Bool
renderBackToLatexTestModSpace str =
    (str |> String.Extra.replace " " "") == (renderBackToLatex str |> String.Extra.replace " " "")


renderString parser str =
    let
        parserOutput =
            Parser.run parser str

        renderOutput =
            case parserOutput of
                Ok latexExpression ->
                    render latexExpression

                Err error ->
                    "Error: " ++ toString error
    in
    renderOutput


render : LatexExpression -> String
render latexExpression =
    case latexExpression of
        Comment str ->
            renderComment str

        Macro name args ->
            renderMacro name args

        Item level latexExpression ->
            renderItem level latexExpression

        InlineMath str ->
            "$" ++ str ++ "$"

        DisplayMath str ->
            "$$" ++ str ++ "$$"

        Environment name args ->
            renderEnvironment name args

        LatexList args ->
            renderLatexList args

        LXString str ->
            str


renderLatexList : List LatexExpression -> String
renderLatexList args =
    args |> List.map render |> JoinStrings.joinList


renderArgList : List LatexExpression -> String
renderArgList args =
    args |> List.map render |> List.map (\x -> "{" ++ x ++ "}") |> String.join ""


renderItem : Int -> LatexExpression -> String
renderItem level latexExpression =
    "\\item " ++ render latexExpression ++ "\n\n"


renderComment : String -> String
renderComment str =
    "% " ++ str ++ "\n"


renderEnvironment : String -> LatexExpression -> String
renderEnvironment name body =
    "\\begin{" ++ name ++ "}\n" ++ render body ++ "\n\\end{" ++ name ++ "}\n\n"


renderMacro : String -> List LatexExpression -> String
renderMacro name args =
    "\\" ++ name ++ renderArgList args
