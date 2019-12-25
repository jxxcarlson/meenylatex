module Internal.Render2
    exposing
        ( makeTableOfContents
        , render
        , renderLatexList
        , renderString
        )

{-| This module is for quickly preparing latex for export.


# API

@docs makeTableOfContents, render, renderLatexList, renderString

-}

-- import List.Extra

import Dict
import Html exposing (Attribute, Html)
import Html.Attributes as HA
import Json.Encode
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
import Internal.Parser exposing (LatexExpression(..), defaultLatexList, latexList)
import Internal.Render
import Internal.ErrorMessages2 as ErrorMessages
import Internal.Utility as Utility
import Parser exposing (DeadEnd, Problem(..))
import Regex
import String
import Internal.Macro as Macro
import Internal.Paragraph as Paragraph


-- |> \str -> "\n<p>" ++ str ++ "</p>\n"
{- FUNCTIONS FOR TESTING THINGS -}


getElement : Int -> List LatexExpression -> LatexExpression
getElement k list =
    Utility.getAt k list |> Maybe.withDefault (LXString "xxx")


parseString parser str =
    Parser.run parser str



-- renderString latexList latexState text


{-| Old version, keeping it around for a while.
It does not execute `spacify`, which is a problem.
-}
renderString1 : LatexState -> String -> Html msg
renderString1 latexState str =
    str
        |> Internal.Parser.parse
        |> List.map (render str latexState)
        |> Html.div []


{-| Parse a string, then render it.
-}
renderString : LatexState -> String -> Html msg
renderString latexState source =
    let
        paragraphs : List String
        paragraphs = Paragraph.logicalParagraphify source

        parse : String.String -> (String, List LatexExpression)
        parse paragraph = (paragraph, Internal.Parser.parse paragraph |> spacify)

        render_ : (String, List LatexExpression) -> Html msg
        render_ (source_, ast) =
          renderLatexList source_ latexState ast

    in
        paragraphs
            |> List.map  parse
            |> List.map render_
            |> Html.div []

--renderString : LatexState -> String -> Html msg
--renderString latexState str =
--    -- ### Render2.renderString
--    str
--        |> Paragraph.logicalParagraphify
--        |> List.map Internal.Parser.parse
--        |> List.map spacify
--        |> List.map (List.map (render latexState))
--        |> List.map (\x -> Html.div [] x)
--        |> Html.div []

postProcess : String -> String
postProcess str =
    str
        |> String.replace "---" "&mdash;"
        |> String.replace "--" "&ndash;"
        |> String.replace "\\&" "&#38"



{- TYPES AND DEFAULT VALJUES -}


extractList : LatexExpression -> List LatexExpression
extractList latexExpression =
    case latexExpression of
        LatexList a ->
            a

        _ ->
            []


{-| THE MAIN RENDERING FUNCTION
-}
mathText : String -> Html msg
mathText content =
    Html.node "math-text"
        [ HA.property "content" (Json.Encode.string content) ]
        []


{-| The main rendering function. Compute an Html msg value
from the current LatexState and a LatexExpression.
-}
render : String -> LatexState -> LatexExpression -> Html msg
render source latexState latexExpression =
    case latexExpression of
        Comment str ->
            Html.p [] [ Html.text <| "" ]

        Macro name optArgs args ->
            renderMacro source latexState name optArgs args

        SMacro name optArgs args le ->
            renderSMacro source latexState name optArgs args le

        Item level latexExpr ->
            renderItem source latexState level latexExpr

        InlineMath str ->
            Html.span [] [ oneSpace, inlineMathText str ]

        DisplayMath str ->
            displayMathText str

        Environment name args body ->
            renderEnvironment source latexState name args body

        LatexList latexList ->
            renderLatexList source latexState latexList

        LXString str ->
            case String.left 1 str of
                " " ->
                    Html.span [ HA.style "margin-left" "1px" ] [ Html.text str ]

                _ ->
                    Html.span [] [ Html.text str ]

        NewCommand commandName numberOfArgs commandBody ->
            Html.span [] []

        LXError  error ->
            let
              _ = Debug.log "YY:ERR" error
            in
            Html.p [ HA.style "color" "red" ] [ Html.text <| "\n---\n\n" ++ (ErrorMessages.renderErrors source error) ]


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


inlineMathText : String -> Html msg
inlineMathText str =
    mathText <| "$ " ++ String.trim str ++ " $"


displayMathText : String -> Html msg
displayMathText str =
    let
        str2 =
            String.trim str
    in
        mathText <| "$$\n" ++ str2 ++ "\n$$"



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
renderLatexList : String -> LatexState -> List LatexExpression -> Html msg
renderLatexList source latexState latexList =
    -- ### Render2.renderLatexList
    latexList
        |> spacify
        |> List.map (render source latexState)
        |> (\list -> Html.span [ HA.style "margin-bottom" "10px" ] list)


spacify : List LatexExpression -> List LatexExpression
spacify latexList =
    -- ### Reader2.spacify
    latexList
        |> ListMachine.run addSpace



{- RENDER MACRO -}


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
        , ( "backslash", \s x y z -> renderBackslash s x z )
        , ( "texarg",  \s x y z -> renderTexArg s x z )
        , ( "ref", \s x y z -> renderRef s x z )
        , ( "medskip", \s x y z -> renderMedSkip s x z )
        , ( "smallskip", \s x y z -> renderSmallSkip s x z )
        , ( "section", \s x y z -> renderSection s x z )
        , ( "section*", \s x y z -> renderSectionStar s x z )
        , ( "subsection", \s x y z -> renderSubsection s x z )
        , ( "subsection*", \s x y z -> renderSubsectionStar s x z )
        , ( "subsubsection", \s x y z -> renderSubSubsection  s x z )
        , ( "subsubsection*", \s x y z -> renderSubSubsectionStar s x z )
        , ( "setcounter", \s x y z -> renderSetCounter s x z )
        , ( "subheading", \s x y z -> renderSubheading s x z )
        , ( "tableofcontents", \s x y z -> renderTableOfContents s x z )
        , ( "innertableofcontents", \s x y z -> renderInnerTableOfContents s x z )
        , ( "red", \s x y z -> renderRed s x z )
        , ( "blue", \s x y z -> renderBlue s x z )
        , ( "highlight", \s x y z -> renderHighlighted s x z )
        , ( "strike", \s x y z -> renderStrikeThrough s x z )
        , ( "term", \s x y z -> renderTerm s x z )
        , ( "xlink", \s x y z -> renderXLink s x z )
        , ( "xlinkPublic", \s x y z -> renderXLinkPublic s x z )
        , ( "documentTitle", \s x y z -> renderDocumentTitle s x z )
        , ( "title", \s x y z -> renderTitle x z )
        , ( "author", \s x y z -> renderAuthor s x z )
        , ( "date", \s x y z -> renderDate s x z )
        , ( "revision", \s x y z -> renderRevision s x z )
        , ( "email", \s x y z -> renderEmail s x z )
        , ( "setdocid", \s x y z -> renderSetDocId s x z )
        , ( "setclient", \s x y z -> renderSetClient s x z )
        , ( "strong", \s x y z -> renderStrong s x z )
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


renderArgList : String -> LatexState -> List LatexExpression -> List (Html msg)
renderArgList source latexState args =
    args |> List.map (render source latexState)


enclose : Html msg -> Html msg
enclose msg =
    Html.span [] [ Html.text "{", msg, Html.text "}" ]


oneSpace : Html msg
oneSpace =
    Html.text " "



{- RENDER INDIVIDUAL MACROS -}


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
            Internal.Render.renderArg 0 latexState args

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
            Internal.Render.renderArg 0 latexState args

        url =
            "https://ellie-app.com/embed/" ++ id

        title_ =
            Internal.Render.renderArg 1 latexState args

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
            Internal.Render.renderArg 0 latexState args

        title =
            Internal.Render.renderArg 1 latexState args
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
            Internal.Render.renderArg 0 emptyLatexState args

        ref =
            getCrossReference key latexState
    in
        Html.i [] [ Html.text "(", Html.text ref, Html.text ")" ]


renderHRef : String -> LatexState -> List LatexExpression -> Html msg
renderHRef source latexState args =
    let
        url =
            Internal.Render.renderArg 0 emptyLatexState args

        label =
            Internal.Render.renderArg 1 emptyLatexState args
    in
        Html.a [ HA.href url, HA.target "_blank" ] [ Html.text label ]


renderImage : String -> LatexState -> List LatexExpression -> Html msg
renderImage source latexState args =
    let
        url =
            Internal.Render.renderArg 0 latexState args

        label =
            Internal.Render.renderArg 1 latexState args

        attributeString =
            Internal.Render.renderArg 2 latexState args

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
            Internal.Render.renderArg 0 latexState args

        imageUrl =
            Internal.Render.renderArg 1 latexState args

        attributeString =
            Internal.Render.renderArg 2 latexState args

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
            Internal.Render.renderArg 0 latexState args
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
            Internal.Render.renderArg 0 latexState args

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
            Internal.Render.renderArg 0 latexState args

        ref =
            idPhrase "section" sectionName
    in
        Html.h2 (headingStyle ref 24) [ Html.text <| sectionName ]


renderSubsection : String -> LatexState -> List LatexExpression -> Html msg
renderSubsection _ latexState args =
    let
        sectionName =
            Internal.Render.renderArg 0 latexState args

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
            Internal.Render.renderArg 0 latexState args

        ref =
            idPhrase "subsection" sectionName
    in
        Html.h3 (headingStyle ref 12) [ Html.text <| sectionName ]


renderSubSubsection : String -> LatexState -> List LatexExpression -> Html msg
renderSubSubsection _ latexState args =
    let
        sectionName =
            Internal.Render.renderArg 0 latexState args

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
            Internal.Render.renderArg 0 latexState args

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
            Internal.Render.renderArg 0 latexState args
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
            Internal.Render.renderArg 0 latexState args
    in
        Html.span [ HA.style "color" "red" ] [ Html.text <| arg ]


renderBlue : String -> LatexState -> List LatexExpression -> Html msg
renderBlue _ latexState args =
    let
        arg =
            Internal.Render.renderArg 0 latexState args
    in
        Html.span [ HA.style "color" "blue" ] [ Html.text <| arg ]


renderHighlighted : String -> LatexState -> List LatexExpression -> Html msg
renderHighlighted _ latexState args =
    let
        arg =
            Internal.Render.renderArg 0 latexState args
    in
        Html.span [ HA.style "background-color" "yellow" ] [ Html.text <| arg ]


renderStrikeThrough : String -> LatexState -> List LatexExpression -> Html msg
renderStrikeThrough _ latexState args =
    let
        arg =
            Internal.Render.renderArg 0 latexState args
    in
        Html.span [ HA.style "text-decoration" "line-through" ] [ Html.text <| arg ]


renderTerm : String -> LatexState -> List LatexExpression -> Html msg
renderTerm _ latexState args =
    let
        arg =
            Internal.Render.renderArg 0 latexState args
    in
        Html.i [] [ Html.text <| arg ]


renderXLink : String -> LatexState -> List LatexExpression -> Html msg
renderXLink _ latexState args =
    let
        id =
            Internal.Render.renderArg 0 latexState args

        ref =
            getDictionaryItem "setclient" latexState ++ "/" ++ id

        label =
            Internal.Render.renderArg 1 latexState args
    in
        Html.a [ HA.href ref ] [ Html.text label ]


renderXLinkPublic : String -> LatexState -> List LatexExpression -> Html msg
renderXLinkPublic _ latexState args =
    let
        id =
            Internal.Render.renderArg 0 latexState args

        ref =
            getDictionaryItem "setclient" latexState ++ "/" ++ id

        label =
            Internal.Render.renderArg 1 latexState args
    in
        Html.a [ HA.href ref ] [ Html.text label ]



{- END OF INDIVIDUAL MACROS -}
{- SMACROS -}


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
                Internal.Render.renderArg 0 latexState optArgs
            else
                Internal.Render.renderArg 0 latexState args

        id =
            "bibitem:" ++ label
    in
        Html.div []
            [ Html.strong [ HA.id id, HA.style "margin-right" "10px" ] [ Html.text <| "[" ++ label ++ "]" ]
            , Html.span [] [ render source latexState body ]
            ]



{- END RENDER INDIVIDUAL SMACROS -}
{- LISTS -}


renderItem : String -> LatexState -> Int -> LatexExpression -> Html msg
renderItem source latexState level latexExpression =
    Html.li [ HA.style "margin-bottom" "8px" ] [ render source latexState latexExpression ]



{- END LISTS -}
{- BEGIN ENVIRONMENTS -}


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



{- INDIVIDUAL ENVIRONMENT RENDERERS -}


renderEnvironmentDict : Dict.Dict String (String -> LatexState -> List LatexExpression -> LatexExpression -> Html msg)
renderEnvironmentDict =
    Dict.fromList
        [
          ( "align", \s x a y -> renderAlignEnvironment s x y )
        , ( "center", \s x a y -> renderCenterEnvironment s x y )
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
        ]


renderAlignEnvironment : String -> LatexState -> LatexExpression -> Html msg
renderAlignEnvironment source latexState body =
    let
        r =
            Internal.Render.render latexState body

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

        content =
            "\n\\begin{align*}\n" ++ addendum ++ r ++ "\n\\end{align*}\n"
    in
        displayMathText content


renderCenterEnvironment : String -> LatexState -> LatexExpression -> Html msg
renderCenterEnvironment source latexState body =
    let
        r =
            render source latexState body
    in
        Html.div [ HA.class "center" ] [ r ]


renderCommentEnvironment : String -> LatexState -> LatexExpression -> Html msg
renderCommentEnvironment source latexState body =
    Html.div [] []


renderEnumerate : String -> LatexState -> LatexExpression -> Html msg
renderEnumerate source latexState body =
    Html.ol [ HA.style "margin-top" "0px" ] [ render source latexState body ]


renderDefItemEnvironment : String -> LatexState -> List LatexExpression -> LatexExpression -> Html msg
renderDefItemEnvironment source latexState optArgs body =
    Html.div []
        [ Html.strong [] [ Html.text <| Internal.Render.renderArg 0 latexState optArgs ]
        , Html.div [ HA.style "margin-left" "25px", HA.style "margin-top" "10px" ] [ render source latexState body ]
        ]


{-| XXX
-}
renderEqnArray : String -> LatexState -> LatexExpression -> Html msg
renderEqnArray source latexState body =
    displayMathText (Internal.Render.render latexState body)


renderEquationEnvironment : String -> LatexState -> LatexExpression -> Html msg
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

        r =
            Internal.Render.render latexState body
    in
        displayMathText <| "\\begin{equation}" ++ r ++ addendum ++ "\\end{equation}"



-- "\n$$\n\\begin{equation}" ++ addendum ++ r ++ "\\end{equation}\n$$\n"


renderIndentEnvironment : String -> LatexState -> LatexExpression -> Html msg
renderIndentEnvironment source latexState body =
    Html.div [ HA.style "margin-left" "2em" ] [ render source latexState body ]


renderItemize : String -> LatexState -> LatexExpression -> Html msg
renderItemize source latexState body =
    Html.ul [ HA.style "margin-top" "0px" ] [ render source latexState body ]


renderListing : String -> LatexState -> LatexExpression -> Html msg
renderListing source latexState body =
    let
        text =
            Internal.Render.render latexState body

        lines =
            Utility.addLineNumbers text
    in
        Html.pre [ HA.class "verbatim" ] [ Html.text lines ]


renderMacros : String -> LatexState -> LatexExpression -> Html msg
renderMacros source latexState body =
    displayMathText (Internal.Render.render latexState body)


renderQuotation : String -> LatexState -> LatexExpression -> Html msg
renderQuotation source latexState body =
    Html.div [ HA.style "margin-left" "2em", HA.style "font-style" "italic" ] [ render source latexState body ]


renderTabular : String -> LatexState -> LatexExpression -> Html msg
renderTabular source latexState body =
    Html.table
        [ HA.style "border-spacing" "20px 10px"
        , HA.style "margin-left" "-20px"
        ]
        [ renderTableBody source body ]


renderCell : String -> LatexExpression -> Html msg
renderCell source cell =
    case cell of
        LXString s ->
            Html.td [] [ Html.text s ]

        InlineMath s ->
            Html.td [] [ inlineMathText s ]

        Macro s x y ->
            Html.td [] [ renderMacro source emptyLatexState s x y ]

        -- ###
        _ ->
            Html.td [] []


renderRow : String -> LatexExpression -> Html msg
renderRow source row =
    case row of
        LatexList row_ ->
            Html.tr [] (row_ |> List.map (renderCell source))

        _ ->
            Html.tr [] []


renderTableBody : String -> LatexExpression -> Html msg
renderTableBody source body =
    case body of
        LatexList body_ ->
            Html.tbody [] (body_ |> List.map (renderRow source))

        _ ->
            Html.tbody [] []


renderTheBibliography : String -> LatexState -> LatexExpression -> Html msg
renderTheBibliography source latexState body =
    Html.div [] [ render source latexState body ]


renderUseForWeb : String -> LatexState -> LatexExpression -> Html msg
renderUseForWeb source latexState body =
    displayMathText (Internal.Render.render latexState body)


renderVerbatim : String -> LatexState -> LatexExpression -> Html msg
renderVerbatim source latexState body =
    let
        body2 =
            Internal.Render.render latexState body
    in
        Html.pre [ HA.style "margin-top" "-14px", HA.style "margin-bottom" "0px", HA.style "margin-left" "25px", HA.style "font-size" "14px" ] [ Html.text body2 ]


renderVerse : String -> LatexState -> LatexExpression -> Html msg
renderVerse source latexState body =
    Html.div [ HA.style "white-space" "pre-line" ] [ Html.text (String.trim <| Internal.Render.render latexState body) ]
