module Internal.Render exposing
    ( makeTableOfContents, render, renderLatexList, renderString
    , parseString, renderString2
    )

{-| This module is for quickly preparing latex for export.


# API

@docs makeTableOfContents, render, renderLatexList, renderString

-}

-- import List.Extra

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
import MiniLatex.Render exposing (MathJaxRenderOption(..))
import Parser exposing (DeadEnd, Problem(..))
import Regex
import String
import SvgParser



-- |> \str -> "\n<p>" ++ str ++ "</p>\n"
{- FUNCTIONS FOR TESTING THINGS -}


getElement : Int -> List LatexExpression -> LatexExpression
getElement k list =
    Utility.getAt k list |> Maybe.withDefault (LXString "xxx")


parseString_ parser str =
    Parser.run parser str


parseString : MathJaxRenderOption -> LatexState -> String -> List ( String, List LatexExpression )
parseString mathJaxRenderOption latexState source =
    let
        paragraphs : List String
        paragraphs =
            Paragraph.logicalParagraphify source

        parse__ : String.String -> ( String, List LatexExpression )
        parse__ paragraph =
            ( paragraph, Internal.Parser.parse paragraph |> spacify )
    in
    paragraphs
        |> List.map parse__


{-| Parse a string, then render it.
-}
renderString2 : MathJaxRenderOption -> LatexState -> String -> Html msg
renderString2 mathJaxRenderOption latexState source =
    let
        render_ : ( String, List LatexExpression ) -> Html msg
        render_ ( source_, ast ) =
            renderLatexList mathJaxRenderOption source_ latexState ast
    in
    source
        |> parseString mathJaxRenderOption latexState
        |> List.map render_
        |> Html.div []


{-| Parse a string, then render it.
-}
renderString : MathJaxRenderOption -> LatexState -> String -> Html msg
renderString mathJaxRenderOption latexState source =
    let
        paragraphs : List String
        paragraphs =
            Paragraph.logicalParagraphify source

        parse : String.String -> ( String, List LatexExpression )
        parse paragraph =
            ( paragraph, Internal.Parser.parse paragraph |> spacify )

        render_ : ( String, List LatexExpression ) -> Html msg
        render_ ( source_, ast ) =
            renderLatexList mathJaxRenderOption source_ latexState ast
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



{- TYPES AND DEFAULT VALUES -}


extractList : LatexExpression -> List LatexExpression
extractList latexExpression =
    case latexExpression of
        LatexList a ->
            a

        _ ->
            []


{-| THE MAIN RENDERING FUNCTION
-}
mathText : MathJaxRenderOption -> DisplayMode -> String -> Html msg
mathText mathJaxRenderOption displayMode content =
    Html.node "math-text"
        [ HA.property "delay" (Json.Encode.bool (isDelayMode mathJaxRenderOption))
        , HA.property "display" (Json.Encode.bool (isDisplayMathMode displayMode))
        , HA.property "content" (Json.Encode.string (content |> String.replace "\\ \\" "\\\\"))
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


isDelayMode : MathJaxRenderOption -> Bool
isDelayMode mathJaxRenderOption =
    case mathJaxRenderOption of
        Delay ->
            True

        NoDelay ->
            False


{-| The main rendering function. Compute an Html msg value
from the current LatexState and a LatexExpression.
-}
render : MathJaxRenderOption -> String -> LatexState -> LatexExpression -> Html msg
render mathJaxRenderOption source latexState latexExpression =
    case latexExpression of
        Comment str ->
            Html.p [] [ Html.text <| "" ]

        Macro name optArgs args ->
            renderMacro mathJaxRenderOption source latexState name optArgs args

        SMacro name optArgs args le ->
            renderSMacro mathJaxRenderOption source latexState name optArgs args le

        Item level latexExpr ->
            renderItem mathJaxRenderOption source latexState level latexExpr

        InlineMath str ->
            Html.span [] [ oneSpace, inlineMathText latexState mathJaxRenderOption (Internal.MathMacro.evalStr latexState.mathMacroDictionary str) ]

        DisplayMath str ->
            -- TODO: fix Internal.MathMacro.evalStr.  It is nuking \begin{pmacro}, etc.
            displayMathText latexState mathJaxRenderOption (Internal.MathMacro.evalStr latexState.mathMacroDictionary str)

        Environment name args body ->
            renderEnvironment mathJaxRenderOption source latexState name args body

        LatexList latexList ->
            renderLatexList mathJaxRenderOption source latexState latexList

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


inlineMathText : LatexState -> MathJaxRenderOption -> String -> Html msg
inlineMathText latexState mathJaxRenderOption str_ =
    let
        str =
            Internal.MathMacro.evalStr latexState.mathMacroDictionary str_
    in
    mathText mathJaxRenderOption InlineMathMode (String.trim str)


displayMathText : LatexState -> MathJaxRenderOption -> String -> Html msg
displayMathText latexState mathJaxRenderOption str_ =
    let
        str =
            Internal.MathMacro.evalStr latexState.mathMacroDictionary str_
    in
    mathText mathJaxRenderOption DisplayMathMode (String.trim str)


displayMathText_ : LatexState -> MathJaxRenderOption -> String -> Html msg
displayMathText_ latexState mathJaxRenderOption str =
    mathText mathJaxRenderOption DisplayMathMode (String.trim str)



--
-- displayMathTextWithLabel1_ : LatexState -> MathJaxRenderOption -> String -> String -> Html msg
-- displayMathTextWithLabel1_ latexState mathJaxRenderOption str label =
--     Html.div
--         [ HA.style "display" "flex"
--         , HA.style "flex-direction" "row"
--         , HA.style "justify-content" "center"
--         ]
--         [ Html.div [] [ mathText mathJaxRenderOption DisplayMathMode (String.trim str) ]
--         , Html.div [ HA.style "float" "right" ]
--             [ Html.text label ]
--         ]


displayMathTextWithLabel_ : LatexState -> MathJaxRenderOption -> String -> String -> Html msg
displayMathTextWithLabel_ latexState mathJaxRenderOption str label =
    Html.div
        []
        [ Html.div [ HA.style "float" "right", HA.style "margin-top" "3px" ]
            [ Html.text label ]
        , Html.div []
            [ mathText mathJaxRenderOption DisplayMathMode (String.trim str) ]
        ]



{- PROCESS SPACES BETWEEN ELEMENTS  V2 -}


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


{-| Like `render`, but renders a list of LatexExpressions
to Html mgs
-}
renderLatexList : MathJaxRenderOption -> String -> LatexState -> List LatexExpression -> Html msg
renderLatexList mathJaxRenderOption source latexState latexList =
    -- ### Render2.renderLatexList
    latexList
        |> spacify
        |> List.map (render mathJaxRenderOption source latexState)
        |> (\list -> Html.span [ HA.style "margin-bottom" "10px" ] list)


spacify : List LatexExpression -> List LatexExpression
spacify latexList =
    -- ### Reader2.spacify
    latexList
        |> ListMachine.run addSpace



{- RENDER MACRO -}


renderMacro : MathJaxRenderOption -> String -> LatexState -> String -> List LatexExpression -> List LatexExpression -> Html msg
renderMacro mathJaxRenderOption source latexState name optArgs args =
    case Dict.get name renderMacroDict of
        Just f ->
            f mathJaxRenderOption source latexState optArgs args

        Nothing ->
            case Dict.get name latexState.macroDictionary of
                Nothing ->
                    reproduceMacro mathJaxRenderOption source name latexState optArgs args

                Just macroDefinition ->
                    let
                        macro =
                            Macro name optArgs args

                        expr =
                            Macro.expandMacro macro macroDefinition
                    in
                    render mathJaxRenderOption source latexState expr


renderArg : MathJaxRenderOption -> String -> Int -> LatexState -> List LatexExpression -> Html msg
renderArg mathJaxRenderOption source k latexState args =
    render mathJaxRenderOption source latexState (getElement k args)


reproduceMacro : MathJaxRenderOption -> String -> String -> LatexState -> List LatexExpression -> List LatexExpression -> Html msg
reproduceMacro mathJaxRenderOption source name latexState optArgs args =
    let
        renderedArgs =
            renderArgList mathJaxRenderOption source latexState args |> List.map enclose
    in
    Html.span [ HA.style "color" "red" ]
        ([ Html.text <| "\\" ++ name ] ++ renderedArgs)


boost : (x -> z -> output) -> (x -> y -> z -> output)
boost f =
    \x y z -> f x z


renderMacroDict : Dict.Dict String (MathJaxRenderOption -> String -> LatexState -> List LatexExpression -> List LatexExpression -> Html.Html msg)
renderMacroDict =
    Dict.fromList
        [ ( "bigskip", \d s x y z -> renderBigSkip s x z )
        , ( "medskip", \d s x y z -> renderMedSkip s x z )
        , ( "smallskip", \d s x y z -> renderSmallSkip s x z )
        , ( "cite", \d s x y z -> renderCite s x z )
        , ( "dollar", \d s x y z -> renderDollar s x z )
        , ( "texbegin", \d s x y z -> renderBegin s x z )
        , ( "texend", \d s x y z -> renderEnd s x z )
        , ( "percent", \d s x y z -> renderPercent s x z )
        , ( "code", \d s x y z -> renderCode d s x z )
        , ( "ellie", \d s x y z -> renderEllie s x z )
        , ( "emph", \d s x y z -> renderItalic d s x z )
        , ( "eqref", \d s x y z -> renderEqRef s x z )
        , ( "href", \d s x y z -> renderHRef s x z )
        , ( "iframe", \d s x y z -> renderIFrame s x z )
        , ( "image", \d s x y z -> renderImage s x z )
        , ( "imageref", \d s x y z -> renderImageRef s x z )
        , ( "index", \d s x y z -> renderIndex s x z )
        , ( "italic", \d s x y z -> renderItalic d s x z )
        , ( "label", \d s x y z -> renderLabel s x z )
        , ( "maintableofcontents", \d s x y z -> renderMainTableOfContents s x z )
        , ( "maketitle", \d s x y z -> renderMakeTitle s x z )
        , ( "mdash", \d s x y z -> renderMdash s x z )
        , ( "ndash", \d s x y z -> renderNdash s x z )
        , ( "underscore", \d s x y z -> renderUnderscore s x z )
        , ( "bs", \d s x y z -> renderBackslash d s x z )
        , ( "texarg", \d s x y z -> renderTexArg d s x z )
        , ( "ref", \d s x y z -> renderRef s x z )
        , ( "medskip", \d s x y z -> renderMedSkip s x z )
        , ( "smallskip", \d s x y z -> renderSmallSkip s x z )
        , ( "section", \d s x y z -> renderSection s x z )
        , ( "section*", \d s x y z -> renderSectionStar s x z )
        , ( "subsection", \d s x y z -> renderSubsection s x z )
        , ( "subsection*", \d s x y z -> renderSubsectionStar s x z )
        , ( "subsubsection", \d s x y z -> renderSubSubsection s x z )
        , ( "subsubsection*", \d s x y z -> renderSubSubsectionStar s x z )
        , ( "setcounter", \d s x y z -> renderSetCounter s x z )
        , ( "subheading", \d s x y z -> renderSubheading s x z )
        , ( "tableofcontents", \d s x y z -> renderTableOfContents s x z )
        , ( "innertableofcontents", \d s x y z -> renderInnerTableOfContents s x z )
        , ( "red", \d s x y z -> renderRed s x z )
        , ( "blue", \d s x y z -> renderBlue s x z )
        , ( "remote", \d s x y z -> renderRemote s x z )
        , ( "local", \d s x y z -> renderLocal s x z )
        , ( "meta", \d s x y z -> renderMeta s x z )
        , ( "highlight", \d s x y z -> renderHighlighted s x z )
        , ( "strike", \d s x y z -> renderStrikeThrough s x z )
        , ( "term", \d s x y z -> renderTerm s x z )
        , ( "xlink", \d s x y z -> renderXLink s x z )
        , ( "ilink", \d s x y z -> renderILink s x z )
        , ( "xlinkPublic", \d s x y z -> renderXLinkPublic s x z )
        , ( "documentTitle", \d s x y z -> renderDocumentTitle s x z )
        , ( "title", \d s x y z -> renderTitle x z )
        , ( "author", \d s x y z -> renderAuthor s x z )
        , ( "date", \d s x y z -> renderDate s x z )
        , ( "revision", \d s x y z -> renderRevision s x z )
        , ( "email", \d s x y z -> renderEmail s x z )
        , ( "setdocid", \d s x y z -> renderSetDocId s x z )
        , ( "setclient", \d s x y z -> renderSetClient s x z )
        , ( "strong", \d s x y z -> renderStrong d s x z )
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


renderPercent : String -> LatexState -> List LatexExpression -> Html msg
renderPercent _ latexState args =
    Html.span [] [ Html.text "%" ]


renderArgList : MathJaxRenderOption -> String -> LatexState -> List LatexExpression -> List (Html msg)
renderArgList mathJaxRenderOption source latexState args =
    args |> List.map (render mathJaxRenderOption source latexState)


enclose : Html msg -> Html msg
enclose msg =
    Html.span [] [ Html.text "{", msg, Html.text "}" ]


oneSpace : Html msg
oneSpace =
    Html.text " "



{- RENDER INDIVIDUAL MACROS -}


renderBozo : MathJaxRenderOption -> String -> LatexState -> List LatexExpression -> Html msg
renderBozo mathJaxRenderOption source latexState args =
    Html.span []
        [ Html.text <| "\\bozo"
        , enclose <| renderArg mathJaxRenderOption source 0 latexState args
        , enclose <| renderArg mathJaxRenderOption source 1 latexState args
        ]


renderItalic : MathJaxRenderOption -> String -> LatexState -> List LatexExpression -> Html msg
renderItalic mathJaxRenderOption source latexState args =
    Html.i [] [ Html.text " ", renderArg mathJaxRenderOption source 0 latexState args ]


renderStrong : MathJaxRenderOption -> String -> LatexState -> List LatexExpression -> Html msg
renderStrong mathJaxRenderOption source latexState args =
    Html.strong [] [ oneSpace, renderArg mathJaxRenderOption source 0 latexState args ]


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


renderCode : MathJaxRenderOption -> String -> LatexState -> List LatexExpression -> Html msg
renderCode mathJaxRenderOption source latexState args =
    let
        arg =
            renderArg mathJaxRenderOption source 0 latexState args
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



{- RENDER TABLE CONTENTS -}


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



{- END TABLE OF CONTENTS -}


renderMdash : String -> LatexState -> List LatexExpression -> Html msg
renderMdash source latexState args =
    Html.span [] [ Html.text "— " ]


renderNdash : String -> LatexState -> List LatexExpression -> Html msg
renderNdash source latexState args =
    Html.span [] [ Html.text "– " ]


renderUnderscore : String -> LatexState -> List LatexExpression -> Html msg
renderUnderscore source latexState args =
    Html.span [] [ Html.text "_" ]


renderBackslash : MathJaxRenderOption -> String -> LatexState -> List LatexExpression -> Html msg
renderBackslash mathJaxRenderOption source latexState args =
    Html.span [] [ Html.text "\\", renderArg mathJaxRenderOption source 0 latexState args ]


renderTexArg : MathJaxRenderOption -> String -> LatexState -> List LatexExpression -> Html msg
renderTexArg mathJaxRenderOption source latexState args =
    Html.span [] [ Html.text "{", renderArg mathJaxRenderOption source 0 latexState args, Html.text "}" ]


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
renderSection _ latexState args =
    let
        sectionName =
            Internal.RenderToString.renderArg 0 latexState args

        s1 =
            getCounter "s1" latexState

        label =
            if s1 > 0 then
                String.fromInt s1 ++ " "

            else
                ""

        ref =
            idPhrase "section" sectionName
    in
    Html.h2 (headingStyle ref 24) [ Html.text <| label ++ sectionName ]



-- headingStyle : String -> Float -> Attribute


headingStyle ref h =
    [ HA.id ref
    , HA.style "margin-top" (String.fromFloat h ++ "px")
    , HA.style "margin-bottom" (String.fromFloat (0.0 * h) ++ "px")
    ]


renderSectionStar : String -> LatexState -> List LatexExpression -> Html msg
renderSectionStar _ latexState args =
    let
        sectionName =
            Internal.RenderToString.renderArg 0 latexState args

        ref =
            idPhrase "section" sectionName
    in
    Html.h2 (headingStyle ref 24) [ Html.text <| sectionName ]


renderSubsection : String -> LatexState -> List LatexExpression -> Html msg
renderSubsection _ latexState args =
    let
        sectionName =
            Internal.RenderToString.renderArg 0 latexState args

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
            idPhrase "subsection" sectionName
    in
    Html.h3 (headingStyle ref 12) [ Html.text <| label ++ sectionName ]


renderSubsectionStar : String -> LatexState -> List LatexExpression -> Html msg
renderSubsectionStar _ latexState args =
    let
        sectionName =
            Internal.RenderToString.renderArg 0 latexState args

        ref =
            idPhrase "subsection" sectionName
    in
    Html.h3 (headingStyle ref 12) [ Html.text <| sectionName ]


renderSubSubsection : String -> LatexState -> List LatexExpression -> Html msg
renderSubSubsection _ latexState args =
    let
        sectionName =
            Internal.RenderToString.renderArg 0 latexState args

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
            idPhrase "subsubsection" sectionName
    in
    Html.h4 [ HA.id ref ] [ Html.text <| label ++ sectionName ]


renderSubSubsectionStar : String -> LatexState -> List LatexExpression -> Html msg
renderSubSubsectionStar _ latexState args =
    let
        sectionName =
            Internal.RenderToString.renderArg 0 latexState args

        ref =
            idPhrase "subsubsection" sectionName
    in
    Html.h4 [ HA.id ref ] [ Html.text <| sectionName ]


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


renderSubheading : String -> LatexState -> List LatexExpression -> Html msg
renderSubheading _ latexState args =
    let
        title =
            Internal.RenderToString.renderArg 0 latexState args
    in
    Html.p [ HA.style "font-weight" "bold", HA.style "margin-bottom" "0", HA.style "margin-left" "-2px" ] [ Html.text <| title ]


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
            Html.div [ HA.style "font-size" "36px" ] [ Html.text <| title ]

        bodyParts =
            [ author, email, date, revisionText ]
                |> List.filter (\x -> x /= "")
                |> List.map (\x -> Html.div [] [ Html.text x ])
    in
    Html.div []
        ([ titlePart ] ++ bodyParts)


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


renderMeta : String -> LatexState -> List LatexExpression -> Html msg
renderMeta _ latexState args =
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
    -- REVIEW: CHANGED  ref to from ++ "/" ++ to +++ "/u/" ++ for lamdera app
    let
        id =
            Internal.RenderToString.renderArg 0 latexState args

        ref =
            getDictionaryItem "setclient" latexState ++ "/i/" ++ id

        label =
            Internal.RenderToString.renderArg 1 latexState args
    in
    Html.a [ HA.href ref ] [ Html.text label ]


renderXLinkPublic : String -> LatexState -> List LatexExpression -> Html msg
renderXLinkPublic _ latexState args =
    let
        id =
            Internal.RenderToString.renderArg 0 latexState args

        ref =
            getDictionaryItem "setclient" latexState ++ "/" ++ id

        label =
            Internal.RenderToString.renderArg 1 latexState args
    in
    Html.a [ HA.href ref ] [ Html.text label ]



{- END OF INDIVIDUAL MACROS -}
{- SMACROS -}


renderSMacroDict : Dict.Dict String (MathJaxRenderOption -> String -> LatexState -> List LatexExpression -> List LatexExpression -> LatexExpression -> Html msg)
renderSMacroDict =
    Dict.fromList
        [ ( "bibitem", \mathJaxRenderOption source latexState optArgs args body -> renderBibItem mathJaxRenderOption source latexState optArgs args body )
        ]


renderSMacro : MathJaxRenderOption -> String -> LatexState -> String -> List LatexExpression -> List LatexExpression -> LatexExpression -> Html msg
renderSMacro mathJaxRenderOption source latexState name optArgs args le =
    case Dict.get name renderSMacroDict of
        Just f ->
            f mathJaxRenderOption source latexState optArgs args le

        Nothing ->
            reproduceSMacro mathJaxRenderOption source name latexState optArgs args le


reproduceSMacro : MathJaxRenderOption -> String -> String -> LatexState -> List LatexExpression -> List LatexExpression -> LatexExpression -> Html msg
reproduceSMacro mathJaxRenderOption source name latexState optArgs args le =
    let
        renderedOptArgs =
            renderArgList mathJaxRenderOption source latexState optArgs |> List.map enclose

        renderedArgs =
            renderArgList mathJaxRenderOption source latexState args |> List.map enclose

        renderedLe =
            render mathJaxRenderOption source latexState le |> enclose
    in
    Html.span []
        ([ Html.text <| "\\" ++ name ] ++ renderedOptArgs ++ renderedArgs ++ [ renderedLe ])


renderBibItem : MathJaxRenderOption -> String -> LatexState -> List LatexExpression -> List LatexExpression -> LatexExpression -> Html msg
renderBibItem mathJaxRenderOption source latexState optArgs args body =
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
        , Html.span [] [ render mathJaxRenderOption source latexState body ]
        ]



{- END RENDER INDIVIDUAL SMACROS -}
{- LISTS -}


renderItem : MathJaxRenderOption -> String -> LatexState -> Int -> LatexExpression -> Html msg
renderItem mathJaxRenderOption source latexState level latexExpression =
    Html.li [ HA.style "margin-bottom" "8px" ] [ render mathJaxRenderOption source latexState latexExpression ]



{- END LISTS -}
{- BEGIN ENVIRONMENTS -}


renderEnvironment : MathJaxRenderOption -> String -> LatexState -> String -> List LatexExpression -> LatexExpression -> Html msg
renderEnvironment mathJaxRenderOption source latexState name args body =
    environmentRenderer mathJaxRenderOption source name latexState args body


environmentRenderer : MathJaxRenderOption -> String -> String -> (LatexState -> List LatexExpression -> LatexExpression -> Html msg)
environmentRenderer mathJaxRenderOption source name =
    case Dict.get name renderEnvironmentDict of
        Just f ->
            f mathJaxRenderOption source

        Nothing ->
            renderDefaultEnvironment mathJaxRenderOption source name


theoremLikeEnvironments : List String
theoremLikeEnvironments =
    [ "theorem"
    , "proposition"
    , "corollary"
    , "lemma"
    , "definition"
    ]


renderDefaultEnvironment : MathJaxRenderOption -> String -> String -> LatexState -> List LatexExpression -> LatexExpression -> Html msg
renderDefaultEnvironment mathJaxRenderOption source name latexState args body =
    if List.member name theoremLikeEnvironments then
        renderTheoremLikeEnvironment mathJaxRenderOption source latexState name args body

    else
        renderDefaultEnvironment2 mathJaxRenderOption source latexState (Utility.capitalize name) args body


renderTheoremLikeEnvironment : MathJaxRenderOption -> String -> LatexState -> String -> List LatexExpression -> LatexExpression -> Html msg
renderTheoremLikeEnvironment mathJaxRenderOption source latexState name args body =
    let
        r =
            render mathJaxRenderOption source latexState body

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


renderDefaultEnvironment2 : MathJaxRenderOption -> String -> LatexState -> String -> List LatexExpression -> LatexExpression -> Html msg
renderDefaultEnvironment2 mathJaxRenderOption source latexState name args body =
    let
        r =
            render mathJaxRenderOption source latexState body
    in
    Html.div [ HA.class "environment" ]
        [ Html.strong [] [ Html.text name ]
        , Html.div [] [ r ]
        ]



{- INDIVIDUAL ENVIRONMENT RENDERERS -}


renderEnvironmentDict : Dict.Dict String (MathJaxRenderOption -> String -> LatexState -> List LatexExpression -> LatexExpression -> Html msg)
renderEnvironmentDict =
    Dict.fromList
        [ ( "align", \d s x a y -> renderAlignEnvironment d s x y )
        , ( "center", \d s x a y -> renderCenterEnvironment d s x y )
        , ( "comment", \d s x a y -> renderCommentEnvironment s x y )
        , ( "defitem", \d s x a y -> renderDefItemEnvironment d s x a y )
        , ( "enumerate", \d s x a y -> renderEnumerate d s x y )
        , ( "eqnarray", \d s x a y -> renderEqnArray d s x y )
        , ( "equation", \d s x a y -> renderEquationEnvironment d s x y )
        , ( "indent", \d s x a y -> renderIndentEnvironment d s x y )
        , ( "itemize", \d s x a y -> renderItemize d s x y )
        , ( "listing", \d s x a y -> renderListing s x y )
        , ( "macros", \d s x a y -> renderMacros d s x y )
        , ( "maskforweb", \d s x a y -> renderCommentEnvironment s x y )
        , ( "quotation", \d s x a y -> renderQuotation d s x y )
        , ( "tabular", \d s x a y -> renderTabular d s x y )
        , ( "thebibliography", \d s x a y -> renderTheBibliography d s x y )
        , ( "useforweb", \d s x a y -> renderUseForWeb d s x y )
        , ( "verbatim", \d s x a y -> renderVerbatim s x y )
        , ( "verse", \d s x a y -> renderVerse s x y )
        , ( "mathmacro", \d s x a y -> renderMathMacros d s x y )
        , ( "textmacro", \d s x a y -> renderTextMacros d s x y )
        , ( "svg", \d s x a y -> renderSvg d s x y )
        ]


renderSvg : MathJaxRenderOption -> String -> LatexState -> LatexExpression -> Html msg
renderSvg mathJaxRenderOption source latexState body =
    case SvgParser.parse (Internal.RenderToString.render latexState body) of
        Ok html_ ->
            html_

        Err _ ->
            Html.span [ HA.class "X6" ] [ Html.text "SVG parse error" ]


renderAlignEnvironment : MathJaxRenderOption -> String -> LatexState -> LatexExpression -> Html msg
renderAlignEnvironment mathJaxRenderOption source latexState body =
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
                    str
                        |> String.trim
                        |> Internal.MathMacro.evalStr latexState.mathMacroDictionary
                        |> String.replace "\\ \\" "\\\\"
                        |> Internal.ParserHelpers.removeLabel

                _ ->
                    "Parser error in render align environment"

        content =
            -- REVIEW: changed for KaTeX
            "\n\\begin{aligned}\n" ++ innerContents ++ "\n\\end{aligned}\n"

        tag =
            case Internal.ParserHelpers.getTag addendum of
                Nothing ->
                    ""

                Just tag_ ->
                    "(" ++ tag_ ++ ")"
    in
    displayMathTextWithLabel_ latexState mathJaxRenderOption content tag


renderCenterEnvironment : MathJaxRenderOption -> String -> LatexState -> LatexExpression -> Html msg
renderCenterEnvironment mathJaxRenderOption source latexState body =
    let
        r =
            render mathJaxRenderOption source latexState body
    in
    Html.div
        [ HA.style "display" "flex"
        , HA.style "flex-direction" "row"
        , HA.style "justify-content" "center"
        ]
        [ r ]


renderCommentEnvironment : String -> LatexState -> LatexExpression -> Html msg
renderCommentEnvironment source latexState body =
    Html.div [] []


renderEnumerate : MathJaxRenderOption -> String -> LatexState -> LatexExpression -> Html msg
renderEnumerate mathJaxRenderOption source latexState body =
    Html.ol [ HA.style "margin-top" "0px" ] [ render mathJaxRenderOption source latexState body ]


renderDefItemEnvironment : MathJaxRenderOption -> String -> LatexState -> List LatexExpression -> LatexExpression -> Html msg
renderDefItemEnvironment mathJaxRenderOption source latexState optArgs body =
    Html.div []
        [ Html.strong [] [ Html.text <| Internal.RenderToString.renderArg 0 latexState optArgs ]
        , Html.div [ HA.style "margin-left" "25px", HA.style "margin-top" "10px" ] [ render mathJaxRenderOption source latexState body ]
        ]


{-| XXX
-}
renderEqnArray : MathJaxRenderOption -> String -> LatexState -> LatexExpression -> Html msg
renderEqnArray mathJaxRenderOption source latexState body =
    let
        body1 =
            Internal.RenderToString.render latexState body

        body2 =
            -- REVIEW: changed for KaTeX
            "\\begin{aligned}" ++ body1 ++ "\\end{aligned}"
    in
    displayMathText latexState mathJaxRenderOption body2


renderEquationEnvironment : MathJaxRenderOption -> String -> LatexState -> LatexExpression -> Html msg
renderEquationEnvironment mathJaxRenderOption source latexState body =
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
    -- displayMathText_ latexState mathJaxRenderOption (contents ++ tag)
    displayMathTextWithLabel_ latexState mathJaxRenderOption contents tag


renderIndentEnvironment : MathJaxRenderOption -> String -> LatexState -> LatexExpression -> Html msg
renderIndentEnvironment mathJaxRenderOption source latexState body =
    Html.div [ HA.style "margin-left" "2em" ] [ render mathJaxRenderOption source latexState body ]


renderItemize : MathJaxRenderOption -> String -> LatexState -> LatexExpression -> Html msg
renderItemize mathJaxRenderOption source latexState body =
    Html.ul [ HA.style "margin-top" "0px" ] [ render mathJaxRenderOption source latexState body ]


renderListing : String -> LatexState -> LatexExpression -> Html msg
renderListing source latexState body =
    let
        text =
            Internal.RenderToString.render latexState body

        lines =
            Utility.addLineNumbers text
    in
    Html.pre [ HA.class "verbatim" ] [ Html.text lines ]


renderMacros : MathJaxRenderOption -> String -> LatexState -> LatexExpression -> Html msg
renderMacros mathJaxRenderOption source latexState body =
    displayMathText latexState mathJaxRenderOption (Internal.RenderToString.render latexState body)


renderMathMacros : MathJaxRenderOption -> String -> LatexState -> LatexExpression -> Html msg
renderMathMacros mathJaxRenderOption source latexState body =
    Html.div [] []


renderTextMacros : MathJaxRenderOption -> String -> LatexState -> LatexExpression -> Html msg
renderTextMacros mathJaxRenderOption source latexState body =
    Html.div [] []


renderQuotation : MathJaxRenderOption -> String -> LatexState -> LatexExpression -> Html msg
renderQuotation mathJaxRenderOption source latexState body =
    Html.div [ HA.style "margin-left" "2em", HA.style "font-style" "italic" ] [ render mathJaxRenderOption source latexState body ]


renderTabular : MathJaxRenderOption -> String -> LatexState -> LatexExpression -> Html msg
renderTabular mathJaxRenderOption source latexState body =
    Html.table
        [ HA.style "border-spacing" "20px 10px"
        , HA.style "margin-left" "-20px"
        ]
        [ renderTableBody mathJaxRenderOption source latexState body ]


renderCell : MathJaxRenderOption -> String -> LatexState -> LatexExpression -> Html msg
renderCell mathJaxRenderOption source latexState cell =
    case cell of
        LXString s ->
            Html.td [] [ Html.text s ]

        InlineMath s ->
            Html.td [] [ inlineMathText latexState mathJaxRenderOption s ]

        Macro s x y ->
            Html.td [] [ renderMacro mathJaxRenderOption source emptyLatexState s x y ]

        -- ###
        _ ->
            Html.td [] []


renderRow : MathJaxRenderOption -> String -> LatexState -> LatexExpression -> Html msg
renderRow mathJaxRenderOption source latexState row =
    case row of
        LatexList row_ ->
            Html.tr [] (row_ |> List.map (renderCell mathJaxRenderOption source latexState))

        _ ->
            Html.tr [] []


renderTableBody : MathJaxRenderOption -> String -> LatexState -> LatexExpression -> Html msg
renderTableBody mathJaxRenderOption source latexState body =
    case body of
        LatexList body_ ->
            Html.tbody [] (body_ |> List.map (renderRow mathJaxRenderOption source latexState))

        _ ->
            Html.tbody [] []


renderTheBibliography : MathJaxRenderOption -> String -> LatexState -> LatexExpression -> Html msg
renderTheBibliography mathJaxRenderOption source latexState body =
    Html.div [] [ render mathJaxRenderOption source latexState body ]


renderUseForWeb : MathJaxRenderOption -> String -> LatexState -> LatexExpression -> Html msg
renderUseForWeb mathJaxRenderOption source latexState body =
    displayMathText latexState mathJaxRenderOption (Internal.RenderToString.render latexState body)


renderVerbatim : String -> LatexState -> LatexExpression -> Html msg
renderVerbatim source latexState body =
    let
        body2 =
            Internal.RenderToString.render latexState body
    in
    Html.pre [ HA.style "margin-top" "-14px", HA.style "margin-bottom" "0px", HA.style "margin-left" "25px", HA.style "font-size" "14px" ] [ Html.text body2 ]


renderVerse : String -> LatexState -> LatexExpression -> Html msg
renderVerse source latexState body =
    Html.div [ HA.style "white-space" "pre-line" ] [ Html.text (String.trim <| Internal.RenderToString.render latexState body) ]
