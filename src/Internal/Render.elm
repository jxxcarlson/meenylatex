module Internal.Render exposing (makeTableOfContents, render, renderLatexList, renderLatexListToList, renderString)

{-| This module is for quickly preparing latex for export.


# API

@docs makeTableOfContents, render, renderLatexList, renderLatexListToList, renderString

-}

{-

COMMENTS
========

DICTIONARIES
------------

There are two dictionaries which are used
to render macros and environements, respectively.  These are

  - renderMacroDict
  - renderEnvironmentDict

In addition, there is latexState.mathMacroDictionary, which
is used for rendering math-mode macros that are defined at
runtime, that is, in the source text of a MiniLaTeX document.

Text-mode macros are handled by `Macro.expandMacro` inside of
`renderMacro`.  Thus it does not use a dictionary.


STRUCTURE
---------

The top level rendering function is `render`.
The SourceText = String argument is passed along
to aid in error reporting.


-}

import Dict
import Html exposing (Attribute, Html)
import Html.Attributes as HA
import Internal.ErrorMessages2 as ErrorMessages
import Internal.Image as Image exposing (..)
import Internal.LatexState
    exposing
        ( LatexState
        , TocEntry
        , emptyLatexState
        , getCounter
        , getCrossReference
        , getDictionaryItem
        )
import Internal.ListMachine as ListMachine
import Internal.Macro as Macro
import Internal.MathMacro
import Internal.Paragraph as Paragraph
import Internal.Parser exposing (LatexExpression(..), defaultLatexList, latexList)
import Internal.ParserHelpers
import Internal.RenderToString
import Internal.Utility as Utility
import Json.Encode
import Parser exposing (DeadEnd, Problem(..))
import Regex
import String
import SvgParser
import SyntaxHighlight as SH


type alias SourceText = String
type alias EnvName = String

{-| The main rendering function. Compute an Html msg value
from the current LatexState and a LatexExpression.
-}
render : SourceText -> LatexState -> LatexExpression -> Html msg
render source latexState latexExpression =
    case latexExpression of
        Comment str ->
            Html.p [] [ Html.text <| "" ]

        Macro name optArgs args ->
            renderMacro source latexState name optArgs args

        SMacro name optArgs args le ->
            renderSMacro source latexState name optArgs args le

        Item level latexExpr ->
            -- TODO: fix spacing issue
            renderItem source latexState level latexExpr

        InlineMath str ->
            Html.span [] [ oneSpace, inlineMathText latexState (Internal.MathMacro.evalStr latexState.mathMacroDictionary str) ]

        DisplayMath str ->
            -- TODO: fix Internal.MathMacro.evalStr.  It is nuking \begin{pmacro}, etc.
            displayMathText latexState (Internal.MathMacro.evalStr latexState.mathMacroDictionary str)

        Environment name args body ->
            renderEnvironment source latexState name args body

        LatexList latexList ->
            renderLatexList source latexState (spacify latexList)

        LXString str ->
            case String.left 1 str of
                " " ->
                    Html.span [ HA.style "margin-left" "1px" ] [ Html.text str ]

                _ ->
                    Html.span [] [ Html.text str ]

        NewCommand commandName numberOfArgs commandBody ->
            Html.span [] []

        LXError error ->
            let
                err =
                    ErrorMessages.renderErrors source error

                errorText =
                    Html.p [ HA.style "margin" "0" ] [ Html.text (String.join "\n" err.errorText ++ " ...") ]

                offset =
                    (String.fromInt <| 5 * err.markerOffset) ++ "px"
            in
            Html.div [ HA.style "font" "Courier", HA.style "font-family" "Mono", HA.style "font-size" "15px" ]
                [ Html.div [ HA.style "color" "blue", HA.style "margin" "0" ] [ errorText ]
                , Html.div [ HA.style "color" "blue", HA.style "margin-left" offset ] [ Html.text "^" ]
                , Html.p [ HA.style "color" "red", HA.style "margin" "0" ] [ Html.text err.explanation ]
                ]


{-| Like `render`, but renders a list of LatexExpressions
to Html mgs
-}
renderLatexList : SourceText -> LatexState -> List LatexExpression -> Html msg
renderLatexList source latexState latexList =
    latexList
        |> List.map (render source latexState)
        |> (\list -> Html.span [ HA.style "margin-bottom" "10px" ] list)


renderLatexListToList : LatexState -> List ( String, List LatexExpression ) -> List (Html msg)
renderLatexListToList latexState list =
    List.map2 (\x y -> renderLatexList x latexState y)
        (List.map Tuple.first list)
        (List.map Tuple.second list |> List.map spacify)



-- HELPERS, TESTING


getElement : Int -> List LatexExpression -> LatexExpression
getElement k list =
    Utility.getAt k list |> Maybe.withDefault (LXString "xxx")


parseString_ parser str =
    Parser.run parser str


parseString : LatexState -> SourceText -> List ( SourceText, List LatexExpression )
parseString _ source =
    let
        paragraphs : List SourceText
        paragraphs =
            Paragraph.logicalParagraphify source

        parse__ : SourceText -> ( SourceText, List LatexExpression )
        parse__ paragraph =
            ( paragraph, Internal.Parser.parse paragraph |> spacify )
    in
    paragraphs
        |> List.map parse__


{-| Parse a string, then render it. TODO: NOT USED?
-}
renderString2 : LatexState -> SourceText -> Html msg
renderString2 latexState source =
    let
        render_ : ( SourceText, List LatexExpression ) -> Html msg
        render_ ( source_, ast ) =
            renderLatexList source_ latexState ast
    in
    source
        |> parseString latexState
        |> List.map render_
        |> Html.div []


{-| Parse a string, then render it. USED EXTERNALLY:
-}
renderString : LatexState -> SourceText -> Html msg
renderString latexState source =
    let
        paragraphs : List SourceText
        paragraphs =
            Paragraph.logicalParagraphify source

        parse : String.String -> ( SourceText, List LatexExpression )
        parse paragraph =
            ( paragraph, Internal.Parser.parse paragraph |> spacify )

        render_ : ( SourceText, List LatexExpression ) -> Html msg
        render_ ( source_, ast ) =
            renderLatexList source_ latexState ast
    in
    paragraphs
        |> List.map parse
        |> List.map render_
        |> Html.div []


postProcess : String -> String
postProcess str =
    str
        |> String.replace "---" "&mdash;"
        |> String.replace "--" "&ndash;"
        |> String.replace "\\&" "&#38"



-- TYPES AND DEFAULT VALUES


extractList : LatexExpression -> List LatexExpression
extractList latexExpression =
    case latexExpression of
        LatexList a ->
            a

        _ ->
            []



-- MATH


mathText : DisplayMode -> String -> Html msg
mathText displayMode content =
    Html.node "math-text"
        [ HA.property "delay" (Json.Encode.bool False)
        , HA.property "display" (Json.Encode.bool (isDisplayMathMode displayMode))
        , HA.property "content" (Json.Encode.string (content  |> String.replace "\\ \\" "\\\\"))
        --, HA.property "content" (Json.Encode.string content |> String.replace "\\ \\" "\\\\"))
        ]
        []

mathJaxText : DisplayMode -> String -> Html msg
mathJaxText displayMode content =
    Html.node "mathjax-text"
        [ HA.property "display" (Json.Encode.bool True)
        , HA.property "content" (Json.Encode.string (content  |> String.replace "\\ \\" "\\\\"))
        ]
        []

type DisplayMode
    = InlineMathMode
    | DisplayMathMode


isDisplayMathMode : DisplayMode -> Bool
isDisplayMathMode displayMode =
    case displayMode of
        InlineMathMode ->
            False

        DisplayMathMode ->
            True



-- MATH


inlineMathText : LatexState -> String -> Html msg
inlineMathText latexState str_ =
    let
        str =
            Internal.MathMacro.evalStr latexState.mathMacroDictionary str_
    in
    mathText InlineMathMode (String.trim str)


displayMathText : LatexState -> String -> Html msg
displayMathText latexState str_ =
    let
        str =
            Internal.MathMacro.evalStr latexState.mathMacroDictionary str_
    in
    mathText DisplayMathMode (String.trim str)


displayMathText_ : LatexState -> String -> Html msg
displayMathText_ latexState str =
    mathText DisplayMathMode (String.trim str)


displayMathTextWithLabel_ : LatexState -> String -> String -> Html msg
displayMathTextWithLabel_ latexState str label =
    Html.div
        []
        [ Html.div [ HA.style "float" "right", HA.style "margin-top" "3px" ]
            [ Html.text label ]
        , Html.div []
            [ mathText DisplayMathMode (String.trim str) ]
        ]

displayMathJaxTextWithLabel_ : LatexState -> String -> String -> Html msg
displayMathJaxTextWithLabel_ latexState str label =
    Html.div
        []
        [ Html.div [ HA.style "float" "right", HA.style "margin-top" "3px" ]
            [ Html.text label ]
        , Html.div []
            -- [ Html.text "MathJax"]
            [ mathJaxText DisplayMathMode (String.trim str) ]
        ]



-- ERRORS


errorReport : DeadEnd -> String
errorReport deadEnd =
    -- "Error at row " ++ String.fromInt deadEnd.row ++ ", column " ++ String.fromInt deadEnd.col ++ "\n: " ++ (reportProblem deadEnd.problem)
    reportProblem deadEnd.problem


reportProblem : Problem -> String
reportProblem problem =
    case problem of
        Expecting str ->
            "Expecting string: " ++ str

        ExpectingInt ->
            "Expecting int"

        ExpectingSymbol str ->
            "Expecting symbol: " ++ str

        ExpectingKeyword str ->
            "Expecting keyword: " ++ str

        ExpectingEnd ->
            "Expecting end"

        UnexpectedChar ->
            "Unexpected char"

        BadRepeat ->
            "Bad repeat"

        _ ->
            "Other problem"



-- PROCESS FOR SPACES, SPACIFY


addSpace : ListMachine.State LatexExpression -> LatexExpression
addSpace internalState =
    let
        a =
            internalState.before |> Maybe.withDefault (LXString "")

        b =
            internalState.current |> Maybe.withDefault (LXString "")

        c =
            internalState.after |> Maybe.withDefault (LXString "")
    in
    case ( a, b, c ) of
        ( Macro _ _ _, LXString str, _ ) ->
            if List.member (firstChar str) [ ".", ",", "?", "!", ";", ":" ] then
                LXString str

            else
                LXString (" " ++ str)

        ( InlineMath _, LXString str, _ ) ->
            if List.member (firstChar str) [ "-", ".", ",", "?", "!", ";", ":" ] then
                LXString str

            else
                LXString (" " ++ str)

        ( _, LXString str, _ ) ->
            if List.member (lastChar str) [ ")", ".", ",", "?", "!", ";", ":" ] then
                LXString (str ++ " ")

            else
                LXString str

        ( _, _, _ ) ->
            b


lastChar =
    String.right 1


firstChar =
    String.left 1



--


spacify : List LatexExpression -> List LatexExpression
spacify latexList =
    latexList
        |> ListMachine.run addSpace



-- RENDER MACRO


renderMacro : String -> LatexState -> String -> List LatexExpression -> List LatexExpression -> Html msg
renderMacro source latexState name optArgs args =
    case Dict.get name renderMacroDict of
        Just f ->
            f source latexState optArgs args

        Nothing ->
            case Dict.get name latexState.macroDictionary of
                Nothing ->
                    reproduceMacro source name latexState optArgs args

                Just macroDefinition ->
                    let
                        macro =
                            Macro name optArgs args

                        expr =
                            Macro.expandMacro macro macroDefinition
                    in
                    render source latexState expr


renderArg : String -> Int -> LatexState -> List LatexExpression -> Html msg
renderArg source k latexState args =
    render source latexState (getElement k args)


reproduceMacro : String -> String -> LatexState -> List LatexExpression -> List LatexExpression -> Html msg
reproduceMacro source name latexState optArgs args =
    let
        renderedArgs =
            renderArgList source latexState args |> List.map enclose
    in
    Html.span [ HA.style "color" "red" ]
        ([ Html.text <| "\\" ++ name ] ++ renderedArgs)


boost : (x -> z -> output) -> (x -> y -> z -> output)
boost f =
    \x y z -> f x z



-- MACRO DICTIONARY


renderMacroDict : Dict.Dict String (String -> LatexState -> List LatexExpression -> List LatexExpression -> Html.Html msg)
renderMacroDict =
    Dict.fromList
        [ ( "bigskip", \s x y z -> renderBigSkip s x z )
        , ( "medskip", \s x y z -> renderMedSkip s x z )
        , ( "smallskip", \s x y z -> renderSmallSkip s x z )
        , ( "cite", \s x y z -> renderCite s x z )
        , ( "dollar", \s x y z -> renderDollar s x z )
        , ( "texbegin", \s x y z -> renderBegin s x z )
        , ( "texend", \s x y z -> renderEnd s x z )
        , ( "percent", \s x y z -> renderPercent s x z )
        , ( "code", \s x y z -> renderCode s x z )
        , ( "ellie", \s x y z -> renderEllie s x z )
        , ( "emph", \s x y z -> renderItalic s x z )
        , ( "eqref", \s x y z -> renderEqRef s x z )
        , ( "href", \s x y z -> renderHRef s x z )
        , ( "iframe", \s x y z -> renderIFrame s x z )
        , ( "image", \s x y z -> renderImage s x z )
        , ( "imageref", \s x y z -> renderImageRef s x z )
        , ( "index", \s x y z -> renderIndex s x z )
        , ( "italic", \s x y z -> renderItalic s x z )
        , ( "label", \s x y z -> renderLabel s x z )
        , ( "maintableofcontents", \s x y z -> renderMainTableOfContents s x z )
        , ( "maketitle", \s x y z -> renderMakeTitle s x z )
        , ( "mdash", \s x y z -> renderMdash s x z )
        , ( "ndash", \s x y z -> renderNdash s x z )
        , ( "underscore", \s x y z -> renderUnderscore s x z )
        , ( "bs", \s x y z -> renderBackslash s x z )
        , ( "texarg", \s x y z -> renderTexArg s x z )
        , ( "ref", \s x y z -> renderRef s x z )
        , ( "medskip", \s x y z -> renderMedSkip s x z )
        , ( "par", \s x y z -> renderMedSkip s x z)
        , ( "smallskip", \s x y z -> renderSmallSkip s x z )
        , ( "section", \s x y z -> renderSection s x z )
        , ( "section*", \s x y z -> renderSectionStar s x z )
        , ( "subsection", \s x y z -> renderSubsection s x z )
        , ( "subsection*", \s x y z -> renderSubsectionStar s x z )
        , ( "subsubsection", \s x y z -> renderSubSubsection s x z )
        , ( "subsubsection*", \s x y z -> renderSubSubsectionStar s x z )
        , ( "setcounter", \s x y z -> renderSetCounter s x z )
        , ( "subheading", \s x y z -> renderSubheading s x z )
        , ( "tableofcontents", \s x y z -> renderTableOfContents s x z )
        , ( "innertableofcontents", \s x y z -> renderInnerTableOfContents s x z )
        , ( "red", \s x y z -> renderRed s x z )
        , ( "blue", \s x y z -> renderBlue s x z )
        , ( "remote", \s x y z -> renderRemote s x z )
        , ( "local", \s x y z -> renderLocal s x z )
        , ( "note", \s x y z -> renderAttachNote s x z )
        , ( "highlight", \s x y z -> renderHighlighted s x z )
        , ( "strike", \s x y z -> renderStrikeThrough s x z )
        , ( "term", \s x y z -> renderTerm s x z )
        , ( "xlink", \s x y z -> renderXLink s x z )
        , ( "ilink1", \s x y z -> renderILink s x z )
        , ( "ilink2", \s x y z -> renderILink s x z )
        , ( "ilink3", \s x y z -> renderILink s x z )
        , ( "include", \s x y z -> renderInclude s x z )
        , ( "publiclink", \s x y z -> renderPublicLink s x z )
        , ( "documentTitle", \s x y z -> renderDocumentTitle s x z )
        , ( "title", \s x y z -> renderTitle x z )
        , ( "author", \s x y z -> renderAuthor s x z )
        , ( "date", \s x y z -> renderDate s x z )
        , ( "revision", \s x y z -> renderRevision s x z )
        , ( "email", \s x y z -> renderEmail s x z )
        , ( "setdocid", \s x y z -> renderSetDocId s x z )
        , ( "setclient", \s x y z -> renderSetClient s x z )
        , ( "strong", \s x y z -> renderStrong s x z )
        , ( "textbf", \s x y z -> renderStrong s x z )
        , ( "uuid", \s x y z -> renderUuid s x z )
        ]


renderDollar : String -> LatexState -> List LatexExpression -> Html msg
renderDollar _ atexState args =
    Html.span [] [ Html.text "$" ]


renderBegin : String -> LatexState -> List LatexExpression -> Html msg
renderBegin _ latexState args =
    Html.span [] [ Html.text "\\begin" ]


renderEnd : String -> LatexState -> List LatexExpression -> Html msg
renderEnd _ atexState args =
    Html.span [] [ Html.text "\\end" ]


renderUuid : String -> LatexState -> List LatexExpression -> Html msg
renderUuid _ _ _ =
    Html.span [] []


renderPercent : String -> LatexState -> List LatexExpression -> Html msg
renderPercent _ latexState args =
    Html.span [] [ Html.text "%" ]


renderArgList : String -> LatexState -> List LatexExpression -> List (Html msg)
renderArgList source latexState args =
    args |> List.map (render source latexState)


enclose : Html msg -> Html msg
enclose msg =
    Html.span [] [ Html.text "{", msg, Html.text "}" ]


oneSpace : Html msg
oneSpace =
    Html.text " "



-- RENDER INDIVIUAL MACROS


renderBozo : String -> LatexState -> List LatexExpression -> Html msg
renderBozo source latexState args =
    Html.span []
        [ Html.text <| "\\bozo"
        , enclose <| renderArg source 0 latexState args
        , enclose <| renderArg source 1 latexState args
        ]


renderItalic : String -> LatexState -> List LatexExpression -> Html msg
renderItalic source latexState args =
    Html.i [] [ Html.text " ", renderArg source 0 latexState args ]


renderStrong : String -> LatexState -> List LatexExpression -> Html msg
renderStrong source latexState args =
    Html.strong [] [ oneSpace, renderArg source 0 latexState args ]


renderBigSkip : String -> LatexState -> List LatexExpression -> Html msg
renderBigSkip _ latexState args =
    Html.div [ HA.style "height" "40px" ] []


renderMedSkip : String -> LatexState -> List LatexExpression -> Html msg
renderMedSkip _ latexState args =
    Html.div [ HA.style "height" "10px" ] []


renderSmallSkip : String -> LatexState -> List LatexExpression -> Html msg
renderSmallSkip _ latexState args =
    Html.div [ HA.style "height" "0px" ] []


renderCite : String -> LatexState -> List LatexExpression -> Html msg
renderCite _ latexState args =
    let
        label_ =
            Internal.RenderToString.renderArg 0 latexState args

        ref =
            getDictionaryItem ("bibitem:" ++ label_) latexState

        label =
            if ref /= "" then
                ref

            else
                label_
    in
    Html.strong []
        [ Html.span [] [ Html.text "[" ]
        , Html.a [ HA.href ("#bibitem:" ++ label) ] [ Html.text label ]
        , Html.span [] [ Html.text "] " ]
        ]


renderCode : String -> LatexState -> List LatexExpression -> Html msg
renderCode source latexState args =
    let
        arg =
            renderArg source 0 latexState args
    in
    Html.code [] [ oneSpace, arg ]


renderEllie : String -> LatexState -> List LatexExpression -> Html msg
renderEllie _ latexState args =
    let
        id =
            Internal.RenderToString.renderArg 0 latexState args

        url =
            "https://ellie-app.com/embed/" ++ id

        title_ =
            Internal.RenderToString.renderArg 1 latexState args

        title =
            if title_ == "xxx" then
                "Link to Ellie"

            else
                title_
    in
    Html.iframe [ HA.src url, HA.width 500, HA.height 600 ] [ Html.text title ]


renderIFrame : String -> LatexState -> List LatexExpression -> Html msg
renderIFrame _ latexState args =
    let
        url =
            Internal.RenderToString.renderArg 0 latexState args

        title =
            Internal.RenderToString.renderArg 1 latexState args
    in
    Html.iframe
        [ HA.src url
        , HA.width 400
        , HA.height 500
        , HA.attribute "Content-Type" "application/pdf"
        , HA.attribute "Content-Disposition" "inline"
        ]
        [ Html.text title ]


renderEqRef : String -> LatexState -> List LatexExpression -> Html msg
renderEqRef source latexState args =
    let
        key =
            Internal.RenderToString.renderArg 0 emptyLatexState args

        ref =
            getCrossReference key latexState
    in
    Html.i [] [ Html.text "(", Html.text ref, Html.text ")" ]


renderHRef : String -> LatexState -> List LatexExpression -> Html msg
renderHRef source latexState args =
    let
        url =
            Internal.RenderToString.renderArg 0 emptyLatexState args

        label =
            Internal.RenderToString.renderArg 1 emptyLatexState args
    in
    Html.a [ HA.href url, HA.target "_blank" ] [ Html.text label ]



-- RENDER IMAGE


renderImage : String -> LatexState -> List LatexExpression -> Html msg
renderImage source latexState args =
    let
        url =
            Internal.RenderToString.renderArg 0 latexState args

        label =
            Internal.RenderToString.renderArg 1 latexState args

        attributeString =
            Internal.RenderToString.renderArg 2 latexState args

        imageAttrs =
            parseImageAttributes attributeString

        width =
            String.fromInt imageAttrs.width ++ "px"
    in
    if imageAttrs.float == "left" then
        Html.div [ HA.style "float" "left" ]
            [ Html.img [ HA.src url, HA.alt label, HA.style "width" width, HA.style "margin-right" "12px" ] []
            , Html.br [] []
            , Html.div [ HA.style "width" width, HA.style "text-align" "center", HA.style "display" "block" ] [ Html.text label ]
            ]

    else if imageAttrs.float == "right" then
        Html.div [ HA.style "float" "right" ]
            [ Html.img [ HA.src url, HA.alt label, HA.style "width" width, HA.style "margin-left" "12px" ] []
            , Html.br [] []
            , Html.div [ HA.style "width" width, HA.style "text-align" "center", HA.style "display" "block" ] [ Html.text label ]
            ]

    else if imageAttrs.align == "center" then
        Html.div [ HA.style "margin-left" "auto", HA.style "margin-right" "auto", HA.style "width" width ]
            [ Html.img [ HA.src url, HA.alt label, HA.style "width" width ] []
            , Html.br [] []
            , Html.div [ HA.style "width" width, HA.style "text-align" "center", HA.style "display" "block" ] [ Html.text label ]
            ]

    else
        Html.div [ HA.style "margin-left" "auto", HA.style "margin-right" "auto", HA.style "width" width ]
            [ Html.img [ HA.src url, HA.alt label, HA.style "width" width ] []
            , Html.br [] []
            , Html.div [ HA.style "width" width, HA.style "text-align" "center", HA.style "display" "block" ] [ Html.text label ]
            ]


renderImageRef : String -> LatexState -> List LatexExpression -> Html msg
renderImageRef source latexState args =
    let
        url =
            Internal.RenderToString.renderArg 0 latexState args

        imageUrl =
            Internal.RenderToString.renderArg 1 latexState args

        attributeString =
            Internal.RenderToString.renderArg 2 latexState args

        imageAttrs =
            parseImageAttributes attributeString

        width =
            String.fromInt imageAttrs.width ++ "px"

        theImage =
            if imageAttrs.float == "left" then
                Html.div [ HA.style "float" "left" ]
                    [ Html.img [ HA.src imageUrl, HA.alt "image link", HA.style "width" width, HA.style "margin-right" "12px" ] []
                    , Html.br [] []
                    , Html.div [ HA.style "width" width, HA.style "text-align" "center", HA.style "display" "block" ] []
                    ]

            else if imageAttrs.float == "right" then
                Html.div [ HA.style "float" "right" ]
                    [ Html.img [ HA.src imageUrl, HA.alt "image link", HA.style "width" width, HA.style "margin-left" "12px" ] []
                    , Html.br [] []
                    , Html.div [ HA.style "width" width, HA.style "text-align" "center", HA.style "display" "block" ] []
                    ]

            else if imageAttrs.align == "center" then
                Html.div [ HA.style "margin-left" "auto", HA.style "margin-right" "auto", HA.style "width" width ]
                    [ Html.img [ HA.src imageUrl, HA.alt "image link", HA.style "width" width ] []
                    , Html.br [] []
                    , Html.div [ HA.style "width" width, HA.style "text-align" "center", HA.style "display" "block" ] []
                    ]

            else
                Html.div [ HA.style "margin-left" "auto", HA.style "margin-right" "auto", HA.style "width" width ]
                    [ Html.img [ HA.src imageUrl, HA.alt "image link", HA.style "width" width ] []
                    , Html.br [] []
                    , Html.div [ HA.style "width" width, HA.style "text-align" "center", HA.style "display" "block" ] []
                    ]
    in
    Html.a [ HA.href url ] [ theImage ]


renderIndex : String -> LatexState -> List LatexExpression -> Html msg
renderIndex source x z =
    Html.span [] []


renderLabel : String -> LatexState -> List LatexExpression -> Html msg
renderLabel source x z =
    Html.span [] []



-- TABLE OF CONTENTS


renderTableOfContents : String -> LatexState -> List LatexExpression -> Html msg
renderTableOfContents _ latexState list =
    let
        innerPart =
            makeTableOfContents latexState
    in
    Html.div []
        [ Html.h3 [] [ Html.text "Table of Contents" ]
        , Html.ul [] innerPart
        ]


renderInnerTableOfContents : String -> LatexState -> List LatexExpression -> Html msg
renderInnerTableOfContents _ latexState args =
    let
        s1 =
            getCounter "s1" latexState

        prefix =
            String.fromInt s1 ++ "."

        innerPart =
            makeInnerTableOfContents prefix latexState
    in
    Html.div []
        [ Html.h3 [] [ Html.text "Table of Contents" ]
        , Html.ul [] innerPart
        ]


{-| Build a table of contents from the
current LatexState; use only level 1 items
-}
makeTableOfContents : LatexState -> List (Html msg)
makeTableOfContents latexState =
    let
        toc =
            List.filter (\item -> item.level == 1) latexState.tableOfContents
    in
    List.foldl (\tocItem acc -> acc ++ [ makeTocItem "" tocItem ]) [] (List.indexedMap Tuple.pair toc)


{-| Build a table of contents from the
current LatexState; use only level 2 items
-}
makeInnerTableOfContents : String -> LatexState -> List (Html msg)
makeInnerTableOfContents prefix latexState =
    let
        toc =
            List.filter (\item -> item.level == 2) latexState.tableOfContents
    in
    List.foldl (\tocItem acc -> acc ++ [ makeTocItem prefix tocItem ]) [] (List.indexedMap Tuple.pair toc)


makeTocItem : String -> ( Int, TocEntry ) -> Html msg
makeTocItem prefix tocItem =
    let
        i =
            Tuple.first tocItem

        ti =
            Tuple.second tocItem

        number =
            prefix ++ String.fromInt (i + 1) ++ ". "

        classProperty =
            "class=\"sectionLevel" ++ String.fromInt ti.level ++ "\""

        id =
            makeId (sectionPrefix ti.level) ti.name

        href =
            "#" ++ id
    in
    Html.p
        [ HA.style "font-size" "14px"
        , HA.style "padding-bottom" "0px"
        , HA.style "margin-bottom" "0px"
        , HA.style "padding-top" "0px"
        , HA.style "margin-top" "0px"
        , HA.style "line-height" "20px"
        ]
        [ Html.text number
        , Html.a [ HA.href href ] [ Html.text ti.name ]
        ]


makeId : String -> String -> String
makeId prefix name =
    String.join "_" [ "", prefix, compress "_" name ]


compress : String -> String -> String
compress replaceBlank str =
    str
        |> String.toLower
        |> String.replace " " replaceBlank
        |> userReplace "[,;.!?&_]" (\_ -> "")


userReplace : String -> (Regex.Match -> String) -> String -> String
userReplace userRegex replacer string =
    case Regex.fromString userRegex of
        Nothing ->
            string

        Just regex ->
            Regex.replace regex replacer string


sectionPrefix : Int -> String
sectionPrefix level =
    case level of
        1 ->
            "section"

        2 ->
            "subsection"

        3 ->
            "subsubsection"

        _ ->
            "asection"



-- RENDER MACRO


renderMdash : String -> LatexState -> List LatexExpression -> Html msg
renderMdash source latexState args =
    Html.span [] [ Html.text "— " ]


renderNdash : String -> LatexState -> List LatexExpression -> Html msg
renderNdash source latexState args =
    Html.span [] [ Html.text "– " ]


renderUnderscore : String -> LatexState -> List LatexExpression -> Html msg
renderUnderscore source latexState args =
    Html.span [] [ Html.text "_" ]


renderBackslash : String -> LatexState -> List LatexExpression -> Html msg
renderBackslash source latexState args =
    Html.span [] [ Html.text "\\", renderArg source 0 latexState args ]


renderTexArg : String -> LatexState -> List LatexExpression -> Html msg
renderTexArg source latexState args =
    Html.span [] [ Html.text "{", renderArg source 0 latexState args, Html.text "}" ]


renderRef : String -> LatexState -> List LatexExpression -> Html msg
renderRef source latexState args =
    let
        key =
            Internal.RenderToString.renderArg 0 latexState args
    in
    Html.span [] [ Html.text <| getCrossReference key latexState ]


docUrl : LatexState -> String
docUrl latexState =
    let
        client =
            getDictionaryItem "setclient" latexState

        docId =
            getDictionaryItem "setdocid" latexState
    in
    client ++ "/" ++ docId


idPhrase : String -> String -> String
idPhrase prefix name =
    let
        compressedName =
            name |> String.toLower |> String.replace " " "_"
    in
    makeId prefix name


renderSection : String -> LatexState -> List LatexExpression -> Html msg
renderSection source latexState args =
    let
        renderedArgs : List (Html msg)
        renderedArgs = renderArgList source latexState args

        s1 =
            getCounter "s1" latexState

        label =
            if s1 > 0 then
                String.fromInt s1 ++ " "

            else
                ""

        ref =
            idPhrase "section" (Internal.RenderToString.renderArg 0 latexState args)
    in
    Html.h2 (headingStyle ref 24) ((Html.text label):: renderedArgs)



headingStyle ref h =
    [ HA.id ref
    , HA.style "margin-top" (String.fromFloat h ++ "px")
    , HA.style "margin-bottom" (String.fromFloat (0.0 * h) ++ "px")
    ]


renderSectionStar : String -> LatexState -> List LatexExpression -> Html msg
renderSectionStar source latexState args =
    let
        renderedArgs = renderArgList source latexState args


        ref =
            idPhrase "section" (Internal.RenderToString.renderArg 0 latexState args)
    in
    Html.h2 (headingStyle ref 24) renderedArgs


renderSubsection : String -> LatexState -> List LatexExpression -> Html msg
renderSubsection source latexState args =
    let
        renderedArgs = renderArgList source latexState args

        s1 =
            getCounter "s1" latexState

        s2 =
            getCounter "s2" latexState

        label =
            if s1 > 0 then
                String.fromInt s1 ++ "." ++ String.fromInt s2 ++ " "

            else
                ""

        ref =
            idPhrase "subsection" (Internal.RenderToString.renderArg 0 latexState args)
    in
    Html.h3 (headingStyle ref 12) ((Html.text label)::renderedArgs)


renderSubsectionStar : String -> LatexState -> List LatexExpression -> Html msg
renderSubsectionStar source latexState args =
    let
        renderedArgs = renderArgList source latexState args

        ref =
            idPhrase "subsection" (Internal.RenderToString.renderArg 0 latexState args)
    in
    Html.h3 (headingStyle ref 12) renderedArgs


renderSubSubsection : String -> LatexState -> List LatexExpression -> Html msg
renderSubSubsection source latexState args =
    let
        renderedArgs = renderArgList source latexState args

        s1 =
            getCounter "s1" latexState

        s2 =
            getCounter "s2" latexState

        s3 =
            getCounter "s3" latexState

        label =
            if s1 > 0 then
                String.fromInt s1 ++ "." ++ String.fromInt s2 ++ "." ++ String.fromInt s3 ++ " "

            else
                ""

        ref =
            idPhrase "subsubsection" (Internal.RenderToString.renderArg 0 latexState args)
    in
    Html.h4 [ HA.id ref ] ((Html.text label)::renderedArgs)


renderSubSubsectionStar : String -> LatexState -> List LatexExpression -> Html msg
renderSubSubsectionStar source latexState args =
    let
        renderedArgs = renderArgList source latexState args

        ref =
            idPhrase "subsubsection" (Internal.RenderToString.renderArg 0 latexState args)
    in
    Html.h4 [ HA.id ref ] renderedArgs

renderSubheading : String -> LatexState -> List LatexExpression -> Html msg
renderSubheading source latexState args =
    let
        renderedArgs = renderArgList source latexState args

        ref =
            idPhrase "subsubsection" (Internal.RenderToString.renderArg 0 latexState args)
    in
    Html.p [ HA.style "font-weight" "bold", HA.style "margin-bottom" "0", HA.style "margin-left" "-2px", HA.id ref ] renderedArgs


renderDocumentTitle : String -> LatexState -> List LatexExpression -> Html msg
renderDocumentTitle _ latexState list =
    let
        title =
            getDictionaryItem "title" latexState

        author =
            getDictionaryItem "author" latexState

        date =
            getDictionaryItem "date" latexState

        email =
            getDictionaryItem "email" latexState

        revision =
            getDictionaryItem "revision" latexState

        revisionText =
            if revision /= "" then
                "Last revised " ++ revision

            else
                ""

        titlePart =
            Html.div [ HA.class "title" ] [ Html.text title ]

        bodyParts =
            [ author, email, date, revisionText ]
                |> List.filter (\x -> x /= "")
                |> List.map (\x -> Html.li [] [ Html.text x ])

        bodyPart =
            Html.ul [] bodyParts
    in
    Html.div [] [ titlePart, bodyPart ]


renderSetCounter : String -> LatexState -> List LatexExpression -> Html msg
renderSetCounter _ latexState list =
    Html.span [] []




renderMakeTitle : String -> LatexState -> List LatexExpression -> Html msg
renderMakeTitle source latexState list =
    let
        title =
            getDictionaryItem "title" latexState

        author =
            getDictionaryItem "author" latexState

        date =
            getDictionaryItem "date" latexState

        email =
            getDictionaryItem "email" latexState

        revision =
            getDictionaryItem "revision" latexState

        revisionText =
            if revision /= "" then
                "Last revised " ++ revision

            else
                ""

        titlePart =
            Html.div [ HA.style "font-size" "28px", HA.style "padding-bottom" "12px" ] [ Html.text <| title ]

        authorPart =
            Html.div [ HA.style "font-size" "18px", HA.style "padding-bottom" "4px" ] [ Html.text <| author ]

        bodyParts =
            [ date, revisionText, email ]
                |> List.filter (\x -> x /= "")
                |> List.map (\x -> Html.div [ HA.style "font-size" "14px" ] [ Html.text x ])
    in
    Html.div []
        (titlePart :: authorPart :: bodyParts)


renderTitle : LatexState -> List LatexExpression -> Html msg
renderTitle latexState args =
    Html.span [] []


renderAuthor : String -> LatexState -> List LatexExpression -> Html msg
renderAuthor _ latexState args =
    Html.span [] []


renderSetDocId : String -> LatexState -> List LatexExpression -> Html msg
renderSetDocId _ latexState args =
    Html.span [] []


renderSetClient : String -> LatexState -> List LatexExpression -> Html msg
renderSetClient _ latexState args =
    Html.span [] []


renderDate : String -> LatexState -> List LatexExpression -> Html msg
renderDate _ latexState args =
    Html.span [] []


renderRevision : String -> LatexState -> List LatexExpression -> Html msg
renderRevision _ latexState args =
    Html.span [] []


renderMainTableOfContents : String -> LatexState -> List LatexExpression -> Html msg
renderMainTableOfContents source latexState args =
    Html.span [] []


renderEmail : String -> LatexState -> List LatexExpression -> Html msg
renderEmail _ latexState args =
    Html.span [] []


renderRed : String -> LatexState -> List LatexExpression -> Html msg
renderRed _ latexState args =
    let
        arg =
            Internal.RenderToString.renderArg 0 latexState args
    in
    Html.span [ HA.style "color" "red" ] [ Html.text <| arg ]


renderBlue : String -> LatexState -> List LatexExpression -> Html msg
renderBlue _ latexState args =
    let
        arg =
            Internal.RenderToString.renderArg 0 latexState args
    in
    Html.span [ HA.style "color" "blue" ] [ Html.text <| arg ]


renderRemote : String -> LatexState -> List LatexExpression -> Html msg
renderRemote _ latexState args =
    let
        arg =
            Internal.RenderToString.renderArg 0 latexState args
    in
    Html.div [ HA.style "color" "red", HA.style "white-space" "pre" ] [ Html.text <| arg ]


renderLocal : String -> LatexState -> List LatexExpression -> Html msg
renderLocal _ latexState args =
    let
        arg =
            Internal.RenderToString.renderArg 0 latexState args
    in
    Html.div [ HA.style "color" "blue", HA.style "white-space" "pre" ] [ Html.text <| arg ]


renderAttachNote : String -> LatexState -> List LatexExpression -> Html msg
renderAttachNote _ latexState args =
    -- TODO: Finish this
    let
        author =
            Internal.RenderToString.renderArg 0 latexState args

        content =
            Internal.RenderToString.renderArg 1 latexState args
    in
    Html.div
        [ HA.style "display" "flex"
        , HA.style "flex-direction" "column"
        ]
        [ Html.div [ HA.style "color" "blue" ] [ Html.text <| author ]
        , Html.div [ HA.style "background-color" "yellow" ] [ Html.text <| content ]
        ]


renderHighlighted : String -> LatexState -> List LatexExpression -> Html msg
renderHighlighted _ latexState args =
    let
        arg =
            Internal.RenderToString.renderArg 0 latexState args
    in
    Html.span [ HA.style "background-color" "yellow" ] [ Html.text <| arg ]


renderStrikeThrough : String -> LatexState -> List LatexExpression -> Html msg
renderStrikeThrough _ latexState args =
    let
        arg =
            Internal.RenderToString.renderArg 0 latexState args
    in
    Html.span [ HA.style "text-decoration" "line-through" ] [ Html.text <| arg ]


renderTerm : String -> LatexState -> List LatexExpression -> Html msg
renderTerm _ latexState args =
    let
        arg =
            Internal.RenderToString.renderArg 0 latexState args
    in
    Html.i [] [ Html.text <| arg ]


renderXLink : String -> LatexState -> List LatexExpression -> Html msg
renderXLink _ latexState args =
    -- REVIEW: CHANGED  ref to from ++ "/" ++ to +++ "/u/" ++ for lamdera app
    let
        id =
            Internal.RenderToString.renderArg 0 latexState args

        ref =
            getDictionaryItem "setclient" latexState ++ "/" ++ id

        label =
            Internal.RenderToString.renderArg 1 latexState args
    in
    Html.a [ HA.href ref ] [ Html.text label ]


renderILink : String -> LatexState -> List LatexExpression -> Html msg
renderILink _ latexState args =
    Html.span [] []


renderInclude : String -> LatexState -> List LatexExpression -> Html msg
renderInclude _ latexState args =
    Html.span [] []


renderPublicLink : String -> LatexState -> List LatexExpression -> Html msg
renderPublicLink _ latexState args =
    let
        id =
            Internal.RenderToString.renderArg 0 latexState args

        ref =
            getDictionaryItem "setclient" latexState ++ "/" ++ id

        label =
            Internal.RenderToString.renderArg 1 latexState args
    in
    Html.a [ HA.href ref ] [ Html.text label ]



-- SMACRO


renderSMacroDict : Dict.Dict String (String -> LatexState -> List LatexExpression -> List LatexExpression -> LatexExpression -> Html msg)
renderSMacroDict =
    Dict.fromList
        [ ( "bibitem", \source latexState optArgs args body -> renderBibItem source latexState optArgs args body )
        ]


renderSMacro : String -> LatexState -> String -> List LatexExpression -> List LatexExpression -> LatexExpression -> Html msg
renderSMacro source latexState name optArgs args le =
    case Dict.get name renderSMacroDict of
        Just f ->
            f source latexState optArgs args le

        Nothing ->
            reproduceSMacro source name latexState optArgs args le


reproduceSMacro : String -> String -> LatexState -> List LatexExpression -> List LatexExpression -> LatexExpression -> Html msg
reproduceSMacro source name latexState optArgs args le =
    let
        renderedOptArgs =
            renderArgList source latexState optArgs |> List.map enclose

        renderedArgs =
            renderArgList source latexState args |> List.map enclose

        renderedLe =
            render source latexState le |> enclose
    in
    Html.span []
        ([ Html.text <| "\\" ++ name ] ++ renderedOptArgs ++ renderedArgs ++ [ renderedLe ])


renderBibItem : String -> LatexState -> List LatexExpression -> List LatexExpression -> LatexExpression -> Html msg
renderBibItem source latexState optArgs args body =
    let
        label =
            if List.length optArgs == 1 then
                Internal.RenderToString.renderArg 0 latexState optArgs

            else
                Internal.RenderToString.renderArg 0 latexState args

        id =
            "bibitem:" ++ label
    in
    Html.div []
        [ Html.strong [ HA.id id, HA.style "margin-right" "10px" ] [ Html.text <| "[" ++ label ++ "]" ]
        , Html.span [] [ render source latexState body ]
        ]


renderItem : String -> LatexState -> Int -> LatexExpression -> Html msg
renderItem source latexState level latexExpression =
    Html.li [ HA.style "margin-bottom" "8px" ] [ render source latexState latexExpression ]



{- END LISTS -}
-- RENDER ENVIRONMENTS


renderEnvironment : String -> LatexState -> String -> List LatexExpression -> LatexExpression -> Html msg
renderEnvironment source latexState name args body =
    environmentRenderer source name latexState args body


environmentRenderer : String -> String -> (LatexState -> List LatexExpression -> LatexExpression -> Html msg)
environmentRenderer source name =
    case Dict.get name renderEnvironmentDict of
        Just f ->
            f source

        Nothing ->
            renderDefaultEnvironment source name


theoremLikeEnvironments : List String
theoremLikeEnvironments =
    [ "theorem"
    , "proposition"
    , "corollary"
    , "lemma"
    , "definition"
    , "problem"
    ]


renderDefaultEnvironment : String -> String -> LatexState -> List LatexExpression -> LatexExpression -> Html msg
renderDefaultEnvironment source name latexState args body =
    if List.member name theoremLikeEnvironments then
        renderTheoremLikeEnvironment source latexState name args body

    else
        renderDefaultEnvironment2 source latexState (Utility.capitalize name) args body


renderTheoremLikeEnvironment : String -> LatexState -> String -> List LatexExpression -> LatexExpression -> Html msg
renderTheoremLikeEnvironment source latexState name args body =
    let
        r =
            render source latexState body

        eqno =
            getCounter "eqno" latexState

        s1 =
            getCounter "s1" latexState

        tno =
            getCounter "tno" latexState

        tnoString =
            if s1 > 0 then
                " " ++ String.fromInt s1 ++ "." ++ String.fromInt tno

            else
                " " ++ String.fromInt tno
    in
    Html.div [ HA.class "environment" ]
        [ Html.strong [] [ Html.text (Utility.capitalize name ++ tnoString) ]
        , Html.div [ HA.class "italic" ] [ r ]
        ]


renderDefaultEnvironment2 : String -> LatexState -> String -> List LatexExpression -> LatexExpression -> Html msg
renderDefaultEnvironment2 source latexState name args body =
    let
        r =
            render source latexState body
    in
    Html.div [ HA.class "environment" ]
        [ Html.strong [] [ Html.text name ]
        , Html.div [] [ r ]
        ]



-- RENDER INDIVIDUAL ENVIRNOMENTS


renderEnvironmentDict : Dict.Dict String (SourceText -> LatexState -> List LatexExpression -> LatexExpression -> Html msg)
renderEnvironmentDict =
    -- s x a y = SourceText, LaTeXState, List LatexExpression, LaTeXExpression
    Dict.fromList
        [ ( "align", \s x a y -> renderMathEnvironment "aligned" s x y )
        , ( "matrix",  \s x a y -> renderMathEnvironment "matrix" s x y )
        , ( "pmatrix",  \s x a y -> renderMathEnvironment "pmatrix" s x y )
        , ( "bmatrix",  \s x a y -> renderMathEnvironment "bmatrix" s x y )
        , ( "Bmatrix",  \s x a y -> renderMathEnvironment "Bmatrix" s x y )
        , ( "vmatrix",  \s x a y -> renderMathEnvironment "vmatrix" s x y )
        , ( "Vmatrix",  \s x a y -> renderMathEnvironment "Vmatrix" s x y )
        , ( "colored",     \s x a y -> renderCodeEnvironment s x a y )
        , ( "center", \s x a y -> renderCenterEnvironment s x y )
        , ( "obeylines", \s x a y -> renderObeyLinesEnvironment s x y )
        , ( "CD",  \s x a y -> renderMathJaxEnvironment "CD" s x y  )
        , ( "comment", \s x a y -> renderCommentEnvironment s x y )
        , ( "defitem", \s x a y -> renderDefItemEnvironment s x a y )
        , ( "enumerate", \s x a y -> renderEnumerate s x y )
        , ( "eqnarray", \s x a y -> renderEqnArray s x y )
        , ( "equation", \s x a y -> renderEquationEnvironment s x y )
        , ( "indent", \s x a y -> renderIndentEnvironment s x y )
        , ( "itemize", \s x a y -> renderItemize s x y )
        , ( "listing", \s x a y -> renderListing s x y )
        , ( "macros", \s x a y -> renderMacros s x y )
        , ( "maskforweb", \s x a y -> renderCommentEnvironment s x y )
        , ( "quotation", \s x a y -> renderQuotation s x y )
        , ( "tabular", \s x a y -> renderTabular s x y )
        , ( "thebibliography", \s x a y -> renderTheBibliography s x y )
        , ( "useforweb", \s x a y -> renderUseForWeb s x y )
        , ( "verbatim", \s x a y -> renderVerbatim s x y )
        , ( "verse", \s x a y -> renderVerse s x y )
        , ( "mathmacro", \s x a y -> renderMathMacros s x y )
        , ( "textmacro", \s x a y -> renderTextMacros s x y )
        , ( "svg", \s x a y -> renderSvg s x y )
        ]


renderSvg : SourceText -> LatexState -> LatexExpression -> Html msg
renderSvg source latexState body =
    case SvgParser.parse (Internal.RenderToString.render latexState body) of
        Ok html_ ->
            html_

        Err _ ->
            Html.span [ HA.class "X6" ] [ Html.text "SVG parse error" ]





renderMathEnvironment : EnvName -> SourceText -> LatexState -> LatexExpression -> Html msg
renderMathEnvironment envName _ latexState body =
    let
        r =
            Internal.RenderToString.render latexState body

        eqno =
            getCounter "eqno" latexState

        s1 =
            getCounter "s1" latexState

        addendum =
            if eqno > 0 then
                if s1 > 0 then
                    "\\tag{" ++ String.fromInt s1 ++ "." ++ String.fromInt eqno ++ "}"

                else
                    "\\tag{" ++ String.fromInt eqno ++ "}"

            else
                ""

        innerContents : String.String
        innerContents =
            case body of
                LXString str ->
                    str
                        |> String.trim
                        |> Internal.MathMacro.evalStr latexState.mathMacroDictionary
                        |> String.replace "\\ \\" "\\\\"
                        |> Internal.ParserHelpers.removeLabel

                _ ->
                    "" --  "Parser error in render align environment"

        content =
            -- REVIEW: changed for KaTeX
            "\n\\begin{" ++ envName ++ "}\n" ++ innerContents ++ "\n\\end{" ++ envName ++ "}\n"

        tag =
            case Internal.ParserHelpers.getTag addendum of
                Nothing ->
                    ""

                Just tag_ ->
                    "(" ++ tag_ ++ ")"
    in
    displayMathTextWithLabel_ latexState content tag

renderMathJaxEnvironment : EnvName -> SourceText -> LatexState -> LatexExpression -> Html msg
renderMathJaxEnvironment envName source latexState body =
    let
        r =
            Internal.RenderToString.render latexState body

        eqno =
            getCounter "eqno" latexState

        s1 =
            getCounter "s1" latexState

        addendum =
            if eqno > 0 then
                if s1 > 0 then
                    "\\tag{" ++ String.fromInt s1 ++ "." ++ String.fromInt eqno ++ "}"

                else
                    "\\tag{" ++ String.fromInt eqno ++ "}"

            else
                ""

        innerContents =
            case body of
                LXString str ->
                    str |> String.trim
                        |> Internal.MathMacro.evalStr latexState.mathMacroDictionary
                        |> String.replace "\\ \\" "\\\\"
                        |> Internal.ParserHelpers.removeLabel
                        |> (\x -> "\\begin{" ++ envName ++ "}\n" ++ x ++ "\n\\end{" ++ envName ++ "}")

                _ ->
                    "" --  "Parser error in render align environment"

        content =
            -- REVIEW: changed for KaTeX
            "\n\\begin{" ++ envName ++ "}\n" ++ innerContents ++ "\n\\end{" ++ envName ++ "}\n"

        tag =
            case Internal.ParserHelpers.getTag addendum of
                Nothing ->
                    ""

                Just tag_ ->
                    "(" ++ tag_ ++ ")"
    in
    displayMathJaxTextWithLabel_ latexState innerContents tag


renderCenterEnvironment : SourceText -> LatexState -> LatexExpression -> Html msg
renderCenterEnvironment source latexState body =
    let
        r =
            render source latexState body
    in
    Html.div
        [ HA.style "display" "flex"
        , HA.style "flex-direction" "row"
        , HA.style "justify-content" "center"
        ]
        [ r ]


renderObeyLinesEnvironment : SourceText -> LatexState -> LatexExpression -> Html msg
renderObeyLinesEnvironment source latexState body =
    let
        r =
            render source latexState body
    in
    Html.div
        [ HA.style "white-space" "pre"

        ]
        [ r ]

renderCommentEnvironment : SourceText -> LatexState -> LatexExpression -> Html msg
renderCommentEnvironment source latexState body =
    Html.div [] []


renderEnumerate : SourceText -> LatexState -> LatexExpression -> Html msg
renderEnumerate source latexState body =
    -- TODO: fix spacing issue
    Html.ol [ HA.style "margin-top" "0px" ] [ render source latexState body ]


renderDefItemEnvironment : SourceText -> LatexState -> List LatexExpression -> LatexExpression -> Html msg
renderDefItemEnvironment source latexState optArgs body =
    Html.div []
        [ Html.strong [] [ Html.text <| Internal.RenderToString.renderArg 0 latexState optArgs ]
        , Html.div [ HA.style "margin-left" "25px", HA.style "margin-top" "10px" ] [ render source latexState body ]
        ]


{-| XXX
-}
renderEqnArray : SourceText -> LatexState -> LatexExpression -> Html msg
renderEqnArray source latexState body =
    let
        body1 =
            Internal.RenderToString.render latexState body

        body2 =
            -- REVIEW: changed for KaTeX
            "\\begin{aligned}" ++ body1 ++ "\\end{aligned}"
    in
    displayMathText latexState body2


renderEquationEnvironment : SourceText -> LatexState -> LatexExpression -> Html msg
renderEquationEnvironment source latexState body =
    let
        eqno =
            getCounter "eqno" latexState

        s1 =
            getCounter "s1" latexState

        addendum =
            if eqno > 0 then
                if s1 > 0 then
                    "\\tag{" ++ String.fromInt s1 ++ "." ++ String.fromInt eqno ++ "}"

                else
                    "\\tag{" ++ String.fromInt eqno ++ "}"

            else
                ""

        contents =
            case body of
                LXString str ->
                    str
                        |> String.trim
                        |> Internal.MathMacro.evalStr latexState.mathMacroDictionary
                        |> Internal.ParserHelpers.removeLabel

                _ ->
                    "Parser error in render equation environment"

        tag =
            case Internal.ParserHelpers.getTag addendum of
                Nothing ->
                    ""

                Just tag_ ->
                    --   "\\qquad (" ++ tag_ ++ ")"
                    "(" ++ tag_ ++ ")"
    in
    -- ("\\begin{equation}" ++ contents ++ addendum ++ "\\end{equation}")
    -- REVIEW; changed for KaTeX
    -- displayMathText_ latexState  (contents ++ tag)
    displayMathTextWithLabel_ latexState contents tag


renderIndentEnvironment : SourceText -> LatexState -> LatexExpression -> Html msg
renderIndentEnvironment source latexState body =
    Html.div [ HA.style "margin-left" "2em" ] [ render source latexState body ]


renderItemize : SourceText -> LatexState -> LatexExpression -> Html msg
renderItemize source latexState body =
    -- TODO: fix space issue
    Html.ul [ HA.style "margin-top" "0px" ] [ render source latexState body ]


renderListing : SourceText -> LatexState -> LatexExpression -> Html msg
renderListing _ latexState body =
    let
        text =
            Internal.RenderToString.render latexState body

        lines =
            Utility.addLineNumbers text
    in
    Html.pre [ HA.class "verbatim" ] [ Html.text lines ]


renderMacros : SourceText -> LatexState -> LatexExpression -> Html msg
renderMacros _ latexState body =
    displayMathText latexState (Internal.RenderToString.render latexState body)


renderMathMacros : SourceText -> LatexState -> LatexExpression -> Html msg
renderMathMacros _ _ _ =
    Html.div [] []


renderTextMacros : SourceText -> LatexState -> LatexExpression -> Html msg
renderTextMacros _ _ _ =
    Html.div [] []


renderQuotation : SourceText -> LatexState -> LatexExpression -> Html msg
renderQuotation source latexState body =
    Html.div [ HA.style "margin-left" "2em", HA.style "font-style" "italic" ] [ render source latexState body ]


renderTabular : SourceText -> LatexState -> LatexExpression -> Html msg
renderTabular source latexState body =
    Html.table
        [ HA.style "border-spacing" "20px 10px"
        , HA.style "margin-left" "-20px"
        ]
        [ renderTableBody source latexState body ]


renderCell : SourceText -> LatexState -> LatexExpression -> Html msg
renderCell source latexState cell =
    case cell of
        LXString s ->
            Html.td [] [ Html.text s ]

        InlineMath s ->
            Html.td [] [ inlineMathText latexState s ]

        Macro s x y ->
            Html.td [] [ renderMacro source emptyLatexState s x y ]

        -- ###
        _ ->
            Html.td [] []


renderRow : SourceText -> LatexState -> LatexExpression -> Html msg
renderRow source latexState row =
    case row of
        LatexList row_ ->
            Html.tr [] (row_ |> List.map (renderCell source latexState))

        _ ->
            Html.tr [] []


renderTableBody : SourceText -> LatexState -> LatexExpression -> Html msg
renderTableBody source latexState body =
    case body of
        LatexList body_ ->
            Html.tbody [] (body_ |> List.map (renderRow source latexState))

        _ ->
            Html.tbody [] []


renderTheBibliography : SourceText -> LatexState -> LatexExpression -> Html msg
renderTheBibliography source latexState body =
    Html.div [] [ render source latexState body ]


renderUseForWeb : SourceText -> LatexState -> LatexExpression -> Html msg
renderUseForWeb source latexState body =
    displayMathText latexState (Internal.RenderToString.render latexState body)


renderVerbatim : SourceText -> LatexState -> LatexExpression -> Html msg
renderVerbatim source latexState body =
    let
        body2 =
            Internal.RenderToString.render latexState body
    in
    Html.pre [ HA.style "margin-top" "0px", HA.style "margin-bottom" "0px", HA.style "margin-left" "25px", HA.style "font-size" "14px" ] [ Html.text body2 ]



renderCodeEnvironment : SourceText -> LatexState -> List LatexExpression -> LatexExpression -> Html msg
renderCodeEnvironment source_ latexState optArgs body =
    let
      lang = Internal.RenderToString.renderArg 0 latexState optArgs
      prefix = "\\begin{colored}[" ++ lang ++ "]\n"
      suffix = "\n\\end{colored}"
      source = source_ |> String.replace prefix "" |> String.replace suffix "" |> String.trim
      -- source = source_ |> String.replace prefix "" |> String.replace suffix "" |> String.replace "$" "＄"|> String.trim
      -- source = source_ |> String.replace prefix "" |> String.replace suffix "" |> String.replace "$" "🤑"|> String.trim |> Debug.log "SOURCE"
    in
    highlightSyntax lang source

highlightSyntax : String -> String -> Html msg
highlightSyntax lang_ source =
        let
          lang = case lang_ of
              "elm" -> SH.elm
              "haskell" -> SH.elm
              "js"  ->  SH.javascript
              "xml" -> SH.xml
              "css" -> SH.css
              "python" -> SH.python
              "sql" -> SH.sql
              "json" -> SH.json
              "nolang" -> SH.noLang
              _ -> SH.noLang
        in
        Html.div [HA.style "class" "elmsh-pa"]
            [ SH.useTheme SH.oneDark
            , lang source
                |> Result.map (SH.toBlockHtml (Just 1))
                -- |> Result.map (SH.toBlockHtml (Just 1) >> \x -> Html.div [HA.style "class" "pre.elmsh {padding: 8px;}"] [x])
                |> Result.withDefault
                     (Html.pre [] [ Html.code [HA.style "padding" "8px"] [ Html.text source ]])
            ]

renderVerse : SourceText -> LatexState -> LatexExpression -> Html msg
renderVerse source latexState body =
    Html.div [ HA.style "white-space" "pre-line" ] [ Html.text (String.trim <| Internal.RenderToString.render latexState body) ]
