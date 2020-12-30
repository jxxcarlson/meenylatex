module MiniLatex.Markdown exposing (convert)

{-| Convert MiniLaTeX to Markdown


# API

@docs render

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
import Internal.Render
import Internal.RenderToString
import Internal.Utility as Utility
import Json.Encode
import MiniLatex.EditSimple
import Parser exposing (DeadEnd, Problem(..))
import Regex
import String
import SvgParser


convert : String -> String
convert source =
    let
        data =
            MiniLatex.EditSimple.init 0 source Nothing

        astList =
            data.astList

        latexState =
            data.latexState

        paragraphs : List String.String
        paragraphs =
            renderLatexListToList latexState astList
    in
    String.join "\n\n" paragraphs


{-| The main rendering function. Compute a String value
from the current LatexState and a LatexExpression.
-}
render : String -> LatexState -> LatexExpression -> String
render source latexState latexExpression =
    case latexExpression of
        Comment str ->
            ""

        Macro name optArgs args ->
            renderMacro source latexState name optArgs args

        SMacro name optArgs args le ->
            renderSMacro source latexState name optArgs args le

        Item level latexExpr ->
            -- TODO: fix spacing issue
            "- " ++ renderItem source latexState level latexExpr

        InlineMath str ->
            "$" ++ Internal.MathMacro.evalStr latexState.mathMacroDictionary str ++ "$"

        DisplayMath str ->
            "$$\n" ++ Internal.MathMacro.evalStr latexState.mathMacroDictionary str ++ "\n$$"

        Environment name args body ->
            renderEnvironment source latexState name args body

        LatexList latexList ->
            renderLatexList source latexState (spacify latexList)

        LXString str ->
            str

        NewCommand commandName numberOfArgs commandBody ->
            ""

        LXError error ->
            "Errpr"


{-| Like `render`, but renders a list of LatexExpressions
to Html mgs
-}
renderLatexList : String -> LatexState -> List LatexExpression -> String
renderLatexList source latexState latexList =
    latexList
        |> List.map (render source latexState)
        |> String.join "\n"


renderLatexListToList : LatexState -> List ( String, List LatexExpression ) -> List String
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


parseString : LatexState -> String -> List ( String, List LatexExpression )
parseString latexState source =
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
renderString2 : LatexState -> String -> String
renderString2 latexState source =
    let
        render_ : ( String, List LatexExpression ) -> String
        render_ ( source_, ast ) =
            renderLatexList source_ latexState ast
    in
    source
        |> parseString latexState
        |> List.map render_
        |> String.join ""


{-| Parse a string, then render it.
-}
renderString : LatexState -> String -> String
renderString latexState source =
    let
        paragraphs : List String
        paragraphs =
            Paragraph.logicalParagraphify source

        parse : String.String -> ( String, List LatexExpression )
        parse paragraph =
            ( paragraph, Internal.Parser.parse paragraph |> spacify )

        render_ : ( String, List LatexExpression ) -> String
        render_ ( source_, ast ) =
            renderLatexList source_ latexState ast
    in
    paragraphs
        |> List.map parse
        |> List.map render_
        |> String.join "\n\n"


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


mathText : DisplayMode -> String -> String
mathText displayMode content =
    case displayMode of
        InlineMathMode ->
            "$" ++ content ++ "$"

        DisplayMathMode ->
            "$$\n" ++ content ++ "\n$$"


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


inlineMathText : LatexState -> String -> String
inlineMathText latexState str_ =
    let
        str =
            Internal.MathMacro.evalStr latexState.mathMacroDictionary str_
    in
    mathText InlineMathMode (String.trim str)


displayMathText : LatexState -> String -> String
displayMathText latexState str_ =
    let
        str =
            Internal.MathMacro.evalStr latexState.mathMacroDictionary str_
    in
    mathText DisplayMathMode (String.trim str)


displayMathText_ : LatexState -> String -> String
displayMathText_ latexState str =
    mathText DisplayMathMode (String.trim str)


displayMathTextWithLabel_ : LatexState -> String -> String -> String
displayMathTextWithLabel_ _ str _ =
    String.trim str



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


renderMacro : String -> LatexState -> String -> List LatexExpression -> List LatexExpression -> String
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


renderArg : String -> Int -> LatexState -> List LatexExpression -> String
renderArg source k latexState args =
    render source latexState (getElement k args)


reproduceMacro : String -> String -> LatexState -> List LatexExpression -> List LatexExpression -> String
reproduceMacro source name latexState optArgs args =
    let
        renderedArgs =
            renderArgList source latexState args
                |> List.map enclose
                |> String.join ""
    in
    "@red[" ++ "\\" ++ name ++ renderedArgs ++ "]"


boost : (x -> z -> output) -> (x -> y -> z -> output)
boost f =
    \x y z -> f x z



-- MACRO DICTIONARY


renderMacroDict : Dict.Dict String (String -> LatexState -> List LatexExpression -> List LatexExpression -> String)
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
        , ( "attachNote", \s x y z -> renderAttachNote s x z )
        , ( "highlight", \s x y z -> renderHighlighted s x z )
        , ( "strike", \s x y z -> renderStrikeThrough s x z )
        , ( "term", \s x y z -> renderTerm s x z )
        , ( "xlink", \s x y z -> renderXLink s x z )
        , ( "ilink1", \s x y z -> renderILink s x z )
        , ( "ilink2", \s x y z -> renderILink s x z )
        , ( "ilink3", \s x y z -> renderILink s x z )
        , ( "include", \s x y z -> renderInclude s x z )
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
        , ( "uuid", \s x y z -> renderUuid s x z )
        ]


renderDollar : String -> LatexState -> List LatexExpression -> String
renderDollar _ atexState args =
    "$"


renderBegin : String -> LatexState -> List LatexExpression -> String
renderBegin _ latexState args =
    "\\begin"


renderEnd : String -> LatexState -> List LatexExpression -> String
renderEnd _ atexState args =
    "\\end"


renderUuid : String -> LatexState -> List LatexExpression -> String
renderUuid _ _ _ =
    ""


renderPercent : String -> LatexState -> List LatexExpression -> String
renderPercent _ latexState args =
    "%"


renderArgList : String -> LatexState -> List LatexExpression -> List String
renderArgList source latexState args =
    args |> List.map (render source latexState)


enclose : String -> String
enclose msg =
    "{" ++ msg ++ "}"


oneSpace : String
oneSpace =
    " "



-- RENDER INDIVIUAL MACROS


renderItalic : String -> LatexState -> List LatexExpression -> String
renderItalic source latexState args =
    "*" ++ renderArg source 0 latexState args ++ "*"


renderStrong : String -> LatexState -> List LatexExpression -> String
renderStrong source latexState args =
    "**" ++ renderArg source 0 latexState args ++ "**"


renderBigSkip : String -> LatexState -> List LatexExpression -> String
renderBigSkip _ latexState args =
    ""


renderMedSkip : String -> LatexState -> List LatexExpression -> String
renderMedSkip _ latexState args =
    ""


renderSmallSkip : String -> LatexState -> List LatexExpression -> String
renderSmallSkip _ latexState args =
    ""


renderCite : String -> LatexState -> List LatexExpression -> String
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
    label_ ++ ": " ++ ref ++ ": " ++ label


renderCode : String -> LatexState -> List LatexExpression -> String
renderCode source latexState args =
    let
        arg =
            renderArg source 0 latexState args
    in
    "`" ++ arg ++ "`"


renderEllie : String -> LatexState -> List LatexExpression -> String
renderEllie _ latexState args =
    "ELLIE"


renderIFrame : String -> LatexState -> List LatexExpression -> String
renderIFrame _ latexState args =
    "IFRAME"


renderEqRef : String -> LatexState -> List LatexExpression -> String
renderEqRef source latexState args =
    let
        key =
            Internal.RenderToString.renderArg 0 emptyLatexState args

        ref =
            getCrossReference key latexState
    in
    "(" ++ key ++ ", " ++ ref ++ ")"


renderHRef : String -> LatexState -> List LatexExpression -> String
renderHRef source latexState args =
    let
        url =
            Internal.RenderToString.renderArg 0 emptyLatexState args

        label =
            Internal.RenderToString.renderArg 1 emptyLatexState args
    in
    "[" ++ label ++ "](" ++ url ++ ")"



-- RENDER IMAGE


renderImage : String -> LatexState -> List LatexExpression -> String
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
    "![" ++ label ++ "](" ++ url ++ ")"


renderImageRef : String -> LatexState -> List LatexExpression -> String
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
    "![" ++ "IMAGE" ++ "](" ++ url ++ ")"


renderIndex : String -> LatexState -> List LatexExpression -> String
renderIndex source x z =
    ""


renderLabel : String -> LatexState -> List LatexExpression -> String
renderLabel source x z =
    ""



-- TABLE OF CONTENTS


renderTableOfContents : String -> LatexState -> List LatexExpression -> String
renderTableOfContents _ latexState list =
    let
        innerPart =
            makeTableOfContents latexState
    in
    "### Table of Contents\n\n" ++ String.join "\n" innerPart


renderInnerTableOfContents : String -> LatexState -> List LatexExpression -> String
renderInnerTableOfContents _ latexState args =
    let
        s1 =
            getCounter "s1" latexState

        prefix =
            String.fromInt s1 ++ "."

        innerPart =
            makeInnerTableOfContents prefix latexState
    in
    "### Table of Contents\n\n" ++ String.join "\n" innerPart


{-| Build a table of contents from the
current LatexState; use only level 1 items
-}
makeTableOfContents : LatexState -> List String
makeTableOfContents latexState =
    let
        toc =
            List.filter (\item -> item.level == 1) latexState.tableOfContents
    in
    List.foldl (\tocItem acc -> acc ++ [ makeTocItem "" tocItem ]) [] (List.indexedMap Tuple.pair toc)


{-| Build a table of contents from the
current LatexState; use only level 2 items
-}
makeInnerTableOfContents : String -> LatexState -> List String
makeInnerTableOfContents prefix latexState =
    let
        toc =
            List.filter (\item -> item.level == 2) latexState.tableOfContents
    in
    List.foldl (\tocItem acc -> acc ++ [ makeTocItem prefix tocItem ]) [] (List.indexedMap Tuple.pair toc)


makeTocItem : String -> ( Int, TocEntry ) -> String
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
    "1. " ++ ti.name


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
            "#"

        2 ->
            "##"

        3 ->
            "###"

        _ ->
            "####"



-- RENDER MACRO


renderMdash : String -> LatexState -> List LatexExpression -> String
renderMdash source latexState args =
    "—"


renderNdash : String -> LatexState -> List LatexExpression -> String
renderNdash source latexState args =
    "–"


renderUnderscore : String -> LatexState -> List LatexExpression -> String
renderUnderscore source latexState args =
    "_"


renderBackslash : String -> LatexState -> List LatexExpression -> String
renderBackslash source latexState args =
    "\\" ++ renderArg source 0 latexState args


renderTexArg : String -> LatexState -> List LatexExpression -> String
renderTexArg source latexState args =
    "{" ++ renderArg source 0 latexState args ++ "}"


renderRef : String -> LatexState -> List LatexExpression -> String
renderRef source latexState args =
    let
        key =
            Internal.RenderToString.renderArg 0 latexState args
    in
    getCrossReference key latexState


docUrl : LatexState -> String
docUrl latexState =
    "DOC URL"


idPhrase : String -> String -> String
idPhrase prefix name =
    let
        compressedName =
            name |> String.toLower |> String.replace " " "_"
    in
    makeId prefix name


renderSection : String -> LatexState -> List LatexExpression -> String
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
    "# " ++ sectionName


renderSectionStar : String -> LatexState -> List LatexExpression -> String
renderSectionStar _ latexState args =
    let
        sectionName =
            Internal.RenderToString.renderArg 0 latexState args

        ref =
            idPhrase "section" sectionName
    in
    "# " ++ sectionName


renderSubsection : String -> LatexState -> List LatexExpression -> String
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
    "## " ++ sectionName


renderSubsectionStar : String -> LatexState -> List LatexExpression -> String
renderSubsectionStar _ latexState args =
    let
        sectionName =
            Internal.RenderToString.renderArg 0 latexState args

        ref =
            idPhrase "subsection" sectionName
    in
    "## " ++ sectionName


renderSubSubsection : String -> LatexState -> List LatexExpression -> String
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
    "#### " ++ sectionName


renderSubSubsectionStar : String -> LatexState -> List LatexExpression -> String
renderSubSubsectionStar _ latexState args =
    let
        sectionName =
            Internal.RenderToString.renderArg 0 latexState args

        ref =
            idPhrase "subsubsection" sectionName
    in
    "### " ++ sectionName


renderDocumentTitle : String -> LatexState -> List LatexExpression -> String
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

        bodyParts =
            [ author, email, date, revisionText ]
                |> List.filter (\x -> x /= "")
                |> String.join "\n"
    in
    "# " ++ title ++ "\n\n" ++ bodyParts


renderSetCounter : String -> LatexState -> List LatexExpression -> String
renderSetCounter _ latexState list =
    ""


renderSubheading : String -> LatexState -> List LatexExpression -> String
renderSubheading _ latexState args =
    let
        title =
            Internal.RenderToString.renderArg 0 latexState args
    in
    "### " ++ title


renderMakeTitle : String -> LatexState -> List LatexExpression -> String
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

        bodyParts =
            [ author, email, date, revisionText ]
                |> List.filter (\x -> x /= "")
                |> String.join "\n"
    in
    "# " ++ title ++ "\n\n" ++ bodyParts


renderTitle : LatexState -> List LatexExpression -> String
renderTitle latexState args =
    ""


renderAuthor : String -> LatexState -> List LatexExpression -> String
renderAuthor _ latexState args =
    ""


renderSetDocId : String -> LatexState -> List LatexExpression -> String
renderSetDocId _ latexState args =
    ""


renderSetClient : String -> LatexState -> List LatexExpression -> String
renderSetClient _ latexState args =
    ""


renderDate : String -> LatexState -> List LatexExpression -> String
renderDate _ latexState args =
    ""


renderRevision : String -> LatexState -> List LatexExpression -> String
renderRevision _ latexState args =
    ""


renderMainTableOfContents : String -> LatexState -> List LatexExpression -> String
renderMainTableOfContents source latexState args =
    ""


renderEmail : String -> LatexState -> List LatexExpression -> String
renderEmail _ latexState args =
    ""


renderRed : String -> LatexState -> List LatexExpression -> String
renderRed _ latexState args =
    let
        arg =
            Internal.RenderToString.renderArg 0 latexState args
    in
    "@red[" ++ arg ++ "]"


renderBlue : String -> LatexState -> List LatexExpression -> String
renderBlue _ latexState args =
    let
        arg =
            Internal.RenderToString.renderArg 0 latexState args
    in
    "@blue[" ++ arg ++ "]"


renderRemote : String -> LatexState -> List LatexExpression -> String
renderRemote _ latexState args =
    let
        arg =
            Internal.RenderToString.renderArg 0 latexState args
    in
    "REMOTE: " ++ arg


renderLocal : String -> LatexState -> List LatexExpression -> String
renderLocal _ latexState args =
    let
        arg =
            Internal.RenderToString.renderArg 0 latexState args
    in
    "LOCAL: " ++ arg


renderAttachNote : String -> LatexState -> List LatexExpression -> String
renderAttachNote _ latexState args =
    -- TODO: Finish this
    let
        author =
            Internal.RenderToString.renderArg 0 latexState args

        content =
            Internal.RenderToString.renderArg 1 latexState args
    in
    "@blue" ++ author ++ "]\n\n" ++ "@highlight[" ++ content ++ "]"


renderHighlighted : String -> LatexState -> List LatexExpression -> String
renderHighlighted _ latexState args =
    let
        arg =
            Internal.RenderToString.renderArg 0 latexState args
    in
    "@highlight[" ++ arg ++ "]"


renderStrikeThrough : String -> LatexState -> List LatexExpression -> String
renderStrikeThrough _ latexState args =
    let
        arg =
            Internal.RenderToString.renderArg 0 latexState args
    in
    "~~" ++ arg ++ "~~"


renderTerm : String -> LatexState -> List LatexExpression -> String
renderTerm _ latexState args =
    let
        arg =
            Internal.RenderToString.renderArg 0 latexState args
    in
    "*" ++ arg ++ "*"


renderXLink : String -> LatexState -> List LatexExpression -> String
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
    "[" ++ label ++ "}(" ++ ref ++ ")"


renderILink : String -> LatexState -> List LatexExpression -> String
renderILink _ latexState args =
    "iLink"


renderInclude : String -> LatexState -> List LatexExpression -> String
renderInclude _ latexState args =
    "INCLUDE"


renderXLinkPublic : String -> LatexState -> List LatexExpression -> String
renderXLinkPublic _ latexState args =
    let
        id =
            Internal.RenderToString.renderArg 0 latexState args

        ref =
            getDictionaryItem "setclient" latexState ++ "/" ++ id

        label =
            Internal.RenderToString.renderArg 1 latexState args
    in
    String.join ", " [ id, ref, label ]



-- SMACRO


renderSMacroDict : Dict.Dict String (String -> LatexState -> List LatexExpression -> List LatexExpression -> LatexExpression -> String)
renderSMacroDict =
    Dict.fromList
        [ ( "bibitem", \source latexState optArgs args body -> renderBibItem source latexState optArgs args body )
        ]


renderSMacro : String -> LatexState -> String -> List LatexExpression -> List LatexExpression -> LatexExpression -> String
renderSMacro source latexState name optArgs args le =
    case Dict.get name renderSMacroDict of
        Just f ->
            f source latexState optArgs args le

        Nothing ->
            reproduceSMacro source name latexState optArgs args le


reproduceSMacro : String -> String -> LatexState -> List LatexExpression -> List LatexExpression -> LatexExpression -> String
reproduceSMacro source name latexState optArgs args le =
    let
        renderedOptArgs =
            renderArgList source latexState optArgs |> List.map enclose |> String.join ""

        renderedArgs =
            renderArgList source latexState args |> List.map enclose |> String.join ""

        renderedLe =
            render source latexState le |> enclose
    in
    "\\" ++ name ++ renderedOptArgs ++ renderedArgs ++ renderedLe


renderBibItem : String -> LatexState -> List LatexExpression -> List LatexExpression -> LatexExpression -> String
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
    "**[" ++ label ++ "]**" ++ render source latexState body


renderItem : String -> LatexState -> Int -> LatexExpression -> String
renderItem source latexState level latexExpression =
    "- " ++ render source latexState latexExpression



{- END LISTS -}
-- RENDER ENVIRONMENTS


renderEnvironment : String -> LatexState -> String -> List LatexExpression -> LatexExpression -> String
renderEnvironment source latexState name args body =
    environmentRenderer source name latexState args body


environmentRenderer : String -> String -> (LatexState -> List LatexExpression -> LatexExpression -> String)
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


renderDefaultEnvironment : String -> String -> LatexState -> List LatexExpression -> LatexExpression -> String
renderDefaultEnvironment source name latexState args body =
    if List.member name theoremLikeEnvironments then
        renderTheoremLikeEnvironment source latexState name args body

    else
        renderDefaultEnvironment2 source latexState (Utility.capitalize name) args body


renderTheoremLikeEnvironment : String -> LatexState -> String -> List LatexExpression -> LatexExpression -> String
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
    "**" ++ Utility.capitalize name ++ ".**\n" ++ r


renderDefaultEnvironment2 : String -> LatexState -> String -> List LatexExpression -> LatexExpression -> String
renderDefaultEnvironment2 source latexState name args body =
    render source latexState body



-- RENDER INDIVIDUAL ENVIRNOMENTS


renderEnvironmentDict : Dict.Dict String (String -> LatexState -> List LatexExpression -> LatexExpression -> String)
renderEnvironmentDict =
    Dict.fromList
        [ ( "align", \s x a y -> renderAlignEnvironment s x y )
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
        , ( "mathmacro", \s x a y -> renderMathMacros s x y )
        , ( "textmacro", \s x a y -> renderTextMacros s x y )
        , ( "svg", \s x a y -> renderSvg s x y )
        ]


renderSvg : String -> LatexState -> LatexExpression -> String
renderSvg source latexState body =
    "@@svg\n" ++ render "" latexState body


renderAlignEnvironment : String -> LatexState -> LatexExpression -> String
renderAlignEnvironment source latexState body =
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
    displayMathTextWithLabel_ latexState content tag


renderCenterEnvironment : String -> LatexState -> LatexExpression -> String
renderCenterEnvironment source latexState body =
    render source latexState body


renderCommentEnvironment : String -> LatexState -> LatexExpression -> String
renderCommentEnvironment source latexState body =
    ""


renderEnumerate : String -> LatexState -> LatexExpression -> String
renderEnumerate source latexState body =
    render source latexState body


renderDefItemEnvironment : String -> LatexState -> List LatexExpression -> LatexExpression -> String
renderDefItemEnvironment source latexState optArgs body =
    --Html.div []
    --    [ Html.strong [] [ Html.text <| Internal.RenderToString.renderArg 0 latexState optArgs ]
    --    , Html.div [ HA.style "margin-left" "25px", HA.style "margin-top" "10px" ] [ render source latexState body ]
    --    ]
    -- TODO
    "DEF ITEM ENVIRONMENT"


{-| XXX
-}
renderEqnArray : String -> LatexState -> LatexExpression -> String
renderEqnArray source latexState body =
    let
        body1 =
            Internal.RenderToString.render latexState body

        body2 =
            -- REVIEW: changed for KaTeX
            "$$\n\\begin{aligned}" ++ body1 ++ "\\end{aligned}\n$$"
    in
    body2


renderEquationEnvironment : String -> LatexState -> LatexExpression -> String
renderEquationEnvironment source latexState body =
    let
        contents =
            case body of
                LXString str ->
                    str
                        |> String.trim
                        |> Internal.MathMacro.evalStr latexState.mathMacroDictionary
                        |> Internal.ParserHelpers.removeLabel

                _ ->
                    "Parser error in render equation environment"
    in
    "\n$$\n" ++ contents ++ "\n$$\n"


renderIndentEnvironment : String -> LatexState -> LatexExpression -> String
renderIndentEnvironment source latexState body =
    render source latexState body


renderItemize : String -> LatexState -> LatexExpression -> String
renderItemize source latexState body =
    -- TODO: fix space issue
    render source latexState body


renderListing : String -> LatexState -> LatexExpression -> String
renderListing source latexState body =
    let
        text =
            Internal.RenderToString.render latexState body

        lines =
            Utility.addLineNumbers text
    in
    "```\n" ++ lines ++ "\n```"


renderMacros : String -> LatexState -> LatexExpression -> String
renderMacros source latexState body =
    displayMathText latexState (Internal.RenderToString.render latexState body)


renderMathMacros : String -> LatexState -> LatexExpression -> String
renderMathMacros source latexState body =
    ""


renderTextMacros : String -> LatexState -> LatexExpression -> String
renderTextMacros source latexState body =
    ""


renderQuotation : String -> LatexState -> LatexExpression -> String
renderQuotation source latexState body =
    "> " ++ render source latexState body


renderTabular : String -> LatexState -> LatexExpression -> String
renderTabular source latexState body =
    renderTableBody source latexState body


renderCell : String -> LatexState -> LatexExpression -> String
renderCell source latexState cell =
    case cell of
        LXString s ->
            s

        InlineMath s ->
            inlineMathText latexState s

        Macro s x y ->
            renderMacro source emptyLatexState s x y

        _ ->
            "TABLE CELL"


renderRow : String -> LatexState -> LatexExpression -> String
renderRow source latexState row =
    case row of
        LatexList row_ ->
            row_
                |> List.map (renderCell source latexState)
                |> String.join " | "
                |> (\x -> "| " ++ x ++ " |")

        _ ->
            "ROW"


renderTableBody : String -> LatexState -> LatexExpression -> String
renderTableBody source latexState body =
    case body of
        LatexList body_ ->
            body_
                |> List.map (renderRow source latexState)
                |> String.join "\n"

        _ ->
            "EMPTY TABLE"


renderTheBibliography : String -> LatexState -> LatexExpression -> String
renderTheBibliography source latexState body =
    render source latexState body


renderUseForWeb : String -> LatexState -> LatexExpression -> String
renderUseForWeb source latexState body =
    displayMathText latexState (Internal.RenderToString.render latexState body)


renderVerbatim : String -> LatexState -> LatexExpression -> String
renderVerbatim source latexState body =
    "````\n" ++ String.trim (Internal.RenderToString.render latexState body) ++ "\n````"


renderVerse : String -> LatexState -> LatexExpression -> String
renderVerse source latexState body =
    ">> " ++ (String.trim <| Internal.RenderToString.render latexState body)
