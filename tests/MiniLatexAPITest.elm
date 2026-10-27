module MiniLatexAPITest exposing (suite)

{-| Tests for the parse / update / render half of `MiniLatex.API`: a document
parsed once and then updated must render the same as one parsed from scratch.
-}

import Expect
import Html
import MiniLatex.API as API
import Test exposing (..)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector exposing (id, style, tag, text)


original : String
original =
    "First paragraph.\n\nSecond paragraph.\n\nThird paragraph."


edited : String
edited =
    "First paragraph.\n\nSecond paragraph, changed.\n\nThird paragraph."


rendered : API.Data -> Query.Single API.LaTeXMsg
rendered data =
    Html.div [] (API.renderData data) |> Query.fromHtml


suite : Test
suite =
    describe "MiniLatex.API parse/update"
        [ test "renderData of a parse has one paragraph per logical paragraph" <|
            \_ ->
                rendered (API.parse original)
                    |> Query.findAll [ tag "p" ]
                    |> Query.count (Expect.equal 3)
        , test "source returns the text that was parsed" <|
            \_ ->
                API.parse original
                    |> API.source
                    |> Expect.equal original
        , test "update replaces the source" <|
            \_ ->
                API.parse original
                    |> API.update edited
                    |> API.source
                    |> Expect.equal edited
        , test "update renders the edited paragraph" <|
            \_ ->
                rendered (API.parse original |> API.update edited)
                    |> Query.has [ text "changed." ]
        , test "update keeps the unchanged paragraphs" <|
            \_ ->
                rendered (API.parse original |> API.update edited)
                    |> Query.findAll [ tag "p" ]
                    |> Query.count (Expect.equal 3)
        , test "update keeps the ids of unchanged paragraphs, so their DOM is reused" <|
            \_ ->
                rendered (API.parse original |> API.update edited)
                    |> Query.has [ id "p.0.1" ]
        , test "paragraph spacing falls back to 0.85em when --paragraph-spacing is not set" <|
            \_ ->
                rendered (API.parse original)
                    |> Query.has [ style "margin-bottom" "var(--paragraph-spacing, 0.85em)" ]
        , test "indentation falls back to 1.5em when --indent is not set" <|
            \_ ->
                rendered (API.parse "\\begin{verbatim}\ncode\n\\end{verbatim}")
                    |> Query.has [ style "margin-left" "var(--indent, 1.5em)" ]
        , test "an equation number sits 1em from the right edge" <|
            \_ ->
                rendered (API.parse "\\begin{equation}\na = b\n\\end{equation}")
                    |> Query.find [ style "float" "right" ]
                    |> Query.has [ style "margin-right" "1em", text "(1)" ]
        , test "clicking a paragraph gives a message carrying that paragraph's id" <|
            \_ ->
                rendered (API.parse original)
                    |> Query.find [ id "p.0.1" ]
                    |> Event.simulate Event.click
                    |> Event.toResult
                    |> Result.map API.clickedParagraphId
                    |> Expect.equal (Ok "p.0.1")
        , test "update with an added paragraph renders it" <|
            \_ ->
                rendered (API.parse original |> API.update (original ++ "\n\nFourth paragraph."))
                    |> Query.findAll [ tag "p" ]
                    |> Query.count (Expect.equal 4)
        ]
