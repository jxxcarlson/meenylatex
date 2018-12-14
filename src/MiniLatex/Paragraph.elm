module MiniLatex.Paragraph exposing (logicalParagraphify)

{-| This module exports just one function,
intended to turn a string into a lisst
of logical paragraphs. It operates as a
finite-state machine.


# API

@docs logicalParagraphify

-}

import MiniLatex.Parser
import MiniLatex.Stack as Stack exposing (Stack)
import Parser
import Regex


type ParserState
    = Start
    | InParagraph
    | InBlock String
    | IgnoreLine
    | Error


type LineType
    = Blank
    | Ignore
    | Text
    | BeginBlock String
    | EndBlock String


type alias ParserRecord =
    { currentParagraph : String, paragraphList : List String, state : ParserState, stack : Stack String }


getBeginArg : String -> String
getBeginArg line =
    let
        parseResult =
            Parser.run MiniLatex.Parser.envName line

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
            Parser.run MiniLatex.Parser.endWord line

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

        ( Start, Ignore ) ->
            ( IgnoreLine, stack )

        ( IgnoreLine, Blank ) ->
            ( Start, stack )

        ( IgnoreLine, Text ) ->
            ( InParagraph, stack )

        ( IgnoreLine, BeginBlock arg ) ->
            ( InBlock arg, Stack.push arg stack )

        ( InBlock arg, Blank ) ->
            ( InBlock arg, stack )

        ( InBlock arg, Text ) ->
            ( InBlock arg, stack )

        ( InBlock arg, BeginBlock arg2 ) ->
            ( InBlock arg, Stack.push arg2 stack )

        ( InBlock arg1, EndBlock arg2 ) ->
            let
                ( nextStack, line_ ) =
                    -- Debug.log "POP"
                    ( Stack.pop stack, line )

                -- _ =
                --    Debug.log "LINE" line
            in
                case Stack.top nextStack of
                    Nothing ->
                        -- ( InBlock arg1, nextStack )
                        -- Debug.log "NOTHING"
                        ( Start, nextStack )

                    Just arg ->
                        -- Debug.log "JUST ARG"
                        ( InBlock arg, nextStack )

        ( InParagraph, Text ) ->
            ( InParagraph, stack )

        ( InParagraph, BeginBlock str ) ->
            ( InParagraph, Stack.push str stack )

        ( InParagraph, EndBlock arg ) ->
            ( Error, stack )

        -- let
        --     nextStack =
        --         Stack.pop stack
        -- in
        -- case Stack.top nextStack of
        --     Nothing ->
        --         ( Start, nextStack )
        --     Just arg_ ->
        --         ( InParagraph, nextStack )
        ( InParagraph, Blank ) ->
            ( Start, stack )

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
            -- Debug.log "S,S"
            getNextState
                line
                ( parserRecord.state, parserRecord.stack )

        -- _ =
        --     Debug.log "line" line
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
or outer blocks of the form \begin{*} ... \end{*}.
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
