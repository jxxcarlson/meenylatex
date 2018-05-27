module MeenyLatex.Render2 exposing (..)

-- exposing
--     ( makeTableOfContents
--     , render
--     , renderLatexList
--     , renderString
--     , transformText
--     )

import Dict
import Html exposing (Html)
import Html.Attributes
import Json.Encode


-- import List.Extra

import MeenyLatex.Render
import MeenyLatex.Configuration as Configuration
import MeenyLatex.ErrorMessages as ErrorMessages
import MeenyLatex.Image as Image exposing (..)
import MeenyLatex.JoinStrings as JoinStrings
import MeenyLatex.LatexState
    exposing
        ( LatexState
        , TocEntry
        , emptyLatexState
        , getCounter
        , getCrossReference
        , getDictionaryItem
        )
import MeenyLatex.Parser exposing (LatexExpression(..), defaultLatexList, latexList)
import MeenyLatex.Utility as Utility
import Parser
import Regex
import String
import Html.Attributes as HA


{-
   transformText : LatexState -> String -> String
   transformText latexState text =
       renderString latexList latexState text

-}
-- |> \str -> "\n<p>" ++ str ++ "</p>\n"
{- FUNCTIONS FOR TESTING THINGS -}


getElement : Int -> List LatexExpression -> LatexExpression
getElement k list =
    Utility.getAt k list |> Maybe.withDefault (LXString "xxx")


parseString parser str =
    Parser.run parser str



-- renderString latexList latexState text
{-
   renderString : Parser.Parser LatexExpression -> LatexState -> String -> String
   renderString parser latexState str =
       let
           parserOutput =
               Parser.run parser str

           renderOutput =
               case parserOutput of
                   Ok latexExpression ->
                       render latexState latexExpression |> postProcess

                   Err error ->
                       "Error: " ++ Parser.deadEndsToString error
       in
           renderOutput


   postProcess : String -> String
   postProcess str =
       str
           |> String.replace "---" "&mdash;"
           |> String.replace "--" "&ndash;"
           |> String.replace "\\&" "&#38"


-}
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
        [ Html.Attributes.property "content" (Json.Encode.string content) ]
        []


render : LatexState -> LatexExpression -> Html msg
render latexState latexExpression =
    case latexExpression of
        Comment str ->
            Html.p [] [ Html.text <| "((" ++ str ++ "))" ]

        Macro name optArgs args ->
            renderMacro latexState name optArgs args

        SMacro name optArgs args le ->
            renderSMacro latexState name optArgs args le

        -- Html.span [] [ Html.text <| " ((SMACRO)) " ]
        Item level latexExpr ->
            -- renderItem latexState level latexExpr
            Html.span [] [ Html.text <| " ((ITEM)) " ]

        InlineMath str ->
            mathText <| "\\(" ++ str ++ "\\)"

        DisplayMath str ->
            mathText <| "\\[" ++ str ++ "\\]"

        Environment name args body ->
            -- renderEnvironment latexState name args body
            Html.p [] [ Html.text <| " ((ENVIRONMENT)) " ]

        LatexList latexList ->
            renderLatexList latexState latexList

        LXString str ->
            Html.span [] [ Html.text str ]

        LXError error ->
            -- List.map ErrorMessages.renderError error |> String.join "; "
            Html.p [] [ Html.text <| "((ERROR))" ]



{- PROCESS SPACES BETWEEN ELEMENTS -}


type Spacing
    = SpaceAfter
    | SpaceBefore
    | NoSpace


lastChar =
    String.right 1


firstChar =
    String.left 1


spaceBefore str =
    if List.member (lastChar str) [ "(" ] then
        NoSpace
    else
        SpaceBefore


spaceAfter str =
    if List.member (firstChar str) [ ")", ".", ",", "?", "!", ";", ":" ] then
        NoSpace
    else
        SpaceAfter


putSpace : LatexExpression -> LatexExpression -> ( LatexExpression, Spacing )
putSpace le1 le2 =
    case ( le1, le2 ) of
        ( _, LXString "!!END" ) ->
            ( le1, NoSpace )

        ( _, LXString str ) ->
            ( le1, spaceAfter str )

        ( LXString str, _ ) ->
            ( le1, spaceBefore str )

        ( _, _ ) ->
            ( le1, NoSpace )


putSpaces : List LatexExpression -> List ( LatexExpression, Spacing )
putSpaces latexList =
    let
        latexList2 =
            (List.drop 1 latexList) ++ [ LXString "!!END" ]
    in
        List.map2 putSpace latexList latexList2


processLatexListWithSpacing : List ( LatexExpression, Spacing ) -> List LatexExpression
processLatexListWithSpacing latexListWithSpacing =
    List.map processLatexExpressionWithSpacing latexListWithSpacing


processLatexExpressionWithSpacing : ( LatexExpression, Spacing ) -> LatexExpression
processLatexExpressionWithSpacing ( expr, spacing ) =
    case ( expr, spacing ) of
        ( _, NoSpace ) ->
            expr

        ( LXString str, SpaceAfter ) ->
            LXString (str ++ " ")

        ( LXString str, SpaceBefore ) ->
            LXString (" " ++ str)

        ( _, _ ) ->
            expr


renderLatexList : LatexState -> List LatexExpression -> Html msg
renderLatexList latexState latexList =
    latexList
        |> putSpaces
        |> processLatexListWithSpacing
        |> (\list -> Html.span [] (List.map (render latexState) list))



{- RENDER MACRO -}


renderMacro : LatexState -> String -> List LatexExpression -> List LatexExpression -> Html msg
renderMacro latexState name optArgs args =
    (macroRenderer name) latexState optArgs args


renderArg : Int -> LatexState -> List LatexExpression -> Html msg
renderArg k latexState args =
    render latexState (getElement k args)


macroRenderer : String -> (LatexState -> List LatexExpression -> List LatexExpression -> Html msg)
macroRenderer name latexState optArgs args =
    case Dict.get name renderMacroDict of
        Just f ->
            f latexState optArgs args

        Nothing ->
            reproduceMacro name latexState optArgs args


reproduceMacro : String -> LatexState -> List LatexExpression -> List LatexExpression -> Html msg
reproduceMacro name latexState optArgs args =
    let
        renderedArgs =
            renderArgList latexState args |> List.map enclose
    in
        Html.span []
            ([ Html.text <| "\\" ++ name ] ++ renderedArgs)


boost : (x -> z -> output) -> (x -> y -> z -> output)
boost f =
    \x y z -> f x z


renderMacroDict : Dict.Dict String (LatexState -> List LatexExpression -> List LatexExpression -> Html.Html msg)
renderMacroDict =
    Dict.fromList
        [ ( "bigskip", \x y z -> renderBigSkip x z )
        , ( "medskip", \x y z -> renderMedSkip x z )
        , ( "smallskip", \x y z -> renderSmallSkip x z )
        , ( "bozo", boost renderBozo )
        , ( "cite", \x y z -> renderCite x z )
        , ( "code", \x y z -> renderCode x z )
        , ( "ellie", \x y z -> renderEllie x z )
        , ( "emph", \x y z -> renderItalic x z )
        , ( "eqref", \x y z -> renderEqRef x z )
        , ( "href", \x y z -> renderHRef x z )
        , ( "image", \x y z -> renderImage x z )
        , ( "imageref", \x y z -> renderImageRef x z )
        , ( "index", \x y z -> renderIndex x z )
        , ( "italic", \x y z -> renderItalic x z )
        , ( "label", \x y z -> renderLabel x z )
        , ( "maketitle", \x y z -> renderTitle x z )
        , ( "mdash", \x y z -> renderMdash x z )
        , ( "ndash", \x y z -> renderNdash x z )
        , ( "newcommand", \x y z -> renderNewCommand x z )
        , ( "ref", \x y z -> renderRef x z )
        , ( "medskip", \x y z -> renderMedSkip x z )
        , ( "smallskip", \x y z -> renderSmallSkip x z )
        , ( "section", \x y z -> renderSection x z )
        , ( "section*", \x y z -> renderSectionStar x z )
        , ( "subsection", \x y z -> renderSubsection x z )
        , ( "subsection*", \x y z -> renderSubsectionStar x z )
        , ( "subsubsection", \x y z -> renderSubSubsection x z )
        , ( "subsubsection*", \x y z -> renderSubSubsectionStar x z )
        , ( "setcounter", \x y z -> renderSetCounter x z )
        , ( "subheading", \x y z -> renderSubheading x z )
        , ( "tableofcontents", \x y z -> renderTableOfContents x z )
        , ( "term", \x y z -> renderTerm x z )
        , ( "xlink", \x y z -> renderXLink x z )
        , ( "xlinkPublic", \x y z -> renderXLinkPublic x z )
        , ( "documentTitle", \x y z -> renderDocumentTitle x z )
        , ( "title", \x y z -> renderTitle x z )
        , ( "author", \x y z -> renderAuthor x z )
        , ( "date", \x y z -> renderDate x z )
        , ( "revision", \x y z -> renderRevision x z )
        , ( "email", \x y z -> renderEmail x z )
        , ( "strong", \x y z -> renderStrong x z )
        ]


renderArgList : LatexState -> List LatexExpression -> List (Html msg)
renderArgList latexState args =
    args |> List.map (render latexState)


enclose : Html msg -> Html msg
enclose msg =
    Html.span [] [ Html.text "{", msg, Html.text "}" ]


oneSpace : Html msg
oneSpace =
    Html.text " "



{- RENDER INDIVIDUAL MACROS -}


renderBozo : LatexState -> List LatexExpression -> Html msg
renderBozo latexState args =
    Html.span []
        [ Html.text <| "\\bozo"
        , enclose <| renderArg 0 latexState args
        , enclose <| renderArg 1 latexState args
        ]


renderItalic : LatexState -> List LatexExpression -> Html msg
renderItalic latexState args =
    Html.i [] [ Html.text " ", renderArg 0 latexState args ]


renderStrong : LatexState -> List LatexExpression -> Html msg
renderStrong latexState args =
    Html.strong [] [ oneSpace, renderArg 0 latexState args ]


renderBigSkip : LatexState -> List LatexExpression -> Html msg
renderBigSkip latexState args =
    Html.div [] [ Html.br [] [] ]


renderMedSkip : LatexState -> List LatexExpression -> Html msg
renderMedSkip latexState args =
    Html.div [] [ Html.br [] [] ]


renderSmallSkip : LatexState -> List LatexExpression -> Html msg
renderSmallSkip latexState args =
    Html.div [] [ Html.br [] [] ]


renderCite : LatexState -> List LatexExpression -> Html msg
renderCite latexState args =
    let
        label_ =
            MeenyLatex.Render.renderArg 0 latexState args

        ref =
            getDictionaryItem ("bibitem:" ++ label_) latexState

        label =
            if ref /= "" then
                ref
            else
                label_
    in
        Html.span []
            [ Html.span [] [ Html.text "[" ]
            , Html.a [ Html.Attributes.href label ] [ Html.text label ]
            , Html.span [] [ Html.text "]" ]
            ]


renderCode : LatexState -> List LatexExpression -> Html msg
renderCode latexState args =
    let
        arg =
            renderArg 0 latexState args
    in
        Html.code [] [ oneSpace, arg ]


renderEllie : LatexState -> List LatexExpression -> Html msg
renderEllie latexState args =
    let
        src =
            "src =\"https://ellie-app.com/embed/" ++ (MeenyLatex.Render.renderArg 0 latexState args ++ "\"")

        url =
            Debug.log "URL"
                ("https://ellie-app.com/" ++ (MeenyLatex.Render.renderArg 0 latexState args))

        title_ =
            MeenyLatex.Render.renderArg 1 latexState args

        title =
            if title_ == "xxx" then
                "Link to Ellie"
            else
                title_
    in
        Html.iframe [ Html.Attributes.href url ] [ Html.text title ]


renderEqRef : LatexState -> List LatexExpression -> Html msg
renderEqRef latexState args =
    let
        key =
            MeenyLatex.Render.renderArg 0 emptyLatexState args

        ref =
            getCrossReference key latexState
    in
        Html.i [] [ Html.text "(", Html.text ref, Html.text ")" ]


renderHRef : LatexState -> List LatexExpression -> Html msg
renderHRef latexState args =
    let
        url =
            MeenyLatex.Render.renderArg 0 emptyLatexState args

        label =
            MeenyLatex.Render.renderArg 1 emptyLatexState args
    in
        Html.a [ Html.Attributes.href url ] [ Html.text label ]


renderImage : LatexState -> List LatexExpression -> Html msg
renderImage latexState args =
    let
        url =
            MeenyLatex.Render.renderArg 0 latexState args

        label =
            MeenyLatex.Render.renderArg 1 latexState args

        attributeString =
            MeenyLatex.Render.renderArg 2 latexState args

        imageAttrs =
            parseImageAttributes attributeString
    in
        if imageAttrs.float == "left" then
            Html.img [ HA.src url, HA.alt label, HA.align "left", HA.width imageAttrs.width ]
                [ Html.caption [] [ Html.text label ] ]
        else if imageAttrs.float == "right" then
            Html.img [ HA.src url, HA.alt label, HA.align "right", HA.width imageAttrs.width ]
                [ Html.caption [] [ Html.text label ] ]
        else if imageAttrs.align == "center" then
            Html.img [ HA.src url, HA.alt label, HA.align "center", HA.width imageAttrs.width ]
                [ Html.caption [] [ Html.text label ] ]
        else
            Html.img [ HA.src url, HA.alt label, HA.align "center", HA.width imageAttrs.width ]
                [ Html.caption [] [ Html.text label ] ]


renderImageRef : LatexState -> List LatexExpression -> Html msg
renderImageRef latexState args =
    let
        url =
            MeenyLatex.Render.renderArg 0 latexState args

        imageUrl =
            MeenyLatex.Render.renderArg 1 latexState args

        attributeString =
            MeenyLatex.Render.renderArg 2 latexState args

        imageAttrs =
            parseImageAttributes attributeString

        theImage =
            if imageAttrs.float == "left" then
                Html.img [ HA.src imageUrl, HA.alt "imagref", HA.align "left", HA.width imageAttrs.width ]
                    []
            else if imageAttrs.float == "right" then
                Html.img [ HA.src imageUrl, HA.alt "imagref", HA.align "right", HA.width imageAttrs.width ]
                    []
            else if imageAttrs.align == "center" then
                Html.img [ HA.src imageUrl, HA.alt "imagref", HA.align "center", HA.width imageAttrs.width ]
                    []
            else
                Html.img [ HA.src imageUrl, HA.alt "imagref", HA.align "center", HA.width imageAttrs.width ]
                    []
    in
        Html.a [ Html.Attributes.href url ] [ theImage ]


renderIndex : LatexState -> List LatexExpression -> Html msg
renderIndex x z =
    Html.span [] []


renderLabel : LatexState -> List LatexExpression -> Html msg
renderLabel x z =
    Html.span [] []



{- RENDER TABLE CONTENTS -}


renderTableOfContents : LatexState -> List LatexExpression -> Html msg
renderTableOfContents latexState list =
    let
        innerPart =
            makeTableOfContents latexState
    in
        Html.div []
            [ Html.h3 [] [ Html.text "Table of Contents" ]
            , Html.ul [] innerPart
            ]


makeTableOfContents : LatexState -> List (Html msg)
makeTableOfContents latexState =
    List.foldl (\tocItem acc -> acc ++ [ makeTocItem tocItem ]) [] (List.indexedMap Tuple.pair latexState.tableOfContents)


makeTocItem : ( Int, TocEntry ) -> Html msg
makeTocItem tocItem =
    let
        i =
            Tuple.first tocItem

        ti =
            Tuple.second tocItem

        classProperty =
            "class=\"sectionLevel" ++ String.fromInt ti.level ++ "\""

        id =
            makeId (sectionPrefix ti.level) ti.name

        href =
            "href=\"#_" ++ id ++ "\""
    in
        Html.li [] [ Html.a [ Html.Attributes.href href ] [ Html.text ti.name ] ]


makeId : String -> String -> String
makeId prefix name =
    String.join ":" [ prefix, compress ":" name ]


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


renderMdash : LatexState -> List LatexExpression -> Html msg
renderMdash latexState args =
    Html.span [] [ Html.text "---" ]


renderNdash : LatexState -> List LatexExpression -> Html msg
renderNdash latexState args =
    Html.span [] [ Html.text "--" ]


renderNewCommand : LatexState -> List LatexExpression -> Html msg
renderNewCommand latexState args =
    let
        command =
            MeenyLatex.Render.renderArg 0 latexState args

        definition =
            MeenyLatex.Render.renderArg 1 latexState args
    in
        Html.span [] [ Html.text <| "\\newcommand{" ++ command ++ "}{" ++ definition ++ "}" ]


renderRef : LatexState -> List LatexExpression -> Html msg
renderRef latexState args =
    let
        key =
            MeenyLatex.Render.renderArg 0 latexState args
    in
        Html.span [] [ Html.text <| getCrossReference key latexState ]


idPhrase : String -> String -> String
idPhrase prefix name =
    let
        compressedName =
            name |> String.toLower |> String.replace " " ":"
    in
        String.join "" [ "id=\"_", makeId prefix name, "\"" ]


renderSection : LatexState -> List LatexExpression -> Html msg
renderSection latexState args =
    let
        sectionName =
            MeenyLatex.Render.renderArg 0 latexState args

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
        Html.h2 [ HA.id ref ] [ Html.text <| label ++ sectionName ]


renderSectionStar : LatexState -> List LatexExpression -> Html msg
renderSectionStar latexState args =
    let
        sectionName =
            MeenyLatex.Render.renderArg 0 latexState args

        ref =
            idPhrase "section" sectionName
    in
        Html.h2 [ HA.id ref ] [ Html.text <| sectionName ]


renderSubsection : LatexState -> List LatexExpression -> Html msg
renderSubsection latexState args =
    let
        sectionName =
            MeenyLatex.Render.renderArg 0 latexState args

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
        Html.h3 [ HA.id ref ] [ Html.text <| label ++ sectionName ]


renderSubsectionStar : LatexState -> List LatexExpression -> Html msg
renderSubsectionStar latexState args =
    let
        sectionName =
            MeenyLatex.Render.renderArg 0 latexState args

        ref =
            idPhrase "subsection" sectionName
    in
        Html.h3 [ HA.id ref ] [ Html.text <| sectionName ]


renderSubSubsection : LatexState -> List LatexExpression -> Html msg
renderSubSubsection latexState args =
    let
        sectionName =
            MeenyLatex.Render.renderArg 0 latexState args

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


renderSubSubsectionStar : LatexState -> List LatexExpression -> Html msg
renderSubSubsectionStar latexState args =
    let
        sectionName =
            MeenyLatex.Render.renderArg 0 latexState args

        ref =
            idPhrase "subsubsection" sectionName
    in
        Html.h4 [ HA.id ref ] [ Html.text <| sectionName ]


renderDocumentTitle : LatexState -> List LatexExpression -> Html msg
renderDocumentTitle latexState list =
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


renderSetCounter : LatexState -> List LatexExpression -> Html msg
renderSetCounter latexState list =
    Html.span [] []


renderSubheading : LatexState -> List LatexExpression -> Html msg
renderSubheading latexState args =
    let
        title =
            MeenyLatex.Render.renderArg 0 latexState args
    in
        Html.div [ HA.class "subheading" ] [ Html.text <| title ]


renderTitle : LatexState -> List LatexExpression -> Html msg
renderTitle latexState args =
    Html.span [] []


renderAuthor : LatexState -> List LatexExpression -> Html msg
renderAuthor latexState args =
    Html.span [] []


renderDate : LatexState -> List LatexExpression -> Html msg
renderDate latexState args =
    Html.span [] []


renderRevision : LatexState -> List LatexExpression -> Html msg
renderRevision latexState args =
    Html.span [] []


renderEmail : LatexState -> List LatexExpression -> Html msg
renderEmail latexState args =
    Html.span [] []


renderTerm : LatexState -> List LatexExpression -> Html msg
renderTerm latexState args =
    let
        arg =
            MeenyLatex.Render.renderArg 0 latexState args
    in
        Html.i [] [ Html.text <| arg ]


renderXLink : LatexState -> List LatexExpression -> Html msg
renderXLink latexState args =
    let
        id =
            MeenyLatex.Render.renderArg 0 latexState args

        ref =
            Configuration.client ++ "##document/" ++ id

        label =
            MeenyLatex.Render.renderArg 1 latexState args
    in
        Html.a [ Html.Attributes.href ref ] [ Html.text label ]


renderXLinkPublic : LatexState -> List LatexExpression -> Html msg
renderXLinkPublic latexState args =
    let
        id =
            MeenyLatex.Render.renderArg 0 latexState args

        ref =
            Configuration.client ++ "##public/" ++ id

        label =
            MeenyLatex.Render.renderArg 1 latexState args
    in
        Html.a [ Html.Attributes.href ref ] [ Html.text label ]



{- END OF INDIVIDUAL MACROS -}
{- SMACROS -}


renderSMacroDict : Dict.Dict String (LatexState -> List LatexExpression -> List LatexExpression -> LatexExpression -> Html msg)
renderSMacroDict =
    Dict.fromList
        [ ( "bibitem", \latexState optArgs args body -> renderBibItem latexState optArgs args body )
        ]


renderSMacro : LatexState -> String -> List LatexExpression -> List LatexExpression -> LatexExpression -> Html msg
renderSMacro latexState name optArgs args le =
    case Dict.get name renderSMacroDict of
        Just f ->
            f latexState optArgs args le

        Nothing ->
            reproduceSMacro name latexState optArgs args le


reproduceSMacro : String -> LatexState -> List LatexExpression -> List LatexExpression -> LatexExpression -> Html msg
reproduceSMacro name latexState optArgs args le =
    let
        renderedOptArgs =
            renderArgList latexState optArgs |> List.map enclose

        renderedArgs =
            renderArgList latexState args |> List.map enclose

        renderedLe =
            render latexState le |> enclose
    in
        Html.span []
            ([ Html.text <| "\\" ++ name ] ++ renderedOptArgs ++ renderedArgs ++ [ renderedLe ])


renderBibItem : LatexState -> List LatexExpression -> List LatexExpression -> LatexExpression -> Html msg
renderBibItem latexState optArgs args body =
    let
        label =
            if List.length optArgs == 1 then
                MeenyLatex.Render.renderArg 0 latexState optArgs
            else
                MeenyLatex.Render.renderArg 0 latexState args

        id =
            "\"bib:" ++ label ++ "\""
    in
        Html.p [ HA.id id ] [ Html.text <| "[" ++ label ++ "] " ++ (MeenyLatex.Render.render latexState body) ]



{- END RENDER INDIVIDUAL MACROS -}
{-
   renderLatexList : LatexState -> List LatexExpression -> String
   renderLatexList latexState args =
       args |> List.map (render latexState) |> JoinStrings.joinList |> postProcess



   itemClass : Int -> String
   itemClass level =
       "item" ++ String.fromInt level


   renderItem : LatexState -> Int -> LatexExpression -> String
   renderItem latexState level latexExpression =
       "<li class=\"" ++ itemClass level ++ "\">" ++ render latexState latexExpression ++ "</li>\n"



   {- ENVIROMENTS -}


   renderEnvironmentDict : Dict.Dict String (LatexState -> List LatexExpression -> LatexExpression -> String)
   renderEnvironmentDict =
       Dict.fromList
           [ ( "align", \x a y -> renderAlignEnvironment x y )
           , ( "center", \x a y -> renderCenterEnvironment x y )
           , ( "comment", \x a y -> renderCommentEnvironment x y )
           , ( "indent", \x a y -> renderIndentEnvironment x y )
           , ( "enumerate", \x a y -> renderEnumerate x y )
           , ( "eqnarray", \x a y -> renderEqnArray x y )
           , ( "equation", \x a y -> renderEquationEnvironment x y )
           , ( "itemize", \x a y -> renderItemize x y )
           , ( "listing", \x a y -> renderListing x y )
           , ( "macros", \x a y -> renderMacros x y )
           , ( "quotation", \x a y -> renderQuotation x y )
           , ( "tabular", \x a y -> renderTabular x y )
           , ( "thebibliography", \x a y -> renderTheBibliography x y )
           , ( "maskforweb", \x a y -> renderCommentEnvironment x y )
           , ( "useforweb", \x a y -> renderUseForWeb x y )
           , ( "verbatim", \x a y -> renderVerbatim x y )
           , ( "verse", \x a y -> renderVerse x y )
           ]


   environmentRenderer : String -> (LatexState -> List LatexExpression -> LatexExpression -> String)
   environmentRenderer name =
       case Dict.get name renderEnvironmentDict of
           Just f ->
               f

           Nothing ->
               renderDefaultEnvironment name


   renderEnvironment : LatexState -> String -> List LatexExpression -> LatexExpression -> String
   renderEnvironment latexState name args body =
       environmentRenderer name latexState args body


   renderDefaultEnvironment : String -> LatexState -> List LatexExpression -> LatexExpression -> String
   renderDefaultEnvironment name latexState args body =
       if List.member name [ "theorem", "proposition", "corollary", "lemma", "definition" ] then
           renderTheoremLikeEnvironment latexState name args body
       else
           renderDefaultEnvironment2 latexState name args body


   renderIndentEnvironment : LatexState -> LatexExpression -> String
   renderIndentEnvironment latexState body =
       Html.div [ "style=\"margin-left:2em\"" ] [ render latexState body ]


   renderTheBibliography : LatexState -> LatexExpression -> String
   renderTheBibliography latexState body =
       Html.div [ "style=\"\"" ] [ render latexState body ]


   renderTheoremLikeEnvironment : LatexState -> String -> List LatexExpression -> LatexExpression -> String
   renderTheoremLikeEnvironment latexState name args body =
       let
           r =
               render latexState body

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
           "\n<div class=\"environment\">\n<strong>" ++ name ++ tnoString ++ "</strong>\n<div class=\"italic\">\n" ++ r ++ "\n</div>\n</div>\n"


   renderDefaultEnvironment2 : LatexState -> String -> List LatexExpression -> LatexExpression -> String
   renderDefaultEnvironment2 latexState name args body =
       let
           r =
               render latexState body
       in
           "\n<div class=\"environment\">\n<strong>" ++ name ++ "</strong>\n<div>\n" ++ r ++ "\n</div>\n</div>\n"


   renderCenterEnvironment latexState body =
       let
           r =
               render latexState body
       in
           "\n<div class=\"center\" >\n" ++ r ++ "\n</div>\n"


   renderCommentEnvironment latexState body =
       ""


   renderEquationEnvironment latexState body =
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
               render latexState body
       in
           "\n$$\n\\begin{equation}" ++ addendum ++ r ++ "\\end{equation}\n$$\n"


   renderAlignEnvironment latexState body =
       let
           r =
               render latexState body |> String.replace "\\ \\" "\\\\"

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
       in
           "\n$$\n\\begin{align}\n" ++ addendum ++ r ++ "\n\\end{align}\n$$\n"


   renderEqnArray latexState body =
       "\n$$\n" ++ render latexState body ++ "\n$$\n"


   renderEnumerate latexState body =
       "\n<ol>\n" ++ render latexState body ++ "\n</ol>\n"


   renderItemize latexState body =
       "\n<ul>\n" ++ render latexState body ++ "\n</ul>\n"


   renderMacros latexState body =
       "\n$$\n" ++ render latexState body ++ "\n$$\n"


   renderQuotation latexState body =
       Html.div [ "class=\"quotation\"" ] [ render latexState body ]


   renderVerse latexState body =
       Html.div [ "class=\"verse\"" ] [ String.trim <| render latexState body ]


   renderUseForWeb latexState body =
       "\n$$\n" ++ render latexState body ++ "\n$$\n"


   renderTabular latexState body =
       renderTableBody body


   renderCell cell =
       case cell of
           LXString s ->
               "<td>" ++ s ++ "</td>"

           InlineMath s ->
               "<td>$" ++ s ++ "$</td>"

           _ ->
               "<td>-</td>"


   renderRow row =
       case row of
           LatexList row_ ->
               row_
                   |> List.foldl (\cell acc -> acc ++ " " ++ renderCell cell) ""
                   |> (\row__ -> "<tr> " ++ row__ ++ " </tr>\n")

           _ ->
               "<tr>-</tr>"


   renderTableBody body =
       case body of
           LatexList body_ ->
               body_
                   |> List.foldl (\row acc -> acc ++ " " ++ renderRow row) ""
                   |> (\bod -> "<table>\n" ++ bod ++ "</table>\n")

           _ ->
               "<table>-</table>"


   renderVerbatim latexState body =
       let
           body2 =
               render latexState body |> String.replace ">" "&gt;" |> String.replace "<" "&lt;"
       in
           "\n<pre class=\"verbatim\">" ++ body2 ++ "</pre>\n"


   renderListing latexState body =
       let
           text =
               render latexState body
       in
           "\n<pre class=\"verbatim\">" ++ Utility.addLineNumbers text ++ "</pre>\n"



   {- MACROS: DISPATCHERS AND HELPERS -}


   -- evalDict : RenderDict -> String -> LatexState -> List LatexExpression -> List LatexExpression -> Maybe String
   -- evalDict dict str x y z =
   --     case (Dict.get str dict) of
   --         Just g ->
   --             Just (g x z)
   --
   --         Nothing ->
   --             Nothing
   --
   --






   -- SMacro String (List LatexExpression) (List LatexExpression) LatexExpression












   {- INDIVIDUAL MACRO RENDERERS -}


   renderBozo : LatexState -> List LatexExpression -> Html msg
   renderBozo latexState args =
       "bozo{" ++ renderArg 0 latexState args ++ "}{" ++ renderArg 1 latexState args ++ "}"






   {-| Needs work
   -}


   renderInlineComment : LatexState -> List LatexExpression -> String
   renderInlineComment latexState args =
       ""







-}
