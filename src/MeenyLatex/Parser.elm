module MeenyLatex.Parser exposing (..)

-- exposing
--     ( LatexExpression(..)
--     , defaultLatexList
--     , endWord
--     , envName
--     , latexList
--     , macro
--     , parse
--     )

import Dict
import MeenyLatex.ParserHelpers as PH exposing (..)
import Parser exposing (..)
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
    | LXError (List DeadEnd)


parse : String -> List LatexExpression
parse text =
    let
        expr =
            Parser.run latexList text
    in
    case expr of
        Ok (LatexList list) ->
            list

        Err error ->
            [ LXError error ]

        _ ->
            [ LXString "yada!" ]


defaultLatexList : LatexExpression
defaultLatexList =
    LatexList [ LXString "Parse Error" ]


defaultLatexExpression : List LatexExpression
defaultLatexExpression =
    [ Macro "NULL" [] [] ]



{- WORDS AND TEXT -}
words : Parser LatexExpression
words = genericWords word

genericWords : Parser String -> Parser LatexExpression
genericWords wordParser =
         wordList wordParser
            |> map (String.join " ")
            |> map LXString
        

wordList : Parser String -> Parser (List String)
wordList wordParser = 
   Parser.loop [] (wordListHelp wordParser)
   
   
wordListHelp : Parser String -> List String -> Parser (Step (List String) (List String))
wordListHelp wordParser revWords = 
  oneOf [  succeed (\w -> Loop (w :: revWords))
             |= wordParser
             |. PH.spaces
         , succeed () 
             |> Parser.map (\_ -> Done (List.reverse revWords))
       ]


{-| Like `words`, but after a word is recognized spaces, not spaces + newlines are consumed
-}
specialWords : Parser LatexExpression
specialWords = genericWords specialWord
 


macroArgWords : Parser LatexExpression
macroArgWords = genericWords macroArgWord
 


texComment : Parser LatexExpression
texComment = 
  parseFromTo "%" "\n"
     |> map Comment
        



{- MACROS -}
{- NOTE: macro sequences should be of the form "" followed by alphabetic characterS,
   but not equal to certain reserved words, e.g., "\begin", "\end", "\item"
-}


-- type alias Macro2 =
--     String (List LatexExpression) (List LatexExpression)


macro : Parser () -> Parser LatexExpression
macro wsParser =
    --  "macro" <|
        (succeed Macro
            |= macroName
            |= simpleItemList optionalArg
            |= simpleItemList arg
            |. wsParser
        )



{-| Use to parse arguments for macros
-}
optionalArg : Parser LatexExpression
optionalArg =
    -- inContext "optionalArg" <|
        (succeed identity
            |. symbol "["
            |= simpleItemList (oneOf [ specialWords, inlineMath PH.spaces ])
            |. symbol "]"
            |> map LatexList
        )


{-| Use to parse arguments for macros
-}
arg : Parser LatexExpression
arg =
    -- inContext "arg" <|
        (succeed identity
            |. symbol "{"
            |= simpleItemList (oneOf [ macroArgWords, inlineMath PH.spaces, lazy (\_ -> macro ws) ])
            |. symbol "}"
            |> map LatexList
        )

macroName : Parser String
macroName =
  variable
    { start = \c -> c == '\\'
    , inner = \c -> Char.isAlphaNum c
    , reserved = Set.fromList [ "\\begin", "\\end", "\\item", "\\bibitem" ]
    }
 

smacro : Parser LatexExpression
smacro =
    succeed SMacro
        |= smacroName
        |= simpleItemList optionalArg
        |= simpleItemList arg
        |= smacroBody


smacroName : Parser String
smacroName =
  variable
    { start = \c -> c == '\\'
    , inner = \c -> Char.isAlphaNum c
    , reserved = Set.fromList [ "\\begin", "\\end", "\\item" ]
    }
 

smacroBody : Parser LatexExpression
smacroBody =
   --  inContext "smacroBody" <|
        (succeed identity
            |. PH.spaces
            |= simpleItemList1 (oneOf [ specialWords, inlineMath PH.spaces, macro PH.spaces ])
            |. symbol "\n\n"
            |> map (\x -> LatexList x)
        )



{- Latex List and Expression -}


{-| Production: $ LatexList &\Rightarrow LatexExpression^+ $
-}
latexList : Parser LatexExpression
latexList =
    -- inContext "latexList" <|
        (succeed identity
            |. ws
            |= simpleItemList1 latexExpression
            |> map LatexList
        )


{-| Production: $ LatexExpression &\Rightarrow Words\ |\ Comment\ |\ IMath\ |\ DMath\ |\ Macro\ |\ Env $
-}
latexExpression : Parser LatexExpression
latexExpression =
    oneOf
        [ texComment
        , lazy (\_ -> environment)
        , displayMathDollar
        , displayMathBrackets
        , inlineMath ws
        , macro ws
        , smacro
        , words
        ]



{- MATHEMATICAL TEXT -}


inlineMath : Parser () -> Parser LatexExpression
inlineMath wsParser =
    -- inContext "inline math" <|
        succeed InlineMath
            |. symbol "$"
            |= parseUntil "$"
            |. wsParser


displayMathDollar : Parser LatexExpression
displayMathDollar =
    -- inContext "display math $$" <|
        succeed DisplayMath
            |. PH.spaces
            |. symbol "$$"
            |= parseUntil "$$"
            |. ws


displayMathBrackets : Parser LatexExpression
displayMathBrackets =
    -- inContext "display math brackets" <|
        succeed DisplayMath
            |. PH.spaces
            |. symbol "\\["
            |= parseUntil "\\]"



{- ENVIRONMENTS -}


environment : Parser LatexExpression
environment =
    -- inContext "environment" <|
        lazy (\_ -> envName |> andThen environmentOfType)


envName : Parser String
envName =
   --  inContext "envName" <|
        (succeed identity
            |. PH.spaces
            |. symbol "\\begin{"
            |= parseUntil "}"
        )


environmentOfType : String -> Parser LatexExpression
environmentOfType envType =
    --- inContext "environmentOfType" <|
        let
            theEndWord =
                "\\end{" ++ envType ++ "}"

            envKind =
                if List.member envType [ "equation", "align", "eqnarray", "verbatim", "listing", "verse" ] then
                    "passThrough"
                else
                    envType
        in
        environmentParser envKind theEndWord envType


endWord : Parser String
endWord =
    -- inContext "endWord" <|
        (succeed identity
            |. PH.spaces
            |. symbol "\\end{"
            |= parseUntil "}"
            |. ws
        )



{- DISPATCHER AND SUBPARSERS -}


environmentParser : String -> String -> String -> Parser LatexExpression
environmentParser name =
    case Dict.get name parseEnvironmentDict of
        Just p ->
            p

        Nothing ->
            standardEnvironmentBody


parseEnvironmentDict : Dict.Dict String (String -> String -> Parser LatexExpression)
parseEnvironmentDict =
    Dict.fromList
        [ ( "enumerate", \endWoord envType -> itemEnvironmentBody  endWoord envType )
        , ( "itemize", \endWoord envType -> itemEnvironmentBody endWoord envType )
        , ( "tabular", \endWoord envType -> tabularEnvironmentBody endWoord envType )
        , ( "passThrough", \endWoord envType -> passThroughBody endWoord envType )
        ]


standardEnvironmentBody : String -> String -> Parser LatexExpression
standardEnvironmentBody endWoord envType =
   --  inContext "standardEnvironmentBody" <|
        (succeed identity
            |. ws
            |= simpleItemList latexExpression
            |. ws
            |. symbol endWoord
            |. ws
            |> map LatexList
            |> map (Environment envType [])
        )


{-| The body of the environment is parsed as an LXString.
This parser is used for envronments whose body is to be
passed to MathJax for processing and also for the verbatim
environment.
-}
passThroughBody : String -> String -> Parser LatexExpression
passThroughBody endWoord envType =
   --  inContext "passThroughBody" <|
        (succeed identity
            |= parseUntil endWoord
            |. ws
            |> map LXString
            |> map (Environment envType [])
        )



{- ITEMIZED LISTS -}


itemEnvironmentBody : String -> String -> Parser LatexExpression
itemEnvironmentBody endWoord envType =
   ---  inContext "itemEnvironmentBody" <|
        (succeed identity
            |. ws
            |= simpleItemList item
            |. ws
            |. symbol endWoord
            |. ws
            |> map LatexList
            |> map (Environment envType [])
        )


item : Parser LatexExpression
item =
   ---  inContext "item" <|
        (succeed identity
            |. PH.spaces
            |. symbol "\\item"
            |. symbol " "
            |. PH.spaces
            |= simpleItemList (oneOf [ words, inlineMath PH.spaces, macro PH.spaces ])
            |. ws
            |> map (\x -> Item 1 (LatexList x))
        )



{- TABLES -}


tabularEnvironmentBody : String -> String -> Parser LatexExpression
tabularEnvironmentBody endWoord envType =
   -- inContext "tabularEnvironmentBody" <|
        (succeed (Environment envType)
            |. ws
            |= simpleItemList arg
            |= tableBody
            |. ws
            |. symbol endWoord
            |. ws
        )


tableBody : Parser LatexExpression
tableBody =
   --  inContext "tableBody" <|
        (succeed identity
            --|. repeat zeroOrMore arg
            |. ws
            |= simpleItemList1 tableRow
            |> map LatexList
        )


tableRow : Parser LatexExpression
tableRow =
   --- inContext "tableRow" <|
        (succeed identity
            |. PH.spaces
            |= andThen (\c -> tableCellHelp [ c ]) tableCell
            |. PH.spaces
            |. oneOf [ symbol "\n", symbol "\\\\\n" ]
            |> map LatexList
        )


tableCell : Parser LatexExpression
tableCell =
   -- inContext "tableCell" <|
        (succeed identity
            |= oneOf [ inlineMath PH.spaces, specialWords ]
        )


tableCellHelp : List LatexExpression -> Parser (List LatexExpression)
tableCellHelp revCells =
  --  inContext "tableCellHelp" <|
        oneOf
            [ nextCell
                |> andThen (\c -> tableCellHelp (c :: revCells))
            , succeed (List.reverse revCells)
            ]


nextCell : Parser LatexExpression
nextCell =
   --  inContext "nextCell" <|
       -- (delayedCommit PH.spaces <|
            succeed identity
                |. symbol "&"
                |. PH.spaces
                |= tableCell
        --)
