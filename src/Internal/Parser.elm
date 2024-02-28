module Internal.Parser exposing (..)

{-| This module is for quickly preparing latex for export.


# API

@docs LatexExpression, macro, parse, defaultLatexList
@docs latexList, endWord, envName, word, latexExpression

-}

--( LatexExpression(..), macro, parse, defaultLatexList
--, runParser, latexList, endWord, envName, word, latexExpression
--, Context, LXParser, Problem(..), displayMathBrackets, displayMathDollar, environment, inlineMath, itemList, newcommand, numberOfArgs, texComment, words, ws
--)
-- import Internal.ParserHelpers as PH exposing (..)

import Dict
import Parser.Advanced exposing (..)
import Set



{- ELLIE: https://ellie-app.com/pcB5b3BPfa1/0

   https://ellie-app.com/pcB5b3BPfa1/1

-}
{- End of Has Math code -}


{-| The type for the Abstract syntax tree
-}
type LatexExpression
    = LXString String
    | Comment String
    | Item Int LatexExpression
    | InlineMath String
    | DisplayMath String
    | SMacro String (List LatexExpression) (List LatexExpression) LatexExpression -- SMacro name optArgs args body
    | Macro String (List LatexExpression) (List LatexExpression) -- Macro name optArgs args
    | Environment String (List LatexExpression) LatexExpression -- Environment name optArgs body
    | LatexList (List LatexExpression)
    | NewCommand String Int LatexExpression
    | LXError (List (DeadEnd Context Problem))


type alias LXParser a =
    Parser.Advanced.Parser Context Problem a


type Context
    = CArg String
    | EnvName
    | List


type Problem
    = ExpectingEndForInlineMath
    | ExpectingEndOfEnvironmentName
    | ExpectingBeginDisplayMathModeDollarSign
    | ExpectingEndDisplayMathModeDollarSign
    | ExpectingBeginDisplayMathModeBracket
    | ExpectingEndDisplayMathModeBracket
    | ExpectingEndForPassThroughBody
    | ExpectingValidTableCell
    | ExpectingValidOptionArgWord
    | ExpectingValidMacroArgWord
    | ExpectingWords
    | ExpectingLeftBrace
    | ExpectingRightBrace
    | ExpectingLeftBracket
    | ExpectingRightBracket
    | ExpectingLeftParen
    | ExpectingRightParen
    | ExpectingNewline
    | ExpectingPercent
    | ExpectingMacroReservedWord
    | ExpectingmSMacroReservedWord
    | ExpectingInt
    | InvalidInt
    | ExpectingLeadingDollarSign
    | ExpectingLeadingInLineMathDelimiter String
    | ExpectingEnvironmentNameBegin
    | ExpectingEnvironmentNameEnd
    | ExpectingBeginAndRightBrace
    | ExpectingEndAndRightBrace
    | ExpectingEscapeAndLeftBracket
    | ExpectingDoubleNewline
    | ExpectingEscapedItem
    | ExpectingSpaceAfterItem
    | ExpectingAmpersand
    | ExpectingDoubleEscapeAndNewline
    | ExpectingEscapedNewcommandAndBrace
    | ExpectingEndWord String
    | ExpectingEndWordInItemList String


{-| Transform a string into a list of LatexExpressions

    parse "Pythagoras: $a^2 + b^2 = c^2$"
    --> [LXString ("Pythagoras: "),InlineMath ("a^2 + b^2 = c^2")]

-}
parse : String -> List LatexExpression
parse text =
    let
        expr =
            Parser.Advanced.run latexList text
    in
    case expr of
        Ok (LatexList list) ->
            list

        Err error ->
            [ LXError error ]

        _ ->
            [ LXString "Dude! not great code here." ]


runParser : LXParser (List LatexExpression) -> String -> List LatexExpression
runParser p str =
    let
        expr =
            Parser.Advanced.run p str
    in
    case expr of
        Ok latexExpr ->
            latexExpr

        Err error ->
            [ LXError error ]


{-| Production: $ LatexList &\\Rightarrow LatexExpression^+ $
-}
latexList : LXParser LatexExpression
latexList =
    -- inContext "latexList" <|
    succeed identity
        |. ws
        |= itemList latexExpression
        |> map LatexList


{-| Production: $ LatexExpression &\\Rightarrow Words\\ |\\ Comment\\ |\\ IMath\\ |\\ DMath\\ |\\ Macro\\ |\\ Env $
-}
latexExpression : LXParser LatexExpression
latexExpression =
    oneOf
        [ texComment
        , displayMathDollar
        , displayMathBrackets
        , inlineMath ws
        , newcommand
        , macro ws
        , smacro
        , words
        , lazy (\_ -> environment)
        ]


{-| A default value of type LatexExpression
-}
defaultLatexList : LatexExpression
defaultLatexList =
    LatexList [ LXString "Parse Error" ]


defaultLatexExpression : List LatexExpression
defaultLatexExpression =
    [ Macro "NULL" [] [] ]



{- WORDS -}


{-|

    import Parser.Advanced
    LXParser.run words "one two three"
    --> Ok (LXString ("one  two  three"))

-}
words : LXParser LatexExpression
words =
    oneOf
        [ blank
        , succeed identity
            |. ws
            |= words_ ExpectingWords
            |. ws
        ]


words_ : Problem -> LXParser LatexExpression
words_ problem =
    nonEmptyItemList (word problem notSpaceOrSpecialCharacters)
        |> map (String.join " ")
        |> map LXString


blank : LXParser LatexExpression
blank =
    symbol (Token "\n\n" ExpectingDoubleNewline) |> map (\_ -> LXString "\n\n")


notSpaceOrSpecialCharacters : Char -> Bool
notSpaceOrSpecialCharacters c =
    not (c == ' ' || c == '\n' || c == '\\' || c == '$')


{-| Use `inWord` to parse a word.

import Parser

inWord : Char -> Bool
inWord c = not (c == ' ')

LXParser.run word "this is a test"
--> Ok "this"

-}
word : Problem -> (Char -> Bool) -> LXParser String
word problem inWord =
    succeed String.slice
        |. ws
        |= getOffset
        |. chompIf inWord problem
        |. chompWhile inWord
        |. ws
        |= getOffset
        |= getSource



{- MACRO WORDS -}


macroArgWords : LXParser LatexExpression
macroArgWords =
    nonEmptyItemList (word ExpectingValidMacroArgWord inMacroArg)
        |> map (String.join " ")
        |> map LXString


inMacroArg : Char -> Bool
inMacroArg c =
    not (c == '\\' || c == '$' || c == '}' || c == ' ' || c == '\n')



{- OPTION ARG WORDS -}


optionArgWords : LXParser LatexExpression
optionArgWords =
    nonEmptyItemList (word ExpectingValidOptionArgWord inOptionArgWord)
        |> map (String.join " ")
        |> map LXString


inOptionArgWord : Char -> Bool
inOptionArgWord c =
    not (c == '\\' || c == '$' || c == ']' || c == ' ' || c == '\n')



{- SPECIAL WORDS -}


tableCellWords : LXParser LatexExpression
tableCellWords =
    nonEmptyItemList (word ExpectingValidTableCell inTableCellWord)
        |> map (String.join " ")
        |> map String.trim
        |> map LXString


inTableCellWord : Char -> Bool
inTableCellWord c =
    not (c == ' ' || c == '\n' || c == '\\' || c == '$' || c == '&')



{- TEX COMMENTS -}


{-|

    import LXParser

    LXParser.run texComment "% testing ...\n"
    --> Ok (Comment ("% testing ...\n"))

    LXParser.run texComment "% testing ..."
    --> Err [{ col = 14, problem = LXParser.UnexpectedChar, row = 1 }]

-}
texComment : LXParser LatexExpression
texComment =
    (getChompedString <|
        succeed ()
            |. chompIf (\c -> c == '%') ExpectingPercent
            |. chompWhile (\c -> c /= '\n')
            |. chompIf (\c -> c == '\n') ExpectingNewline
            |. ws
    )
        |> map Comment



{- MACROS -
   NOTE: macro sequences should be of the form "" followed by alphabetic characters,
   but not equal to certain reserved words, e.g., "\begin", "\end", "\item"
-}


{-| Parse the macro keyword followed by
zero or more optional followed by zero or more more eventual arguments.

    import LXParser

    LXParser.run newcommand "\\newcommand{\\hello}[1]{Hello \\strong{#1}!}"
    --> Ok (NewCommand "hello" 1 (LatexList [LXString "Hello ",Macro "strong" [] [LatexList [LXString "#1"]],LXString "!"]))

-}
newcommand : LXParser LatexExpression
newcommand =
    succeed NewCommand
        |. symbol (Token "\\newcommand{" ExpectingEscapedNewcommandAndBrace)
        |= macroName
        |. symbol (Token "}" ExpectingRightBrace)
        |= numberOfArgs
        |= arg
        |. ws


numberOfArgs_ : LXParser Int
numberOfArgs_ =
    succeed identity
        |. symbol (Token "[" ExpectingLeftBracket)
        |= int ExpectingInt InvalidInt
        |. symbol (Token "]" ExpectingRightBracket)


{-|

    import LXParser

    LXParser.run numberOfArgs "[3]"
    --> Ok 3

-}
numberOfArgs : LXParser Int
numberOfArgs =
    many numberOfArgs_
        |> map List.head
        |> map (Maybe.withDefault 0)


{-| Parse the macro keyword followed by
zero or more optional followed by zero or more more eventual arguments.

    import LXParser
    import Internal.ParserHelpers as PH

    LXParser.run (macro ws) "\\hello}[1]{Hello \\strong{#1}!}"
    --> Ok (Macro "hello" [] [])

-}
macro : LXParser () -> LXParser LatexExpression
macro wsParser =
    succeed Macro
        |= macroName
        |= itemList optionalArg
        |= itemList arg
        |. wsParser


{-| Use to parse arguments for macros
-}
optionalArg : LXParser LatexExpression
optionalArg =
    succeed identity
        |. symbol (Token "[" ExpectingLeftBracket)
        |= itemList (oneOf [ optionArgWords, inlineMath spaces ])
        |. symbol (Token "]" ExpectingRightBracket)
        |> map LatexList


{-| Use to parse arguments for macros
-}
arg : LXParser LatexExpression
arg =
    inContext (CArg "arg") <|
        (succeed identity
            |. symbol (Token "{" ExpectingLeftBrace)
            |= itemList (oneOf [ macroArgWords, inlineMath spaces, lazy (\_ -> macro spaces) ])
            |. symbol (Token "}" ExpectingRightBrace)
            |> map LatexList
        )


macroName : LXParser String
macroName =
    variable
        { start = \c -> c == '\\'
        , inner = \c -> Char.isAlphaNum c || c == '*'
        , reserved = Set.fromList [ "\\begin", "\\end", "\\item", "\\bibitem" ]
        , expecting = ExpectingMacroReservedWord
        }
        |> map (String.dropLeft 1)


{-| The smacro parser assumes that the text to be
parsed forms a single paragraph
-}
smacro : LXParser LatexExpression
smacro =
    succeed SMacro
        |= smacroName
        |= itemList optionalArg
        |= itemList arg
        |= lazy (\_ -> latexList)


smacroName : LXParser String
smacroName =
    variable
        { start = \c -> c == '\\'
        , inner = \c -> Char.isAlphaNum c
        , reserved = Set.fromList [ "\\begin", "\\end", "\\item" ]
        , expecting = ExpectingmSMacroReservedWord
        }
        |> map (String.dropLeft 1)



{- Latex List and Expression -}
{- MATHEMATICAL TEXT -}


{-|

    import LXParser
    import Internal.ParserHelpers as PH

    LXParser.run (inlineMath ws) "$a^2 + b^2$"
    --> Ok (InlineMath ("a^2 + b^2"))

-}

inlineMath : LXParser () -> LXParser LatexExpression
inlineMath wsParser =
    let
        inLineMathUsingDelimiters : ( String, String ) -> Parser Context Problem LatexExpression
        inLineMathUsingDelimiters ( startDelimiter, endDelimiter ) =
            succeed InlineMath
                |. symbol (Token startDelimiter <| ExpectingLeadingInLineMathDelimiter startDelimiter)
                |= parseToSymbol ExpectingEndForInlineMath endDelimiter
                |. wsParser
    in
    oneOf
        [ inLineMathUsingDelimiters ( "\\(", "\\)" )
        , inLineMathUsingDelimiters ( "~~", "~~" )
        , inLineMathUsingDelimiters ( "$", "$" )
        ]


{-|

    import LXParser

    LXParser.run displayMathDollar "$$a^2 + b^2$$"
    --> Ok (DisplayMath ("a^2 + b^2"))

-}
displayMathDollar : LXParser LatexExpression
displayMathDollar =
    -- inContext "display math $$" <|
    succeed DisplayMath
        |. spaces
        |. symbol (Token "$$" ExpectingBeginDisplayMathModeDollarSign)
        |= parseToSymbol ExpectingEndDisplayMathModeDollarSign "$$"
        |. ws


{-|

    import LXParser

    LXParser.run displayMathBrackets "\\[a^2 + b^2\\]"
    --> Ok (DisplayMath ("a^2 + b^2"))

-}
displayMathBrackets : LXParser LatexExpression
displayMathBrackets =
    -- inContext "display math brackets" <|
    succeed DisplayMath
        |. spaces
        |. symbol (Token "\\[" ExpectingBeginDisplayMathModeBracket)
        |= parseToSymbol ExpectingEndDisplayMathModeBracket "\\]"
        |. ws



{- ENVIRONMENTS -}


{-| Capture the name of the environment in
a \\begin{ENV} ... \\end{ENV}
pair
-}
envName : LXParser String
envName =
    inContext EnvName <|
        succeed identity
            |. spaces
            |. symbol (Token "\\begin{" ExpectingEnvironmentNameBegin)
            |= parseToSymbol ExpectingEndOfEnvironmentName "}"


{-| Use to parse begin ... end blocks
Todo -- XXX: IS THIS USED?
-}
endWord : LXParser String
endWord =
    succeed identity
        |. spaces
        |. symbol (Token "\\end{" ExpectingEnvironmentNameEnd)
        |= parseToSymbol ExpectingEndAndRightBrace "}"
        |. ws


{-|

    import LXParser

    LXParser.run environment "\\begin{theorem}\nFor all integers $i$, $j$, $i + j = j = i$.\n\\end{theorem}"
    --> Ok (Environment "theorem" [] (LatexList [LXString ("For  all  integers "),InlineMath "i",LXString (", "),InlineMath "j",LXString (", "),InlineMath ("i + j = j = i"),LXString ".\n"]))

-}
environment : LXParser LatexExpression
environment =
    envName |> andThen environmentOfType


environmentOfType : String -> LXParser LatexExpression
environmentOfType envType =
    let
        theEndWord =
            "\\end{" ++ envType ++ "}"

        katex =
            [ "align", "matrix", "pmatrix", "bmatrix", "Bmatrix", "vmatrix", "Vmatrix" ]

        envKind =
            if List.member envType ([ "equation", "eqnarray", "verbatim", "colored", "CD", "mathmacro", "textmacro", "listing", "verse" ] ++ katex) then
                "passThrough"

            else
                envType
    in
    environmentParser envKind theEndWord envType



{- DISPATCHER AND SUBPARSERS -}


environmentParser : String -> String -> String -> LXParser LatexExpression
environmentParser envKind theEndWord envType =
    case Dict.get envKind parseEnvironmentDict of
        Just p ->
            p theEndWord envType

        Nothing ->
            standardEnvironmentBody theEndWord envType


parseEnvironmentDict : Dict.Dict String (String -> String -> LXParser LatexExpression)
parseEnvironmentDict =
    Dict.fromList
        [ ( "enumerate", \endWoord envType -> itemEnvironmentBody endWoord envType )
        , ( "itemize", \endWoord envType -> itemEnvironmentBody endWoord envType )
        , ( "thebibliography", \endWoord envType -> biblioEnvironmentBody endWoord envType )
        , ( "tabular", \endWoord envType -> tabularEnvironmentBody endWoord envType )
        , ( "passThrough", \endWoord envType -> passThroughBody endWoord envType )
        ]



-- Environment String (List LatexExpression) LatexExpression -- Environment name optArgs body


standardEnvironmentBody : String -> String -> LXParser LatexExpression
standardEnvironmentBody endWoord envType =
    succeed (Environment envType)
        |. ws
        |= itemList optionalArg
        |. ws
        |= (nonEmptyItemList latexExpression |> map LatexList)
        |. ws
        |. symbol (Token endWoord (ExpectingEndWord endWoord))
        |. ws


{-| The body of the environment is parsed as an LXString.
This parser is used for environments whose body is to be
passed to MathJax for processing and also for the verbatim
environment.
-}



-- TODO


passThroughBody : String -> String -> LXParser LatexExpression
passThroughBody endWoord envType =
    --  inContext "passThroughBody" <|
    succeed identity
        |= parseToSymbol ExpectingEndForPassThroughBody endWoord
        |. ws
        |> map (passThroughEnv envType)


passThroughEnv : String -> String -> LatexExpression
passThroughEnv envType source =
    let
        lines =
            source |> String.trim |> String.lines |> List.filter (\l -> String.length l > 0)

        optArgs_ =
            runParser (itemList optionalArg) (List.head lines |> Maybe.withDefault "")

        body =
            if optArgs_ == [] then
                lines |> String.join "\n"

            else
                List.drop 1 lines |> String.join "\n"
    in
    Environment envType optArgs_ (LXString body)



{- ITEMIZED LISTS -}


itemEnvironmentBody : String -> String -> LXParser LatexExpression
itemEnvironmentBody endWoord envType =
    ---  inContext "itemEnvironmentBody" <|
    succeed identity
        |. ws
        |= itemList (oneOf [ item, lazy (\_ -> environment) ])
        |. ws
        |. symbol (Token endWoord (ExpectingEndWordInItemList endWoord))
        |. ws
        |> map LatexList
        |> map (Environment envType [])


biblioEnvironmentBody : String -> String -> LXParser LatexExpression
biblioEnvironmentBody endWoord envType =
    ---  inContext "itemEnvironmentBody" <|
    succeed identity
        |. ws
        |= itemList smacro
        |. ws
        |. symbol (Token endWoord (ExpectingEndWord endWoord))
        |. ws
        |> map LatexList
        |> map (Environment envType [])


biblioExample =
    """
\\begin{thebibliography}

\\bibitem{X} ABCD

\\bibitem{Y} EFGH

\\end{thebibliography}
"""


item : LXParser LatexExpression
item =
    ---  inContext "item" <|
    succeed identity
        |. spaces
        |. symbol (Token "\\item" ExpectingEscapedItem)
        |. symbol (Token " " ExpectingSpaceAfterItem)
        |. spaces
        |= itemList (oneOf [ words, inlineMath ws, macro ws ])
        |. ws
        |> map (\x -> Item 1 (LatexList x))



{- TABLES -}


tabularEnvironmentBody : String -> String -> LXParser LatexExpression
tabularEnvironmentBody endWoord envType =
    -- inContext "tabularEnvironmentBody" <|
    succeed (Environment envType)
        |. ws
        |= itemList arg
        |= tableBody
        |. ws
        |. symbol (Token endWoord (ExpectingEndWord endWoord))
        |. ws


tableBody : LXParser LatexExpression
tableBody =
    --  inContext "tableBody" <|
    succeed identity
        --|. repeat zeroOrMore arg
        |. ws
        |= nonEmptyItemList tableRow
        |> map LatexList


tableRow : LXParser LatexExpression
tableRow =
    --- inContext "tableRow" <|
    succeed identity
        |. spaces
        |= andThen (\c -> tableCellHelp [ c ]) tableCell
        |. spaces
        |. oneOf [ symbol (Token "\n" ExpectingNewline), symbol (Token "\\\\\n" ExpectingDoubleEscapeAndNewline) ]
        |> map LatexList



-- ###


tableCell : LXParser LatexExpression
tableCell =
    -- inContext "tableCell" <|
    succeed identity
        |= oneOf [ displayMathBrackets, macro ws, displayMathDollar, inlineMath ws, tableCellWords ]


tableCellHelp : List LatexExpression -> LXParser (List LatexExpression)
tableCellHelp revCells =
    --  inContext "tableCellHelp" <|
    oneOf
        [ nextCell
            |> andThen (\c -> tableCellHelp (c :: revCells))
        , succeed (List.reverse revCells)
        ]


nextCell : LXParser LatexExpression
nextCell =
    --  inContext "nextCell" <|
    -- (delayedCommit spaces <|
    succeed identity
        |. symbol (Token "&" ExpectingAmpersand)
        |. spaces
        |= tableCell



--
-- HELPERS
--


spaces : LXParser ()
spaces =
    chompWhile (\c -> c == ' ')


ws : LXParser ()
ws =
    chompWhile (\c -> c == ' ' || c == '\n')


parseUntil : Problem -> String -> LXParser String
parseUntil problem marker =
    getChompedString <| chompUntil (Token marker problem)


{-| chomp to end of the marker and return the
chomped string minus the marker.
-}
parseToSymbol : Problem -> String -> LXParser String
parseToSymbol problem marker =
    (getChompedString <|
        succeed identity
            |= chompUntilEndOr marker
            |. symbol (Token marker problem)
    )
        |> map (String.dropRight (String.length marker))


parseBetweenSymbols : Problem -> Problem -> String -> String -> LXParser String
parseBetweenSymbols problem1 problem2 startSymbol endSymbol =
    succeed identity
        |. symbol (Token startSymbol problem1)
        |. spaces
        |= parseUntil problem2 endSymbol



{- ITEM LIST PARSERS -}


nonEmptyItemList : LXParser a -> LXParser (List a)
nonEmptyItemList itemParser =
    itemParser
        |> andThen (\x -> itemList_ [ x ] itemParser)


itemList : LXParser a -> LXParser (List a)
itemList itemParser =
    itemList_ [] itemParser


itemList_ : List a -> LXParser a -> LXParser (List a)
itemList_ initialList itemParser =
    loop initialList (itemListHelper itemParser)


itemListHelper : LXParser a -> List a -> LXParser (Step (List a) (List a))
itemListHelper itemParser revItems =
    oneOf
        [ succeed (\item_ -> Loop (item_ :: revItems))
            |= itemParser
        , succeed ()
            |> map (\_ -> Done (List.reverse revItems))
        ]



-- itemListWithSeparator : Parser () -> Parser a -> Parser (List a)
-- itemListWithSeparator separatorParser itemParser =
--     Parser.loop [] (itemListWithSeparatorHelper separatorParser itemParser)
-- itemListWithSeparatorHelper : Parser () -> Parser a -> List a -> Parser (Step (List a) (List a))
-- itemListWithSeparatorHelper separatorParser itemParser revItems =
--     oneOf
--         [ succeed (\w -> Loop (w :: revItems))
--             |= itemParser
--             |. separatorParser
--         , succeed ()
--             |> Parser.map (\_ -> Done (List.reverse revItems))
--         ]
{-
   notSpecialTableOrMacroCharacter : Char -> Bool
   notSpecialTableOrMacroCharacter c =
       not (c == ' ' || c == '\n' || c == '\\' || c == '$' || c == '}' || c == ']' || c == '&')


   notMacroSpecialCharacter : Char -> Bool
   notMacroSpecialCharacter c =
       not (c == '{' || c == '[' || c == ' ' || c == '\n')

-}


{-| Transform special words
-}
transformWords : String -> String
transformWords str =
    if str == "--" then
        "\\ndash"

    else if str == "---" then
        "\\mdash"

    else
        str



{- From Punie/elm-parser-extras -}


{-| Apply a parser zero or more times and return a list of the results.
-}
many : LXParser a -> LXParser (List a)
many p =
    loop [] (manyHelp p)


{-| Apply a parser one or more times and return a tuple of the first result parsed
and the list of the remaining results.
-}
some : LXParser a -> LXParser ( a, List a )
some p =
    succeed Tuple.pair
        |= p
        |. spaces
        |= many p


{-| Parse an expression between two other parser

    import Parser exposing(symbol)

    Parser.run (between (symbol "<<") (symbol ">>") Parser.int) "<<4>>"
    --> Ok 4

-}
between : LXParser opening -> LXParser closing -> LXParser a -> LXParser a
between opening closing p =
    succeed identity
        |. opening
        |. spaces
        |= p
        |. spaces
        |. closing


{-| Parse an expression between parenthesis.

    import Parser

    Parser.run (parens Parser.int) "(4)"
    --> Ok 4

-}
parens : LXParser a -> LXParser a
parens =
    between (symbol (Token "(" ExpectingLeftParen)) (symbol (Token ")" ExpectingRightParen))


{-| Parse an expression between curly braces.

    import Parser

    Parser.run (braces Parser.int) "{4}"
    --> Ok 4

-}
braces : LXParser a -> LXParser a
braces =
    between (symbol (Token "{" ExpectingLeftBrace)) (symbol (Token "}" ExpectingRightBrace))


{-| Parse an expression between square brackets.
brackets p == between (symbol "[") (symbol "]") p
-}
brackets : LXParser a -> LXParser a
brackets =
    between (symbol (Token "[" ExpectingLeftBracket)) (symbol (Token "]" ExpectingRightBracket))



-- HELPERS


manyHelp : LXParser a -> List a -> LXParser (Step (List a) (List a))
manyHelp p vs =
    oneOf
        [ succeed (\v -> Loop (v :: vs))
            |= p
            |. spaces
        , succeed ()
            |> map (\_ -> Done (List.reverse vs))
        ]
