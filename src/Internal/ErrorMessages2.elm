module Internal.ErrorMessages2 exposing (renderError, renderErrors)

import Internal.Parser exposing (Context, Problem(..))
import List.Extra
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
    --let
    --    _ =
    --        Debug.log "ERRS" errs
    --
    --    _ =
    --        Debug.log "SRC" source
    --in
    case List.head (List.reverse errs) of
        Nothing ->
            { errorText = [], markerOffset = 0, explanation = "no explanation" }

        Just theErr ->
            let
                --_ =
                --    Debug.log "ERR (!!)" theErr
                errColumn =
                    List.head theErr.contextStack |> Maybe.map .col |> Maybe.withDefault 1

                markerOffset =
                    -- theErr.col
                    errColumn

                -- _ =
                --     Debug.log "ROW" theErr.row
            in
            { errorText = betterErrorText theErr source -- getRows theErr.row source

            -- errorText = [ List.Extra.getAt (theErr.row - 1) (String.lines source) |> Maybe.withDefault "errrrr!" ]
            -- errorText = getLines theErr.row source
            , markerOffset = markerOffset
            , explanation = displayExpected theErr.problem
            }


getRows : Int -> String -> List String
getRows k source =
    source
        |> String.lines
        |> List.indexedMap (\i line -> ( i, line ))
        |> List.filter (\( i, line ) -> i < k)
        |> List.map Tuple.second
        |> List.map (String.left 40)


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



-- ExpectingEndWord


betterErrorText : DeadEnd Context Problem -> String -> List String
betterErrorText theError source =
    let
        firstLine source_ =
            [ getLine 1 source_ ]
    in
    case theError.problem of
        ExpectingValidMacroArgWord ->
            firstLine source

        ExpectingEndOfEnvironmentName ->
            firstLine source

        ExpectingEndWord word ->
            firstLine source

        _ ->
            getRows theError.row source


displayExpected : Problem -> String
displayExpected problem =
    case problem of
        ExpectingEndForInlineMath ->
            "Expecting '$' to end inline math"

        ExpectingEndOfEnvironmentName ->
            "Make complete environment \\begin{..} ... \\end{..}"

        ExpectingBeginDisplayMathModeDollarSign ->
            "Expecting '$$' to begin displayed math"

        ExpectingEndDisplayMathModeDollarSign ->
            "Expecting '$$' to end displayed math"

        ExpectingBeginDisplayMathModeBracket ->
            "Expecting '\\[' or '\\]' for displayed math"

        ExpectingEndDisplayMathModeBracket ->
            "Expecting '\\[' or '\\]' for displayed math"

        ExpectingEndForPassThroughBody ->
            "Missing \\end{env}"

        ExpectingValidTableCell ->
            "Something is to complete the table cell"

        ExpectingValidOptionArgWord ->
            "Something is missing to complete the optional argument"

        ExpectingValidMacroArgWord ->
            "Fill in the macro argument: {..}"

        ExpectingWords ->
            "Something is missing in this sequence of words"

        ExpectingLeftBrace ->
            "Expecting left brace"

        ExpectingRightBrace ->
            "Complete the argument with a right brace : {..}"

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

        ExpectingLeadingInLineMathDelimiter string ->
            "Expecting Leading Inline Math Delimiter " ++ string

        ExpectingEnvironmentNameBegin ->
            "Close your environment \\begin{..} ... \\end{..}"

        ExpectingEnvironmentNameEnd ->
            "Expecting \\end{envName}"

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

        ExpectingSpaceAfterItem ->
            "Complete your \\item ..."

        ExpectingAmpersand ->
            "Expecting &"

        ExpectingDoubleEscapeAndNewline ->
            "Expecting \\\\\n"

        ExpectingEscapedNewcommandAndBrace ->
            "Expecting \\newcommand{"

        ExpectingEndWord envName ->
            "Close environment with " ++ envName

        ExpectingEndWordInItemList envName ->
            "Do you have an incomplete \\item ... ?"
