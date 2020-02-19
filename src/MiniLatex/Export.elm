module MiniLatex.Export exposing
    ( transform
    , toLaTeX
    )

{-| This module is for preparing latex for export.


# API

@docs transform

-}

-- import List.Extra

import Dict
import Internal.ErrorMessages2 as ErrorMessages
import Internal.Image as Image
import Internal.JoinStrings as JoinStrings
import Internal.Paragraph
import Internal.Parser exposing (LatexExpression(..), defaultLatexList, latexList)
import Internal.ParserTools as PT
import Internal.Source
import Internal.Utility as Utility
import Maybe.Extra
import String


table =
    """
\\begin{tabular}
A & B \\\\
C & D \\\\
\\end{tabular}
"""


toLaTeX : String -> String
toLaTeX str =
    let
        parsand =
            str
                |> Internal.Paragraph.logicalParagraphify
                |> List.map Internal.Parser.parse

        latex_ =
            parsand
                |> List.map renderLatexList
                |> List.foldl (\par acc -> acc ++ "\n\n" ++ par) ""
    in
    [ Internal.Source.texPrefix, latex_, Internal.Source.texSuffix ] |> String.join "\n\n"


{-| Parse a string and render it as a tuple,
where the first element is the string rendered
back into Latex, and where the second element is a list
of image urls.
-}
transform : String -> ( String, List String )
transform str =
    let
        parsand =
            str
                |> Internal.Paragraph.logicalParagraphify
                |> List.map Internal.Parser.parse

        latex =
            parsand
                |> List.map renderLatexList
                |> List.foldl (\par acc -> acc ++ "\n\n" ++ par) ""

        imageUrlList =
            parsand
                --|> List.concat
                |> List.map (PT.macroValue_ "image")
                |> Maybe.Extra.values
    in
    ( latex, imageUrlList )


foo str =
    str
        |> Internal.Paragraph.logicalParagraphify
        |> List.map Internal.Parser.parse


testString =
    """
This is a test.

\\image{http://foo.bar/yada.jpg}{Yada}{width: 400}

End of test.
"""


render : LatexExpression -> String
render latexExpression =
    case latexExpression of
        Comment str ->
            renderComment str

        Macro name optArgs args ->
            renderMacro name optArgs args

        SMacro name optArgs args le ->
            renderSMacro name optArgs args le

        Item level latexExpression_ ->
            renderItem level latexExpression_

        InlineMath str ->
            " $" ++ str ++ "$ "

        DisplayMath str ->
            "$$" ++ str ++ "$$"

        Environment name args body ->
            renderEnvironment name args body

        LatexList args ->
            renderLatexList args

        LXString str ->
            str

        NewCommand _ _ _ ->
            ""

        LXError error ->
            List.map ErrorMessages.renderError error |> String.join "; "


renderLatexList : List LatexExpression -> String
renderLatexList args =
    args |> List.map render |> JoinStrings.joinList


renderArgList : List LatexExpression -> String
renderArgList args =
    args
        |> List.map render
        |> List.map fixBadChars
        |> List.map (\x -> "{" ++ x ++ "}")
        |> String.join ""


renderCleanedArgList : List LatexExpression -> String
renderCleanedArgList args =
    args
        |> List.map render
        |> List.map fixBadChars
        |> List.map (\x -> "{" ++ x ++ "}")
        |> String.join ""


renderSpecialArgList : List LatexExpression -> String
renderSpecialArgList args =
    let
        head =
            List.head args

        tail =
            List.tail args

        renderedHead =
            Maybe.map render head

        renderedTail =
            Maybe.map renderCleanedArgList tail
    in
    case ( renderedHead, renderedTail ) of
        ( Just h, Just t ) ->
            "{" ++ h ++ "}" ++ t

        _ ->
            ""


fixBadChars : String -> String
fixBadChars str =
    str
        |> String.replace "_" "\\_"
        |> String.replace "#" "\\#"


renderOptArgList : List LatexExpression -> String
renderOptArgList args =
    args |> List.map render |> List.map (\x -> "[" ++ x ++ "]") |> String.join ""


renderItem : Int -> LatexExpression -> String
renderItem level latexExpression =
    "\\item " ++ render latexExpression ++ "\n\n"


renderComment : String -> String
renderComment str =
    "% " ++ str ++ "\n"


renderEnvironment : String -> List LatexExpression -> LatexExpression -> String
renderEnvironment name args body =
    case Dict.get name renderEnvironmentDict of
        Just f ->
            f args body

        Nothing ->
            renderDefaultEnvironment name args body


renderDefaultEnvironment : String -> List LatexExpression -> LatexExpression -> String
renderDefaultEnvironment name args body =
    let
        slimBody =
            String.trim <| render body
    in
    "\\begin{" ++ name ++ "}" ++ renderArgList args ++ "\n" ++ slimBody ++ "\n\\end{" ++ name ++ "}\n"


renderEnvironmentDict : Dict.Dict String (List LatexExpression -> LatexExpression -> String)
renderEnvironmentDict =
    Dict.fromList
        [ ( "listing", \args body -> renderListing body )
        , ( "useforweb", \args body -> renderUseForWeb body )
        , ( "thebibliography", \args body -> renderTheBibliography body )
        , ( "tabular", \args body -> renderTabular args body )
        ]


renderListing body =
    let
        text =
            render body
    in
    "\n\\begin{verbatim}\n" ++ Utility.addLineNumbers text ++ "\n\\end{verbatim}\n"


renderTheBibliography body =
    "\n\\begin{thebibliography}{abc}\n"
        ++ render body
        ++ "\n\\end{thebibliography}\n"


renderTabular args body =
    let
        format =
            renderArg 0 args
    in
    case body of
        LatexList rows ->
            rows
                |> List.map renderRow
                |> String.join "\n"
                |> (\x -> "\\begin{tabular}{" ++ format ++ "}\n" ++ x ++ "\n\\end{tabular}\n")

        _ ->
            "renderTabular: error"


renderRow : LatexExpression -> String
renderRow expr =
    case expr of
        LatexList cells ->
            cells
                |> List.map render
                |> String.join " & "
                |> (\x -> x ++ " \\\\")

        _ ->
            "renderRow: error"


renderUseForWeb body =
    ""


renderMacroDict : Dict.Dict String (List LatexExpression -> List LatexExpression -> String)
renderMacroDict =
    Dict.fromList
        [ ( "image", \x y -> renderImage y )
        , ( "code", \x y -> renderCode x y )
        , ( "href", \x y -> renderHref x y )
        , ( "mdash", \x y -> "---" )
        , ( "ndash", \x y -> "--" )
        , ( "setcounter", \x y -> renderSetCounter x y )
        ]


renderMacro : String -> List LatexExpression -> List LatexExpression -> String
renderMacro name optArgs args =
    macroRenderer name optArgs args


renderSMacro : String -> List LatexExpression -> List LatexExpression -> LatexExpression -> String
renderSMacro name optArgs args le =
    " \\" ++ name ++ renderOptArgList optArgs ++ renderArgList args ++ " " ++ render le ++ "\n\n"


macroRenderer : String -> (List LatexExpression -> List LatexExpression -> String)
macroRenderer name =
    case Dict.get name renderMacroDict of
        Just f ->
            f

        Nothing ->
            reproduceMacro name


renderCode : List LatexExpression -> List LatexExpression -> String
renderCode optArgs args =
    " \\code" ++ renderOptArgList optArgs ++ renderCleanedArgList args


renderHref : List LatexExpression -> List LatexExpression -> String
renderHref optArgs args =
    " \\href" ++ renderSpecialArgList args


renderSetCounter : List LatexExpression -> List LatexExpression -> String
renderSetCounter optArgs args =
    let
        argValue =
            PT.getDecrementedSetCounterArg args |> Maybe.withDefault "0"
    in
    " \\setcounter{section}" ++ "{" ++ argValue ++ "}"



-- \setcounter{section}{2}


reproduceMacro : String -> List LatexExpression -> List LatexExpression -> String
reproduceMacro name optArgs args =
    " \\" ++ name ++ renderOptArgList optArgs ++ renderArgList args


getExportUrl url =
    let
        parts =
            String.split "/" url

        n =
            List.length parts

        lastPart =
            parts |> List.drop (n - 1) |> List.head |> Maybe.withDefault "xxx"
    in
    "image/" ++ lastPart


renderImage : List LatexExpression -> String
renderImage args =
    let
        url =
            renderArg 0 args

        exportUrl =
            getExportUrl url

        label =
            renderArg 1 args

        attributeString =
            renderArg 2 args

        imageAttrs =
            Image.parseImageAttributes attributeString

        width_ =
            imageAttrs.width |> toFloat |> (\x -> 4.5 * x)

        width =
            String.fromFloat (3.0 * width_ / 1400.0) ++ "in"
    in
    case ( imageAttrs.float, imageAttrs.align ) of
        ( "left", _ ) ->
            imageFloatLeft exportUrl label width

        ( "right", _ ) ->
            imageFloatRight exportUrl label width

        ( _, "center" ) ->
            imageAlignCenter exportUrl label width

        ( _, _ ) ->
            imageAlignCenter exportUrl label width


imageFloatLeft exportUrl label width =
    "\\imagefloatleft{" ++ exportUrl ++ "}{" ++ label ++ "}{" ++ width ++ "}"


imageFloatRight exportUrl label width =
    "\\imagefloatright{" ++ exportUrl ++ "}{" ++ label ++ "}{" ++ width ++ "}"


imageAlignCenter exportUrl label width =
    "\\imagecenter{" ++ exportUrl ++ "}{" ++ label ++ "}{" ++ width ++ "}"


renderArg : Int -> List LatexExpression -> String
renderArg k args =
    render (getElement k args) |> String.trim


getElement : Int -> List LatexExpression -> LatexExpression
getElement k list =
    Utility.getAt k list |> Maybe.withDefault (LXString "xxx")
