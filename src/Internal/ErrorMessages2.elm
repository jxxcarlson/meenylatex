module Internal.ErrorMessages2 exposing (renderError, renderErrors)

import Internal.Parser exposing (Context, Problem(..))
import Parser.Advanced exposing (DeadEnd)


type alias ErrorDatum =
    DeadEnd Context Problem



-- { col : Int, problem : Problem, row : Int }


renderError : DeadEnd Context Problem -> String
renderError errorDatum =
    "error"


renderErrors2 : List (DeadEnd Context Problem) -> String
renderErrors2 errorData =
    errorData
        |> List.map renderError
        |> String.join ", "


type alias ErrorReport =
    { errorText : List String
    , markerOffset : Int
    , explanation : String
    }


renderErrors : String -> List (DeadEnd Context Problem) -> ErrorReport
renderErrors source errs =
    case List.head errs of
        Nothing ->
            { errorText = [], markerOffset = 0, explanation = "no explanation" }

        Just firstErr ->
            let
                markerOffset =
                    firstErr.col
            in
            { errorText = getLines firstErr.row source, markerOffset = markerOffset, explanation = displayExpected firstErr.problem }


getLines : Int -> String -> List String
getLines lineNumber str =
    List.range 1 lineNumber
        |> List.map (\i -> getLine i str)
        |> List.filter (\line -> String.length line > 0)



-- |> List.take 1


getLine : Int -> String -> String
getLine lineNumber str =
    if lineNumber <= 1 then
        Maybe.withDefault str (List.head (String.split "\n" str))

    else
        getLine
            (lineNumber - 1)
            (String.slice
                (Maybe.withDefault 0 (List.head (String.indexes "\n" str)) + 1)
                (String.length str)
                str
            )


displayExpected : Problem -> String
displayExpected problem =
    case problem of
        ExpectingEndForInlineMath ->
            "Expecting '$' to end inline math"

        ExpectingEndOfEnvironmentName ->
            "Begin or end phrase messed up in environment"

        ExpectingBeginDisplayMathModeDollarSign ->
            "Expecting '$$' for displayed math"

        ExpectingEndDisplayMathModeDollarSign ->
            "Expecting '$$' for displayed math"

        ExpectingBeginDisplayMathModeBracket ->
            "Expecting '\\[' or '\\]' for displayed math"

        ExpectingEndDisplayMathModeBracket ->
            "Expecting '\\[' or '\\]' for displayed math"

        ExpectingEndForPassThroughBody ->
            "Begin or end phrase messed up in environment"

        ExpectingValidTableCell ->
            "Something is to complete the table cell"

        ExpectingValidOptionArgWord ->
            "Something is missing to complete the optional argument"

        ExpectingValidMacroArgWord ->
            "Something is missing to complete the macro argument'"

        ExpectingWords ->
            "Something is missing in this sequence of words"

        ExpectingLeftBrace ->
            "Expecting left brace"

        ExpectingRightBrace ->
            "Expecting right brace"

        ExpectingLeftBracket ->
            "Expecting left bracket"

        ExpectingRightBracket ->
            "Expecting right bracket"

        ExpectingLeftParen ->
            "Expecting left paren"

        ExpectingRightParen ->
            "Expecting right paren"

        ExpectingNewline ->
            "Expecting new line"

        ExpectingPercent ->
            "Expecting percent"

        ExpectingMacroReservedWord ->
            "Expecting macro reserved word"

        ExpectingmSMacroReservedWord ->
            "Expecting smacro reserved word"

        ExpectingInt ->
            "Expecting int"

        InvalidInt ->
            "Invalid int"

        ExpectingLeadingDollarSign ->
            "Expecting $"

        ExpectingBeginAndRightBrace ->
            "Expecting begin{"

        ExpectingEndAndRightBrace ->
            "Expecting end}"

        ExpectingEscapeAndLeftBracket ->
            "Expecting \\["

        ExpectingDoubleNewline ->
            "Expecting \n\n"

        ExpectingEscapedItem ->
            "Expecting \\item"

        ExpectingSpace ->
            "Expecting space"

        ExpectingAmpersand ->
            "Expecting &"

        ExpectingDoubleEscapeAndNewline ->
            "Expecting \\\\\n"

        ExpectingEscapedNewcommandAndBrace ->
            "Expecting \\newcommand{"

        ExpectingEndWord ->
            "Begin or end phrase messed up"
