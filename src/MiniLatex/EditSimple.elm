module MiniLatex.EditSimple exposing (Data, emptyData, init, update, get, render, LaTeXMsg)

{-| This module is like MiniLaTeX.Edit, except that the Data type, which is an
alias of the record type `Internal.DifferSimple.EditRecord`, contains no functions.


# API

@docs Data, emptyData, init, update, get, LaTeXMsg

-}

import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import Html.Keyed as Keyed
import Internal.Accumulator as Accumulator
import Internal.DifferSimple
import Internal.LatexDifferSimple
import Internal.Paragraph
import Internal.Parser
import Internal.Render
import MiniLatex.Render exposing (MathJaxRenderOption(..))


{-| Data structures and functions for managing interactive edits. The parse tree, rendered text, and other information needed
for this is stored in a value of type

    MiniLatex.Edit.Data

That data is initialized using

    data =
        init version text

where the version is an integer that distinguishes
different edits.


# API

@docs Data, emptyData, init, update, get, LaTeXMsg

-}
type alias Data =
    Internal.DifferSimple.EditRecord


{-| Use this type so that clicks in the rendered text can be detected
-}
type LaTeXMsg
    = IDClicked String


{-| Create Data from a string of MiniLaTeX text and a version number.
The version number should be different for each call of init.
-}
init : Int -> String -> Data
init version source =
    Internal.LatexDifferSimple.update
        version
        Internal.Parser.parse
        Internal.DifferSimple.emptyEditRecord
        source


{-| Update Data with modified text, re-parsing and re-rerendering changed elements.
-}
update : Int -> String -> Data -> Data
update version source editRecord =
    Internal.LatexDifferSimple.update
        version
        Internal.Parser.parse
        editRecord
        source


{-| Retrieve Html from a Data object and construct
the click handlers used to highlight the selected paragraph
(if any). Example:

    get "p.1.10" data

will retrieve the rendered text and will hightlight the paragraph
with ID "p.1.10". The ID decodes
as "paragraph 10, version 1". The version number
of a paragraph is incremented when it is edited.

-}



--render : MathJaxRenderOption -> String -> LatexState -> LatexExpression -> Html msg
--render mathJaxRenderOption source latexState latexExpression


render : String -> List (Html LaTeXMsg)
render source =
  source |> init 1 |> get "-"

get : String -> Data -> List (Html LaTeXMsg)
get selectedId data =
    let
        -- LatexState → List LatexExpression → List LatexExpression → Html msg
        ( _, paragraphs ) =
            Accumulator.render (Internal.Render.renderLatexList NoDelay "") data.latexState data.astList

        mark id_ =
            if selectedId == id_ then
                "select:" ++ id_

            else if String.left 7 id_ == "selected:" then
                String.dropLeft 7 id_

            else
                id_

        ids =
            data.idList
                |> List.map mark
 
        keyedNode : String -> Html LaTeXMsg -> Html LaTeXMsg
        keyedNode id para =
            Keyed.node "p"
                [ HA.id id
                , selectedStyle selectedId id
                , HE.onClick (IDClicked id)
                , HA.style "margin-bottom" "10px"
                ]
                [ ( id, para ) ]
    in
    List.map2 keyedNode ids paragraphs


selectedStyle : String -> String -> Html.Attribute LaTeXMsg
selectedStyle targetId currentId =
    case ("select:" ++ targetId) == currentId of
        True ->
            HA.style "background-color" highlightColor

        False ->
            HA.style "background-color" "#fff"


highlightColor =
    "#d7d6ff"


{-| Used for initialization.
-}
emptyData : Data
emptyData =
    Internal.DifferSimple.emptyEditRecord


{-| Parse the given text and return an AST representing it.
-}
parse : String -> ( List String, List (List Internal.Parser.LatexExpression) )
parse text =
    let
        paragraphs =
            Internal.Paragraph.logicalParagraphify text
    in
    ( paragraphs, List.map Internal.Parser.parse paragraphs )
