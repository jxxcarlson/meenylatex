module Internal.Paragraph exposing(..) -- exposing (logicalParagraphify)

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


lp = logicalParagraphify

ex0 = """
\\begin{colored}[haskell]
push k = ST (\\s -> ((), k::s)
\\end{colored}
"""

ex0b = """
\\begin{colored}[haskell, foo]
push k = ST (\\s -> ((), k::s)
\\end{colored}
"""

ex1 = """
\\begin{colored}[haskell]
push k = ST (\\s -> ((), k::s)

pop = ST (\\(k:ks) -> (k, ks))
\\end{colored}
"""

ex2 = """
\\begin{colored}[haskell]
instance Functor (ST s) where
    fmap f s = ST $  \\t -> let (a,s') = app s t
                          in ( f a, s')
\\end{colored}
"""



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
        let
            arg =
                getBeginArg line
        in
        if String.contains ("\\end{" ++ arg ++ "}") line then
            -- The environment opens and closes on this single line, e.g.
            -- `\begin{pmatrix} a & b \\ c & d \end{pmatrix}`. It is self-contained,
            -- so treat it as ordinary text rather than opening a block. Otherwise
            -- the matching `\end` (which is not at the start of a line) is never
            -- counted, the block stack never rebalances, and the "paragraph"
            -- swallows the rest of the document.
            Text

        else
            BeginBlock arg

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


{-| A logical paragraph together with its source line range:
`startLine` is the 0-indexed first source line; `lineCount` is how many source
lines it spans (covering lines `startLine .. startLine + lineCount - 1`).
-}
type alias ParaWithLines =
    { text : String, startLine : Int, lineCount : Int }


type alias ParserRecordL =
    { currentParagraph : String
    , paragraphList : List ParaWithLines
    , state : ParserState
    , stack : Stack String
    , lineIndex : Int
    , paraStartLine : Int
    , paraEndLine : Int
    }


initParserRecordL : ParserRecordL
initParserRecordL =
    { currentParagraph = ""
    , paragraphList = []
    , state = Start
    , stack = Stack.empty
    , lineIndex = 0
    , paraStartLine = -1
    , paraEndLine = -1
    }


{-| Line-tracking analogue of `updateParserRecord`. Reuses `getNextState` so
grouping (incl. nested environments via its stack) is identical; only line
bookkeeping is added. A line is "content" when appended to the current
paragraph (InParagraph/InMathBlock/InBlock, and the Start branch when the
triggering line is non-empty, e.g. a block's `\end`). The trailing blank line
ending a normal paragraph is NOT content.
-}
updateParserRecordL : String -> ParserRecordL -> ParserRecordL
updateParserRecordL line record =
    let
        ( nextState, nextStack ) =
            getNextState line ( record.state, record.stack )

        idx =
            record.lineIndex

        contentStart =
            if record.paraStartLine < 0 then
                idx

            else
                record.paraStartLine

        bumped =
            { record | lineIndex = idx + 1, state = nextState, stack = nextStack }
    in
    case nextState of
        Start ->
            let
                lineIsContent =
                    line /= ""

                startL =
                    if lineIsContent then
                        contentStart

                    else
                        record.paraStartLine

                endL =
                    if lineIsContent then
                        idx

                    else
                        record.paraEndLine

                count =
                    if startL < 0 then
                        0

                    else
                        endL - startL + 1
            in
            { bumped
                | currentParagraph = ""
                , paragraphList =
                    record.paragraphList
                        ++ [ { text = joinLines record.currentParagraph line, startLine = startL, lineCount = count } ]
                , paraStartLine = -1
                , paraEndLine = -1
            }

        InParagraph ->
            { bumped
                | currentParagraph = joinLines record.currentParagraph line
                , paraStartLine = contentStart
                , paraEndLine = idx
            }

        InMathBlock ->
            { bumped
                | currentParagraph = joinLines record.currentParagraph line
                , paraStartLine = contentStart
                , paraEndLine = idx
            }

        InBlock _ ->
            { bumped
                | currentParagraph = joinLines record.currentParagraph (fixLine line)
                , paraStartLine = contentStart
                , paraEndLine = idx
            }

        IgnoreLine ->
            bumped

        Error ->
            { record | stack = nextStack, lineIndex = idx + 1 }


{-| Like `logicalParagraphify`, but each paragraph carries its source line
range. Grouping, trimming, and empty-paragraph filtering match
`logicalParagraphify` so results align 1:1 (by index).
-}
logicalParagraphifyWithLines : String -> List ParaWithLines
logicalParagraphifyWithLines text =
    let
        lastState =
            (text ++ "\n")
                |> String.split "\n"
                |> List.foldl updateParserRecordL initParserRecordL

        trailing =
            { text = lastState.currentParagraph
            , startLine = lastState.paraStartLine
            , lineCount =
                if lastState.paraStartLine < 0 then
                    0

                else
                    lastState.paraEndLine - lastState.paraStartLine + 1
            }
    in
    (lastState.paragraphList ++ [ trailing ])
        |> List.filter (\p -> p.text /= "")
        |> List.map (\p -> { p | text = String.trim p.text ++ "\n\n" })
