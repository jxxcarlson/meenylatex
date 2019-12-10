module MiniLatex.Edit exposing (init, get, update, Data, emptyData, parse)

import Html exposing (Html)
import Html.Attributes as HA
import Html.Keyed as Keyed
import Internal.Differ as Differ exposing (EditRecord)
import Internal.LatexDiffer as MiniLatexDiffer
import Internal.LatexState exposing (LatexState, emptyLatexState)
import Internal.Paragraph as Paragraph
import Internal.Parser as MiniLatexParser exposing (LatexExpression)
import MiniLatex.Render2 as Render


{-

initializeEditRecord -> init
updateEditRecord -> update
getRenderedText -> get


-}

{-| Data for differential parsing and rendering -}
type alias Data a = Differ.EditRecord a

{-| Create an EditRecord from a string of MiniLaTeX text.
The `seed` is used for creating id's for rendered paragraphs
in order to help Elm's runtime optimize diffing for rendering
text.

> editRecord = Internal.initialize source

        { paragraphs =
            [ "\\italic{Test:}\n\n"
            , "$$a^2 + b^2 = c^2$$\n\n"
            , "\\strong{Q.E.D.}\n\n"
            ]
        , renderedParagraphs = ((an Html msg value representing))
            [ "  <span class=italic>Test:</span>"
            , " $$a^2 + b^2 = c^2$$"
            , "  <span class=\"strong\">Q.E.D.</span> "
            ]
        , latexState =
            { counters =
                Dict.fromList
                    [ ( "eqno", 0 )
                    , ( "s1", 0 )
                    , ( "s2", 0 )
                    , ( "s3", 0 )
                    , ( "tno", 0 )
                    ]
            , crossReferences = Dict.fromList []
            }
        , idList = []
        , idListStart = 0
        } : Internal.Differ.EditRecord

-}
init : Int -> String -> Data (Html msg)
init seed text =
    MiniLatexDiffer.update seed Render.renderLatexList Render.renderString Differ.emptyHtmlMsgRecord text


{-| Update the given edit record with modified text.
Thus, if

    source2 = "\italic{Test:}\n\n$$a^3 + b^3 = c^3$$\n\n\strong{Q.E.D.}"

then we can say

editRecord2 = updateEditRecord 0 source2 editRecord

The `updateEditRecord` function attempts to re-render only the (logical) paragraphs
which have been changed. It will always update the text correctly,
but its efficiency depends on the nature of the edit. This is
because the "differ" used to detect changes is rather crude.

-}
update : Int -> Data (Html msg) -> String -> Data (Html msg)
update seed editRecord text =
    MiniLatexDiffer.update seed Render.renderLatexList Render.renderString editRecord text



{-| Using the renderedParagraph list of the editRecord,
return an HTML element represeing the paragraph list
of the editRecord.
-}
get : EditRecord (Html msg) -> List (Html msg)
get editRecord =
    let
        paragraphs =
            editRecord.renderedParagraphs

        ids =
            editRecord.idList
    in
        List.map2 (\para id -> Keyed.node "p" [ HA.id id, HA.style "margin-bottom" "10px" ] [ ( id, para ) ]) paragraphs ids



{-| Return an empty EditRecord

        { paragraphs = []
        , renderedParagraphs = []
        , latexState =
            { counters =
                Dict.fromList
                    [ ( "eqno", 0 )
                    , ( "s1", 0 )
                    , ( "s2", 0 )
                    , ( "s3", 0 )
                    , ( "tno", 0 )
                    ]
            , crossReferences = Dict.fromList []
            }
        , idList = []
        , idListStart = 0
        }

-}
emptyData : EditRecord (Html msg)
emptyData =
    Differ.emptyHtmlMsgRecord

{-| Parse the given text and return an AST representing it.
-}
parse : String -> List (List LatexExpression)
parse text =
    text
        |> Paragraph.logicalParagraphify
        |> List.map MiniLatexParser.parse


