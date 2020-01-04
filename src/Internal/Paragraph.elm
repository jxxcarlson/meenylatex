module Internal.Paragraph exposing (logicalParagraphify)

{-| This module exports just one function,
intended to turn a string into a lisst
of logical paragraphs. It operates as a
finite-state machine.


# API

@docs logicalParagraphify

-}

import Internal.Parser
import Internal.Stack as Stack exposing (Stack)
import Parser.Advanced
import Regex


type ParserState
    = Start
    | InParagraph
    | InBlock String
    | InMathBlock
    | IgnoreLine
    | Error


type LineType
    = Blank
    | Ignore
    | Text
    | BeginBlock String
    | EndBlock String
    | MathBlock


type alias ParserRecord =
    { currentParagraph : String
    , paragraphList : List String
    , state : ParserState
    , stack : Stack String
    }


getBeginArg : String -> String
getBeginArg line =
    let
        parseResult =
            Parser.Advanced.run Internal.Parser.envName line

        arg =
            case parseResult of
                Ok word ->
                    word

                Err _ ->
                    ""
    in
    arg


getEndArg : String -> String
getEndArg line =
    let
        parseResult =
            Parser.Advanced.run Internal.Parser.endWord line

        arg =
            case parseResult of
                Ok word ->
                    word

                Err _ ->
                    ""
    in
    arg


lineType : String -> LineType
lineType line =
    if line == "" then
        Blank
        -- else if line == "\\begin{thebibliography}" || line == "\\end{thebibliography}" then
        --     Ignore

    else if String.startsWith "\\begin" line then
        BeginBlock (getBeginArg line)

    else if String.startsWith "\\end" line then
        EndBlock (getEndArg line)

    else if String.startsWith "$$" line then
        MathBlock

    else
        Text


{-| getNextState is the transition function for a finite-state
machine which parses lines.
-}
getNextState : String -> ( ParserState, Stack String ) -> ( ParserState, Stack String )
getNextState line ( parserState, stack ) =
    case ( parserState, lineType line ) of
        ( Start, Blank ) ->
            ( Start, stack )

        ( Start, Text ) ->
            ( InParagraph, stack )

        ( Start, BeginBlock arg ) ->
            ( InBlock arg, Stack.push arg stack )

        ( Start, MathBlock ) ->
            if String.endsWith "$$" (String.dropLeft 2 line) then
                ( Start, stack )

            else
                ( InMathBlock, stack )

        -- ( Start, MathBlock ) ->
        --     ( InMathBlock, stack )
        ( Start, Ignore ) ->
            ( IgnoreLine, stack )

        ( IgnoreLine, Blank ) ->
            ( Start, stack )

        ( IgnoreLine, Text ) ->
            ( InParagraph, stack )

        ( IgnoreLine, BeginBlock arg ) ->
            ( InBlock arg, Stack.push arg stack )

        ( IgnoreLine, MathBlock ) ->
            ( InMathBlock, stack )

        ( InBlock arg, Blank ) ->
            ( InBlock arg, stack )

        ( InBlock arg, Text ) ->
            ( InBlock arg, stack )

        ( InBlock arg, MathBlock ) ->
            ( InMathBlock, stack )

        ( InBlock arg, BeginBlock arg2 ) ->
            ( InBlock arg, Stack.push arg2 stack )

        ( InBlock arg1, EndBlock arg2 ) ->
            let
                ( nextStack, line_ ) =
                    ( Stack.pop stack, line )
            in
            case Stack.top nextStack of
                Nothing ->
                    ( Start, nextStack )

                Just arg ->
                    ( InBlock arg, nextStack )

        ( InParagraph, Text ) ->
            ( InParagraph, stack )

        ( InParagraph, BeginBlock str ) ->
            ( InParagraph, Stack.push str stack )

        ( InParagraph, MathBlock ) ->
            ( InMathBlock, stack )

        ( InParagraph, EndBlock arg ) ->
            ( Error, stack )

        ( InParagraph, Blank ) ->
            ( Start, stack )

        ( InMathBlock, BeginBlock str ) ->
            ( InMathBlock, stack )

        ( InMathBlock, EndBlock str ) ->
            ( InMathBlock, stack )

        ( InMathBlock, MathBlock ) ->
            ( Start, stack )

        ( InMathBlock, _ ) ->
            if String.endsWith "$$" (String.dropLeft 2 line) then
                ( Start, stack )

            else if line == "" then
                -- XXX: experiment to terminate math block if it contains blank lines
                ( Start, stack )

            else
                ( InMathBlock, stack )

        ( _, _ ) ->
            ( Error, stack )


joinLines : String -> String -> String
joinLines a b =
    case ( a, b ) of
        ( "", _ ) ->
            b

        ( _, "" ) ->
            a

        ( "\n", _ ) ->
            "\n" ++ b

        ( _, "\n" ) ->
            a ++ "\n"

        ( aa, bb ) ->
            aa ++ "\n" ++ bb


fixLine : String -> String
fixLine line =
    if line == "" then
        "\n"

    else
        line


{-| Given an line and a parserRecord, compute a new parserRecord.
The new parserRecord depends on the getNextState of the FSM. Note
that the state of the machine is part of the parserRecord.
-}
updateParserRecord : String -> ParserRecord -> ParserRecord
updateParserRecord line parserRecord =
    let
        ( nextState, nextStack ) =
            getNextState
                line
                ( parserRecord.state, parserRecord.stack )
    in
    case nextState of
        Start ->
            { parserRecord
                | currentParagraph = ""
                , paragraphList = parserRecord.paragraphList ++ [ joinLines parserRecord.currentParagraph line ]
                , state = nextState
                , stack = nextStack
            }

        InParagraph ->
            { parserRecord
                | currentParagraph = joinLines parserRecord.currentParagraph line
                , state = nextState
                , stack = nextStack
            }

        InMathBlock ->
            { parserRecord
                | currentParagraph = joinLines parserRecord.currentParagraph line
                , state = nextState
                , stack = nextStack
            }

        InBlock arg ->
            { parserRecord
                | currentParagraph = joinLines parserRecord.currentParagraph (fixLine line)
                , state = nextState
                , stack = nextStack
            }

        IgnoreLine ->
            { parserRecord
                | state = nextState
                , stack = nextStack
            }

        Error ->
            { parserRecord | stack = nextStack }


logicalParagraphParse : String -> ParserRecord
logicalParagraphParse text =
    (text ++ "\n")
        |> String.split "\n"
        |> List.foldl updateParserRecord { currentParagraph = "", paragraphList = [], state = Start, stack = Stack.empty }


{-| logicalParagraphify text: split text into logical
parapgraphs, where these are either normal paragraphs, i.e.,
blocks text with no blank lines surrounded by blank lines,
or outer blocks of the form \\begin{_} ... \\end{_}.
-}
logicalParagraphify : String -> List String
logicalParagraphify text =
    let
        lastState =
            logicalParagraphParse text
    in
    lastState.paragraphList
        ++ [ lastState.currentParagraph ]
        |> List.filter (\x -> x /= "")
        |> List.map (\paragraph -> String.trim paragraph ++ "\n\n")


para : Regex.Regex
para =
    Maybe.withDefault Regex.never <|
        Regex.fromString "\\n\\n+"


paragraphify : String -> List String
paragraphify text =
    --String.split "\n\n" text
    Regex.split para text
        |> List.filter (\x -> String.length x /= 0)
        |> List.map (String.trim >> (\x -> x ++ "\n\n"))
