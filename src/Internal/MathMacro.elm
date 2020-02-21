module Internal.MathMacro exposing (..)

import Dict
import Parser.Advanced exposing (..)
import Set
import Dict exposing(Dict)
import List.Extra

{-| The type for the Abstract syntax tree
-}
type MathExpression
    = MathText String
    | Macro String (List MathExpression)
    | MathList (List MathExpression)


type alias MacroDict = Dict String (List String -> String)

macroDict : Dict.Dict String ( List String -> String)
macroDict = Dict.fromList [("bb", \list -> "{\\bf B}"), ("bt", \list -> "{\\bf " ++ (getArg 0 list) ++ "}")]

getArg : Int -> List String -> String
getArg k list = List.Extra.getAt k list |> Maybe.withDefault ""


type alias MXParser a =
    Parser.Advanced.Parser Context Problem a
    
type Context
    = CArg String
    | List


type Problem
    = ExpectingLeftBrace
    | ExpectingRightBrace
    | ExpectingMacroReservedWord
    | ExpectingValidMacroArgWord
    | ExpectingLeftBracket
    | ExpectingInt
    | ExpectingRightBracket
    | InvalidInt
    | ExpectingStuff

{-|

    parse "x + y = \\foo{bar} + z"
    --> Ok [MathText ("x + y = "),Macro "foo" [MathList [MathText "bar"]],MathText ("+ z")]
-}
parse : String -> Result (List (DeadEnd Context Problem)) (List MathExpression)
parse str =
    run (many mathExpression) str

check : String -> String
check str =
    case parse str of
        Ok (result) -> text result
        Err _ -> "error"


{-|
    macroDict = Dict.fromList [("bb", \list -> "{\\bf B}"), ("bt", \list -> "{\\bf " ++ (getArg 1 list) ++ "}")]

    evalStr macroDict "\\int_0^1 x^n dx + \\bb"
    --> "\\int_0^1 x^n dx + {\\bf B}"

    evalStr macroDict "\\int_0^1 x^n dx + \\bt{Z}"
    --> "\\int_0^1 x^n dx + {\\bf Z}"
-}
evalStr : MacroDict ->  String -> String
evalStr macroDict_ str =
    case parse str of
        Ok (result) -> evalList macroDict_ result
        Err _ -> "error"


evalList :  MacroDict -> List MathExpression -> String
evalList macroDict_ list =
  List.map (evalExpr macroDict_) list
  |> String.join ""

evalExpr :  MacroDict -> MathExpression -> String
evalExpr macroDict_ expr =
    case expr of
        MathText str -> str
        Macro name args -> evalMacro macroDict_ name args
        MathList list -> List.map text_ list |> String.join " "


evalMacro : MacroDict -> String -> List MathExpression -> String
evalMacro macroDict_ name args =
    case Dict.get name macroDict_ of
        Nothing -> "\\" ++ name ++ (List.map (text_ >> enclose) args |> String.join "")
        Just definition -> definition (List.map text_ args)



evalMacro1 : MacroDict -> String -> List MathExpression -> String
evalMacro1 macroDict_ name args =
    "\\" ++ name ++ (List.map (text_ >> enclose) args |> String.join "")



-- TEXT

text : List MathExpression -> String
text list =
    List.map text_ list
    |> String.join ""


text_ : MathExpression -> String
text_ expr =
    case expr of
        MathText str -> str
        Macro name args -> "\\" ++ name ++ (List.map (text_ >> enclose) args |> String.join "")
        MathList list -> List.map text_ list |> String.join "||"

enclose : String -> String
enclose arg_ =
    "{" ++ arg_ ++ "}"

mathExpression : MXParser MathExpression
mathExpression =
    oneOf
        [
           macro
         , mathStuff
         ]

{-|
    run mathStuff "x + y = \\foo"
    --> Ok (MathText ("x + y = "))
-}
mathStuff : MXParser MathExpression
mathStuff =
    stuff ExpectingStuff inStuff |> map MathText

inStuff : Char -> Bool
inStuff c = not (c == '\\')

{-|
    run (stuff ExpectingStuff inStuff) "x + y = \\foo"
    --> Ok ("x + y = ")
-}
stuff : Problem -> (Char -> Bool) -> MXParser String
stuff problem inWord =
    succeed String.slice
        |. ws
        |= getOffset
        |. chompIf inStuff problem
        |. chompWhile inStuff
        |. ws
        |= getOffset
        |= getSource
 
{-|

    import MXParser

    MXParser.run numberOfArgs "[3]"
    --> Ok 3

-}
numberOfArgs : MXParser Int
numberOfArgs =
    many numberOfArgs_
        |> map List.head
        |> map (Maybe.withDefault 0)


{-| Parse the macro keyword followed by
zero or more more arguments.

    run (macro ws) "\\bf{1}"
    --> Ok (Macro "bf" [MathList [MathText "1"]])

    run (macro ws) "\\foo"
    --> Ok (Macro "foo" [])

-}
macro :  MXParser MathExpression

macro  =
    succeed Macro
        |= macroName
        |= itemList arg
        -- |. wsParser



{-| Use to parse arguments for macros
-}
arg : MXParser MathExpression
arg =
    inContext (CArg "arg") <|
        (succeed identity
            |. symbol (Token "{" ExpectingLeftBrace)
            |= itemList (oneOf [ macroArgWords, lazy (\_ -> macro) ])
            |. symbol (Token "}" ExpectingRightBrace)
            |> map MathList
        )


macroName : MXParser String
macroName =
    variable
        { start = \c -> c == '\\'
        , inner = \c -> Char.isAlphaNum c || c == '*'
        , reserved = Set.fromList [ "\\begin", "\\end", "\\item", "\\bibitem" ]
        , expecting = ExpectingMacroReservedWord
        }
        |> map (String.dropLeft 1)


{- MACRO WORDS -}


macroArgWords :  MXParser MathExpression
macroArgWords =
    nonEmptyItemList (word ExpectingValidMacroArgWord inMacroArg)
        |> map (String.join " ")
        |> map MathText


inMacroArg : Char -> Bool
inMacroArg c =
    not (c == '\\' || c == '$' || c == '}' || c == ' ' || c == '\n')


{-| Use `inWord` to parse a word.

import Parser

inWord : Char -> Bool
inWord c = not (c == ' ')

MXParser.run word "this is a test"
--> Ok "this"

-}
word : Problem -> (Char -> Bool) -> MXParser String
word problem inWord =
    succeed String.slice
        |. ws
        |= getOffset
        |. chompIf inWord problem
        |. chompWhile inWord
        |. ws
        |= getOffset
        |= getSource


numberOfArgs_ : MXParser Int
numberOfArgs_ =
    succeed identity
        |. symbol (Token "[" ExpectingLeftBracket)
        |= int ExpectingInt InvalidInt
        |. symbol (Token "]" ExpectingRightBracket)


--
-- HELPERS
--


spaces : MXParser ()
spaces =
    chompWhile (\c -> c == ' ')


ws : MXParser ()
ws =
    chompWhile (\c -> c == ' ' || c == '\n')


parseUntil : Problem -> String -> MXParser String
parseUntil problem marker =
    getChompedString <| chompUntil (Token marker problem)


{-| chomp to end of the marker and return the
chomped string minus the marker.
-}
parseToSymbol : Problem -> String -> MXParser String
parseToSymbol problem marker =
    (getChompedString <|
        succeed identity
            |= chompUntilEndOr marker
            |. symbol (Token marker problem)
    )
        |> map (String.dropRight (String.length marker))


parseBetweenSymbols : Problem -> Problem -> String -> String -> MXParser String
parseBetweenSymbols problem1 problem2 startSymbol endSymbol =
    succeed identity
        |. symbol (Token startSymbol problem1)
        |. spaces
        |= parseUntil problem2 endSymbol



{- ITEM LIST PARSERS -}


nonEmptyItemList : MXParser a -> MXParser (List a)
nonEmptyItemList itemParser =
    itemParser
        |> andThen (\x -> itemList_ [ x ] itemParser)


itemList : MXParser a -> MXParser (List a)
itemList itemParser =
    itemList_ [] itemParser


itemList_ : List a -> MXParser a -> MXParser (List a)
itemList_ initialList itemParser =
    loop initialList (itemListHelper itemParser)


itemListHelper : MXParser a -> List a -> MXParser (Step (List a) (List a))
itemListHelper itemParser revItems =
    oneOf
        [ succeed (\item_ -> Loop (item_ :: revItems))
            |= itemParser
        , succeed ()
            |> map (\_ -> Done (List.reverse revItems))
        ]


{-| Apply a parser zero or more times and return a list of the results.
-}
many : MXParser a -> MXParser (List a)
many p =
    loop [] (manyHelp p)


manyHelp : MXParser a -> List a -> MXParser (Step (List a) (List a))
manyHelp p vs =
    oneOf
        [ succeed (\v -> Loop (v :: vs))
            |= p
            |. spaces
        , succeed ()
            |> map (\_ -> Done (List.reverse vs))
        ]

{-| Apply a parser one or more times and return a tuple of the first result parsed
and the list of the remaining results.
-}
some : MXParser a -> MXParser ( a, List a )
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
between : MXParser opening -> MXParser closing -> MXParser a -> MXParser a
between opening closing p =
    succeed identity
        |. opening
        |. spaces
        |= p
        |. spaces
        |. closing