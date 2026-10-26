module MiniLatexTocTest exposing (suite)

{-| Tests for `MiniLatex.API.tableOfContents`: one entry per numbered heading,
with an `id` that matches the rendered heading, kept up to date by `update`.
-}

import Expect
import Html
import MiniLatex.API as API
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector exposing (id)


doc : String
doc =
    String.join "\n\n"
        [ "\\section{Introduction}"
        , "Some text."
        , "\\subsection{Background}"
        , "More text."
        , "\\subsubsection{Early Work}"
        , "Even more."
        , "\\section{Results}"
        , "The end."
        ]


summary : API.Data -> List ( Int, String, String )
summary data =
    API.tableOfContents data
        |> List.map (\e -> ( e.level, e.number, e.title ))


rendered : API.Data -> Query.Single API.LaTeXMsg
rendered data =
    Html.div [] (API.renderData data) |> Query.fromHtml


suite : Test
suite =
    describe "MiniLatex.API.tableOfContents"
        [ test "a document without headings has an empty table of contents" <|
            \_ ->
                API.parse "Just a paragraph."
                    |> API.tableOfContents
                    |> Expect.equal []
        , test "lists each heading with its level, number and title" <|
            \_ ->
                summary (API.parse doc)
                    |> Expect.equal
                        [ ( 1, "1", "Introduction" )
                        , ( 2, "1.1", "Background" )
                        , ( 3, "1.1.1", "Early Work" )
                        , ( 1, "2", "Results" )
                        ]
        , test "each entry's id is the id of the rendered heading" <|
            \_ ->
                let
                    data =
                        API.parse doc
                in
                API.tableOfContents data
                    |> List.map (\e -> \query -> Query.has [ id e.id ] query)
                    |> (\checks -> Expect.all checks (rendered data))
        , test "update picks up an added section" <|
            \_ ->
                API.parse doc
                    |> API.update (doc ++ "\n\n\\section{Conclusion}\n\nBye.")
                    |> summary
                    |> List.reverse
                    |> List.head
                    |> Expect.equal (Just ( 1, "3", "Conclusion" ))
        , test "update picks up a renamed section without duplicating entries" <|
            \_ ->
                API.parse doc
                    |> API.update (String.replace "{Results}" "{Findings}" doc)
                    |> summary
                    |> List.map (\( _, n, t ) -> n ++ " " ++ t)
                    |> Expect.equal [ "1 Introduction", "1.1 Background", "1.1.1 Early Work", "2 Findings" ]
        ]
