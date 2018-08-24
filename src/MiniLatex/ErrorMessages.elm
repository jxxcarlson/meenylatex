module MiniLatex.ErrorMessages exposing (renderError)

import Dict
import Parser exposing(DeadEnd, deadEndsToString)



renderError : DeadEnd -> String
renderError error =
    "<div style=\"color: red\">ERROR: "
        ++ deadEndsToString [error]
        ++ "</div>\n"
        ++ "<div style=\"color: blue\">"
        ++ "explanation_"
        ++ "</div>"


normalizeError : String -> String
normalizeError str =
    str
        |> reduceBackslashes
        |> String.replace "\"" ""
        -- |> String.softBreak 50
        -- |> List.keep 5
        -- |> String.join " "
        -- |> (\x -> x ++ " ...")


reduceBackslashes : String -> String
reduceBackslashes str =
    str |> String.replace "\\\\" "\\" |> String.replace "\\n" "\n"


errorMessage1 error =
    "<div style=\"color: red\">ERROR: "
        ++ error.source
        ++ "</div>\n"
        ++ "<div style=\"color: blue\">"
        ++ explanation error
        ++ "</div>"


errorDict : Dict.Dict String String
errorDict =
    Dict.fromList
        [ ( "ExpectingSymbol \"\\end{enumerate}\"", "Check \\begin--\\end par, then check \\items" )
        , ( "ExpectingSymbol \"\\end{itemize}\"", "Check \\begin--\\end par, then check \\items" )
        , ( "ExpectingSymbol \"}\"", "Looks like you didn't close a macro argument." )
        ]


explanation error =
    let
        errorWords =
            error.problem |> String.words

        errorHead =
            errorWords |> List.head
    in
    case errorHead of
        Just "ExpectingSymbol" ->
            handleExpectingSymbol error errorWords

        Just "ExpectingClosing" ->
            handleExpectingClosing error errorWords

        _ ->
            stateProblem error


stateProblem error =
    "Problem: "
        ++ error.problem
        ++ "\nfor: "
        ++ leadErrorDescription error


handleExpectingSymbol error errorWords =
    let
        maybeErrorSecondWord =
            errorWords |> List.drop 1 |> List.head
    in
    case maybeErrorSecondWord of
        Just secondWord ->
            handleSecondWord error (normalize secondWord)

        _ ->
            stateProblem error


handleSecondWord error secondWord =
    let
        lead =
            leadErrorDescription error
    in
    if String.startsWith "end{" secondWord then
        "You seem to have a mismatched begin-end pair."
    else if String.startsWith "}" secondWord then
        "You need a closing brance -- macro argument?"
    else if secondWord == "" && lead == "item" then
        "Is an \"\\item\" misspelled?"
    else
        stateProblem error


handleExpectingClosing error errorWords =
    stateProblem error


leadErrorDescription error =
    let
        leadContext =
            List.head error.context
    in
    case leadContext of
        Just info ->
            info.description

        _ ->
            "No info"


normalize str =
    str |> String.replace "\"" "" |> String.replace "\\" ""


errorMessage2 error =
    "row: "
        ++ String.fromInt error.row
        ++ "\ncol: "
        ++ String.fromInt  error.col
        ++ "\nProblem: "
        ++ error.problem
        ++ "\nContext: "
        ++ error.context
        ++ "\nSource: "
        ++ error.source
