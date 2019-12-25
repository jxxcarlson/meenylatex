module Internal.ErrorMessages2 exposing (renderError,renderErrors )

import Parser.Advanced exposing(DeadEnd)
import Internal.Parser exposing(Problem(..), Context)



type alias ErrorDatum = DeadEnd Context Problem

-- { col : Int, problem : Problem, row : Int }


renderError : DeadEnd Context Problem -> String
renderError errorDatum = "error"

renderErrors2 : List (DeadEnd Context Problem) -> String
renderErrors2 errorData =
    errorData
      |> List.map renderError
      |> String.join ", "




renderErrors : String -> List (DeadEnd Context Problem) -> (List String, String)
renderErrors source errs =
    case List.head errs of
        Nothing ->
           ([], "")

        Just firstErr ->
            (getLines firstErr.row source, displayExpected firstErr.problem)

--            String.fromInt firstErr.row
--                ++ "| "
--                ++ getLines firstErr.row source
--                ++ "\n"
--                ++ String.repeat (firstErr.col - 1 + 3) " "
--                ++ "^"
--                ++ "\n\n\n"
--                ++ displayExpected firstErr.problem



getLines : Int -> String -> List String
getLines lineNumber str =
    List.range 1 lineNumber
      |> List.map (\i -> getLine i str)
      |> List.take 1


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
         ExpectingInWord -> "Expecting word"
         ExpectingMarker -> "Expecting marker"
         ExpectingLeftBrace -> "Expecting left brace"
         ExpectingRightBrace -> "Expecting right brace"
         ExpectingLeftBracket -> "Expecting left bracket"
         ExpectingRightBracket -> "Expecting right bracket"
         ExpectingLeftParen -> "Expecting left paren"
         ExpectingRightParen -> "Expecting right paren"
         ExpectingNewline -> "Expecting new line"
         ExpectingPercent -> "Expecting percent"
         ExpectingMacroReservedWord  -> "Expecting macro reserved word"
         ExpectingmSMacroReservedWord -> "Expecting smacro reserved word"
         ExpectingInt -> "Expecting int"
         InvalidInt -> "Invalid int"
         ExpectingLeadingDollarSign -> "Expecting $"
         ExpectingBeginAndRightBrace -> "Expecting begin{"
         ExpectingEndAndRightBrace -> "Expecting end}"
         ExpectingEscapeAndLeftBracket -> "Expecting \\["
         ExpectingDoubleNewline -> "Expecting \n\n"
         ExpectingEscapedItem -> "Expecting \\item"
         ExpectingSpace -> "Expecting space"
         ExpectingAmpersand -> "Expecting &"
         ExpectingDoubleEscapeAndNewline -> "Expecting \\\\\n"
         ExpectingEscapedNewcommandAndBrace -> "Expecting \\newcommand{"
         ExpectingEndWord -> "Expecting end word"
