module MiniLatex.FastExport exposing (transform)

{-| This module is for quickly preparing latex for export.


# API

@docs transform

-}

import Internal.JoinStrings as JoinStrings
import Internal.Paragraph as Paragraph
import MiniLatex.Export as Export


{-| Tranform MiniLatex text into Latex text.
-}
transform : String -> String
transform sourceText =
    sourceText
        |> Paragraph.logicalParagraphify
        |> List.map processParagraph
        |> List.map (\par -> par ++ "\n\n")
        |> JoinStrings.joinList


processParagraph : String -> String
processParagraph par =
    let
        prefix =
            String.left 14 par

        signature =
            if String.left 6 prefix == "\\begin" then
                String.dropLeft 7 prefix |> String.dropRight 1

            else if String.contains "\\code" par then
                "code"

            else if String.contains "\\href" par then
                "href"

            else
                String.left 6 prefix
    in
    case signature of
        "\\image" ->
            Export.transform par |> Tuple.first

        "listin" ->
            Export.transform par |> Tuple.first

        "code" ->
            Export.transform par |> Tuple.first

        "href" ->
            Export.transform par |> Tuple.first

        "usefor" ->
            Export.transform par |> Tuple.first

        _ ->
            Export.transform par |> Tuple.first
