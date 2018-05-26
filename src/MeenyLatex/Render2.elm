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
            -- renderSMacro latexState name optArgs args le
            Html.span [] [ Html.text <| " ((SMACRO)) " ]

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
        , ( "italic", \x y z -> renderItalic x z )
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
            Html.img
                [ HA.src url, HA.alt label, HA.align "left", HA.width imageAttrs.width ]
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



--
-- "<iframe "
-- ++ src
-- ++ style
-- ++ sandbox
-- ++ " ></iframe>\n<center style=\"margin-top: -10px;\"><a href=\""
-- ++ url
-- ++ "\" target=_blank>"
-- ++ title
-- ++ "</a></center>"
{- END RENDER INDIVIDUAL MACROS -}
-- " <span>[<a href=\"#bib:" ++ label ++ "\">" ++ label ++ "</a>]</span>"
-- renderOptArgList : LatexState -> List LatexExpression -> String
-- renderOptArgList latexState args =
--     args |> List.map (render latexState) |> List.map (\x -> "[" ++ x ++ "]") |> String.join ""
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





   renderMacroDict : Dict.Dict String (LatexState -> List LatexExpression -> List LatexExpression -> String)
   renderMacroDict =
       Dict.fromList
           [

           , ( "imageref", \x y z -> renderImageRef x z )
           , ( "index", \x y z -> "" )

           , ( "label", \x y z -> "" )
           , ( "tableofcontents", \x y z -> renderTableOfContents x z )
           , ( "maketitle", \x y z -> renderTitle x z )
           , ( "mdash", \x y z -> "&mdash;" )
           , ( "ndash", \x y z -> "&ndash;" )
           , ( "newcommand", \x y z -> renderNewCommand x z )
           , ( "ref", \x y z -> renderRef x z )
           , ( "section", \x y z -> renderSection x z )
           , ( "section*", \x y z -> renderSectionStar x z )
           , ( "setcounter", \x y z -> "" )
           , ( "medskip", \x y z -> renderMedSkip x z )
           , ( "smallskip", \x y z -> renderSmallSkip x z )

           , ( "subheading", \x y z -> renderSubheading x z )
           , ( "subsection", \x y z -> renderSubsection x z )
           , ( "subsection*", \x y z -> renderSubsectionStar x z )
           , ( "subsubsection", \x y z -> renderSubSubsection x z )
           , ( "subsubsection*", \x y z -> renderSubSubsectionStar x z )
           , ( "title", \x y z -> "" )
           , ( "author", \x y z -> "" )
           , ( "date", \x y z -> "" )
           , ( "revision", \x y z -> "" )
           , ( "email", \x y z -> "" )
           , ( "term", \x y z -> renderTerm x z )
           , ( "xlink", \x y z -> renderXLink x z )
           , ( "xlinkPublic", \x y z -> renderXLinkPublic x z )
           ]


   renderSMacroDict : Dict.Dict String (LatexState -> List LatexExpression -> List LatexExpression -> LatexExpression -> String)
   renderSMacroDict =
       Dict.fromList
           [ ( "bibitem", \latexState optArgs args body -> renderBibItem latexState optArgs args body )
           ]



   -- SMacro String (List LatexExpression) (List LatexExpression) LatexExpression









   renderSMacro : LatexState -> String -> List LatexExpression -> List LatexExpression -> LatexExpression -> Html msg
   renderSMacro latexState name optArgs args le =
       case Dict.get name renderSMacroDict of
           Just f ->
               f latexState optArgs args le

           Nothing ->
               "<span style=\"color: red;\">\\" ++ name ++ renderArgList emptyLatexState args ++ " " ++ render latexState le ++ "</span>"



   {- INDIVIDUAL MACRO RENDERERS -}


   renderBozo : LatexState -> List LatexExpression -> Html msg
   renderBozo latexState args =
       "bozo{" ++ renderArg 0 latexState args ++ "}{" ++ renderArg 1 latexState args ++ "}"


   renderBibItem : LatexState -> List LatexExpression -> List LatexExpression -> LatexExpression -> Html msg
   renderBibItem latexState optArgs args body =
       let
           label =
               if List.length optArgs == 1 then
                   renderArg 0 latexState optArgs
               else
                   renderArg 0 latexState args
       in
           " <p id=\"bib:" ++ label ++ "\">[" ++ label ++ "] " ++ render latexState body ++ "</p>\n"





   {-| Needs work
   -}


   renderInlineComment : LatexState -> List LatexExpression -> String
   renderInlineComment latexState args =
       ""



   renderNewCommand : LatexState -> List LatexExpression -> String
   renderNewCommand latexState args =
       let
           command =
               renderArg 0 latexState args

           definition =
               renderArg 1 latexState args
       in
           "\\newcommand{" ++ command ++ "}{" ++ definition ++ "}"


   renderRef : LatexState -> List LatexExpression -> String
   renderRef latexState args =
       let
           key =
               renderArg 0 latexState args
       in
           getCrossReference key latexState


   makeId : String -> String -> String
   makeId prefix name =
       String.join ":" [ prefix, compress ":" name ]


   userReplace : String -> (Regex.Match -> String) -> String -> String
   userReplace userRegex replacer string =
       case Regex.fromString userRegex of
           Nothing ->
               string

           Just regex ->
               Regex.replace regex replacer string


   {-| map str to lower case and squeeze out bad characters
   -}
   compress : String -> String -> String
   compress replaceBlank str =
       str
           |> String.toLower
           |> String.replace " " replaceBlank
           |> userReplace "[,;.!?&_]" (\_ -> "")


   idPhrase : String -> String -> String
   idPhrase prefix name =
       let
           compressedName =
               name |> String.toLower |> String.replace " " ":"
       in
           String.join "" [ "id=\"_", makeId prefix name, "\"" ]


   tag : String -> String -> String -> String
   tag tagName tagProperties content =
       String.join "" [ "<", tagName, " ", tagProperties, " ", ">", content, "</", tagName, ">" ]


   renderSection : LatexState -> List LatexExpression -> String
   renderSection latexState args =
       let
           sectionName =
               renderArg 0 latexState args

           s1 =
               getCounter "s1" latexState

           label =
               if s1 > 0 then
                   String.fromInt s1 ++ " "
               else
                   ""
       in
           tag "h2" (idPhrase "section" sectionName) (label ++ sectionName)


   renderSectionStar : LatexState -> List LatexExpression -> String
   renderSectionStar latexState args =
       let
           sectionName =
               renderArg 0 latexState args
       in
           tag "h2" (idPhrase "section" sectionName) sectionName





   renderSubheading : LatexState -> List LatexExpression -> String
   renderSubheading latexState args =
       "<div class=\"subheading\">" ++ renderArg 0 latexState args ++ "</div>"


   renderSubsection : LatexState -> List LatexExpression -> String
   renderSubsection latexState args =
       let
           sectionName =
               renderArg 0 latexState args

           s1 =
               getCounter "s1" latexState

           s2 =
               getCounter "s2" latexState

           label =
               if s1 > 0 then
                   String.fromInt s1 ++ "." ++ String.fromInt s2 ++ " "
               else
                   ""
       in
           tag "h3" (idPhrase "subsection" sectionName) (label ++ sectionName)


   renderSubsectionStar : LatexState -> List LatexExpression -> String
   renderSubsectionStar latexState args =
       let
           sectionName =
               renderArg 0 latexState args
       in
           tag "h3" (idPhrase "subsection" sectionName) sectionName


   renderSubSubsection : LatexState -> List LatexExpression -> String
   renderSubSubsection latexState args =
       let
           sectionName =
               renderArg 0 latexState args

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
       in
           tag "h4" (idPhrase "subsubsection" sectionName) (label ++ sectionName)


   renderSubSubsectionStar : LatexState -> List LatexExpression -> String
   renderSubSubsectionStar latexState args =
       let
           sectionName =
               renderArg 0 latexState args
       in
           tag "h4" (idPhrase "subsubsection" sectionName) sectionName


   renderTerm : LatexState -> List LatexExpression -> String
   renderTerm latexState args =
       let
           arg =
               renderArg 0 latexState args
       in
           " <span class=italic>" ++ arg ++ "</span>"


   renderXLink : LatexState -> List LatexExpression -> String
   renderXLink latexState args =
       let
           id =
               renderArg 0 latexState args

           label =
               renderArg 1 latexState args
       in
           " <a href=\"" ++ Configuration.client ++ "##document/" ++ id ++ "\">" ++ label ++ "</a>"


   renderXLinkPublic : LatexState -> List LatexExpression -> String
   renderXLinkPublic latexState args =
       let
           id =
               renderArg 0 latexState args

           label =
               renderArg 1 latexState args
       in
           " <a href=\"" ++ Configuration.client ++ "##public/" ++ id ++ "\">" ++ label ++ "</a>"



   {- TABLE OF CONTENTS -}


   renderTitle : LatexState -> List LatexExpression -> String
   renderTitle latexState list =
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
               "\n<div class=\"title\">" ++ title ++ "</div>"

           bodyParts =
               [ "<div class=\"authorinfo\">", author, email, date, revisionText, "</div>\n" ]
                   |> List.filter (\x -> x /= "")

           bodyPart =
               String.join "\n" bodyParts
       in
           String.join "\n" [ titlePart, bodyPart ]


   renderTableOfContents : LatexState -> List LatexExpression -> String
   renderTableOfContents latexState list =
       let
           innerPart =
               makeTableOfContents latexState
       in
           "\n<p class=\"tocTitle\">Table of Contents</p>\n<ul class=\"ListEnvironment\">\n" ++ innerPart ++ "\n</ul>\n"


   makeTableOfContents : LatexState -> String
   makeTableOfContents latexState =
       List.foldl (\tocItem acc -> acc ++ [ makeTocItem tocItem ]) [] (List.indexedMap Tuple.pair latexState.tableOfContents)
           |> String.join "\n"


   makeTocItem : ( Int, TocEntry ) -> String
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

           innerTag =
               ti.label ++ " " ++ tag "a" href ti.name
       in
           tag "li" classProperty innerTag


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




   renderImageRef : LatexState -> List LatexExpression -> String
   renderImageRef latexState args =
       let
           url =
               renderArg 0 latexState args

           imageUrl =
               renderArg 1 latexState args

           attributeString =
               renderArg 2 latexState args

           imageAttrs =
               parseImageAttributes attributeString
       in
           if imageAttrs.float == "left" then
               Html.a url (Html.div [ imageFloatLeftStyle imageAttrs ] [ Html.img imageUrl imageAttrs ])
           else if imageAttrs.float == "right" then
               Html.a url (Html.div [ imageFloatRightStyle imageAttrs ] [ Html.img imageUrl imageAttrs ])
           else if imageAttrs.align == "center" then
               Html.a url (Html.div [ imageCenterStyle imageAttrs ] [ Html.img imageUrl imageAttrs ])
           else
               Html.a url (Html.div [ imageCenterStyle imageAttrs ] [ Html.img imageUrl imageAttrs ])

-}
