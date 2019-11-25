module MiniLatex
    exposing
        ( render
        , renderWithSeed
        , initializeEditRecord
        , getRenderedText
        , parse
        , updateEditRecord
        , emptyStringRecord
        , EditRecord
        )

{-| This library exposes functions for rendering MiniLaTeX text into HTML.
Most users will need only (1) the functions exposed in the `MiniLatex` module
and (2) `EditRecord`, which is exposed in the `Differ` module.

See [MiniLatex Live](https://jxxcarlson.github.io/app/miniLatexLive/index.html)
for a no-login demo of the MiniLatex technology. [Source code](https://github.com/jxxcarlson/MiniLatexLive)

See this [Hackernoon article](https://hackernoon.com/towards-latex-in-the-browser-2ff4d94a0c08)
for an explanation of the theory behind the MiniLatex package.


# API

@docs render, renderWithSeed, initializeEditRecord, getRenderedText, parse, updateEditRecord, emptyStringRecord

-}

import Html exposing (Html)
import Html.Attributes as HA
import Html.Keyed as Keyed
import Internal.Differ as Differ exposing (EditRecord)
import Internal.LatexDiffer as MiniLatexDiffer
import Internal.LatexState exposing (LatexState, emptyLatexState)
import Internal.Paragraph as Paragraph
import Internal.Parser as MiniLatexParser exposing (LatexExpression)
import MiniLatex.Render2 as Render


-- exposing (render, renderString)


{-| The function call `render macros sourceTest` produces
an HTML element or Html msg value corresponding to the MiniLatex source text
`sourceText`. The macro definitions in `macros`
are prepended to this string and are used by MathJax
to render purely mathematical text. The `macros` string
may be empty.
-}
render : String -> String -> Html msg
render macroDefinitions text =
    MiniLatexDiffer.createRecord Render.renderLatexList emptyLatexState (prependMacros macroDefinitions text)
        |> getRenderedText
        |> Html.div []


{-| Like render, but used the `seed` to define the ids for each paragraph.
-}
renderWithSeed : Int -> String -> String -> Html msg
renderWithSeed seed macroDefinitions text =
    MiniLatexDiffer.createRecordWithSeed seed Render.renderLatexList emptyLatexState (prependMacros macroDefinitions text)
        |> getRenderedText
        |> Html.div []


freshRender : String -> String -> Html msg
freshRender macroDefinitions text =
    MiniLatexDiffer.createRecord Render.renderLatexList emptyLatexState (prependMacros macroDefinitions text)
        |> getRenderedText
        |> Html.div []


prependMacros macros_ sourceText =
    "$$\n" ++ String.trim macros_ ++ "\n$$\n\n" ++ sourceText


{-| Parse the given text and return an AST represeting it.
-}
parse : String -> List (List LatexExpression)
parse text =
    text
        |> Paragraph.logicalParagraphify
        |> List.map MiniLatexParser.parse



type alias EditRecord a = Differ.EditRecord a

{-| Using the renderedParagraph list of the editRecord,
return an HTML element represeing the paragraph list
of the editRecord.
-}
getRenderedText : EditRecord (Html msg) -> List (Html msg)
getRenderedText editRecord =
    let
        paragraphs =
            editRecord.renderedParagraphs

        ids =
            editRecord.idList
    in
        List.map2 (\para id -> Keyed.node "p" [ HA.id id, HA.style "margin-bottom" "10px" ] [ ( id, para ) ]) paragraphs ids


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
initializeEditRecord : Int -> String -> EditRecord (Html msg)
initializeEditRecord seed text =
    MiniLatexDiffer.update seed Render.renderLatexList Render.renderString Differ.emptyHtmlMsgRecord text


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
emptyStringRecord : EditRecord (Html msg)
emptyStringRecord =
    Differ.emptyHtmlMsgRecord



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
updateEditRecord : Int -> EditRecord (Html msg) -> String -> EditRecord (Html msg)
updateEditRecord seed editRecord text =
    -- ### updateEditRecord, MiniLatexDiffer.update
    MiniLatexDiffer.update seed Render.renderLatexList Render.renderString editRecord text



--   MiniLatexDiffer.update seed Render.renderLatexList Render.renderString Differ.emptyHtmlMsgRecord text
