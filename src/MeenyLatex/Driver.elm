module MeenyLatex.Driver
    exposing
        ( emptyEditRecord
        , getRenderedText
        , parse
        , render
        , setup
        , update
        )

{-| This library exposes functions for rendering MiniLaTeX text into HTML.


# API

@docs render, setup, getRenderedText, parse, update, emptyEditRecord

-}

import Html exposing (Html)
import MeenyLatex.Differ as Differ exposing (EditRecord)
import MeenyLatex.LatexDiffer as MiniLatexDiffer
import MeenyLatex.LatexState exposing (emptyLatexState)
import MeenyLatex.Paragraph as Paragraph
import MeenyLatex.Parser as MiniLatexParser exposing (LatexExpression)
import MeenyLatex.LatexState exposing (LatexState)
import MeenyLatex.Render2 as Render


-- exposing (render, renderString)


{-| The function call `render macros sourceTest` produces
an HTML string corresponding to the MeenyLatex source text
`sourceText`. The macro definitions in `macros`
are appended to this string and are used by MathJax
to render purely mathematical text. The `macros` string
may be empty. Thus, if

macros = ""
source = "\italic{Test:}\n\n$$a^2 + b^2 = c^2$$\n\n\strong{Q.E.D.}"

then `render macros source` yields the HTML text

    <p>
    <span class=italic>Test:</span></p>
      <p>
        $$a^2 + b^2 = c^2$$
      </p>
    <p>

    <span class="strong">Q.E.D.</span>
    </p>

-}
render : String -> String -> Html msg
render macroDefinitions text =
    MiniLatexDiffer.createEditRecord Render.renderLatexList emptyLatexState text
        |> getRenderedText macroDefinitions
        |> Html.div []


{-| Parse the given text and return an AST represeting it.
-}
parse : String -> List (List LatexExpression)
parse text =
    text
        |> Paragraph.logicalParagraphify
        |> List.map MiniLatexParser.parse


pTags : EditRecord (Html msg) -> List String
pTags editRecord =
    editRecord.idList |> List.map (\x -> "<p id=\"" ++ x ++ "\">")


{-| Using the renderedParagraph list of the editRecord,
return a string representing the HTML of the paragraph list
of the editRecord. Append the macroDefinitions for use
by MathJax.
-}
getRenderedText : String -> EditRecord (Html msg) -> List (Html msg)
getRenderedText macroDefinitions editRecord =
    editRecord.renderedParagraphs



-- let
--     paragraphs =
--         editRecord.renderedParagraphs
--
--     pTagList =
--         pTags editRecord
-- in
--     List.map2 (\para pTag -> pTag ++ "\n" ++ para ++ "\n</p>") paragraphs pTagList
--         |> String.join "\n\n"
--         |> (\x -> x ++ "\n\n" ++ macroDefinitions)
--


{-| Create an EditRecord from a string of MiniLaTeX text:

> editRecord = setup 0 source

        { paragraphs =
            [ "\\italic{Test:}\n\n"
            , "$$a^2 + b^2 = c^2$$\n\n"
            , "\\strong{Q.E.D.}\n\n"
            ]
        , renderedParagraphs =
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
        } : MeenyLatex.Differ.EditRecord

-}
setup : Int -> String -> EditRecord (Html msg)
setup seed text =
    MiniLatexDiffer.update seed Render.renderLatexList Render.renderString Differ.emptyEditRecordHtmlMsg text


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
emptyEditRecord : EditRecord (Html msg)
emptyEditRecord =
    Differ.emptyEditRecordHtmlMsg


{-| Update the given edit record with modified text.
Thus, if

    source2 = "\italic{Test:}\n\n$$a^3 + b^3 = c^3$$\n\n\strong{Q.E.D.}"

then we can say

editRecord2 = update 0 source2 editRecord

The `update` function attempts to re-render only the paragraph
which have been changed. It will always update the text correctly,
but its efficiency depends on the nature of the edit. This is
because the "differ" used to detect changes is rather crude.

-}
update : Int -> EditRecord (Html msg) -> String -> EditRecord (Html msg)
update seed editRecord text =
    MiniLatexDiffer.update seed Render.renderLatexList Render.renderString editRecord text
