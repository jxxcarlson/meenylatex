module Internal.Paragraph2 exposing (..)

import Parser.Advanced exposing (..)


co =
    """% comment
"""


mb =
    """$$
a == b
$$
"""


ob =
    """\\begin{foo}
bar
\\end{foo}
"""


pa =
    """one
two

"""


s0 =
    """one
two

$$
a == b
$$

\\begin{foo}
bar
\\end{foo}

three
four

"""


s1 =
    """
\\begin{foo}
bar
\\end{foo}
"""


s2 =
    """
\\begin{foo}

bar
\\end{foo}
"""


e1 =
    """
\\begin{foo}

  """


e2 =
    """
one

\\begin{foo}

two
  """


type LogicalParagraph
    = Paragraph String
    | OuterBlock String String
    | MathBlock String
    | Comment String



--| InitialBlanks


type alias PParser a =
    Parser.Advanced.Parser Context Problem a


type Context
    = CArg String
    | List


type Problem
    = ExpectingPercent
    | ExpectingDoubleDollarAtStart
    | ExpectingToChompUntilDoublelDollar
    | ExpectingDoubleDollarAtEnd
    | ExpectingBeginWord
    | ExpectingMarker String
    | ChompUntileNewLine
    | ChompUntilTwoNewLines
    | ChompUntilEndWord String
    | ExpectingEndWord String
    | ExpectingInitialBlank
    | ExpectingInitialNewLine



-- logicalParagraphify : String -> List String


{-|

    > logicalParagraphify "$$ a == b $$\n\nAnd also:\n\n\\begin{foo}bar\\end{foo}  "
    ["$$ a == b $$","And also:","\\begin{foo}\nbar\\end{foo}"]

-}
logicalParagraphify str =
    case Parser.Advanced.run parseMany str of
        Ok list ->
            List.map render list

        Err _ ->
            [ "error" ]


render : LogicalParagraph -> String
render par =
    case par of
        Paragraph str ->
            str

        OuterBlock name body ->
            "\\begin{" ++ name ++ "}\n" ++ body ++ "\\end{" ++ name ++ "}"

        MathBlock body ->
            "$$\n" ++ body ++ "\n$$"

        Comment body ->
            ""


{-|

    > run parseMany"$$ a == b $$\n\nAnd also:\n\n\\begin{foo}bar\\end{foo}  "
    Ok [Paragraph ("$$ a == b $$"),Paragraph ("And also:"),OuterBlock "foo" "bar"]

-}
parseMany : PParser (List LogicalParagraph)
parseMany =
    many parse


many : PParser a -> PParser (List a)
many p =
    loop [] (manyHelp p)


manyHelp : PParser a -> List a -> PParser (Step (List a) (List a))
manyHelp p vs =
    oneOf
        [ succeed (\v -> Loop (v :: vs))
            |= p

        --|. spaces
        , succeed ()
            |> map (\_ -> Done (List.reverse vs))
        ]


parse : PParser LogicalParagraph
parse =
    oneOf [ comment, outerBlock, mathBlock, paragraph ]



--
-- initialBlanks : PParser LogicalParagraph
-- initialBlanks =
--     succeed InitialBlanks
--         |. oneOf [ symbol (Token " " ExpectingInitialBlank), symbol (Token "\n" ExpectingInitialNewLine) ]
--         |. chompWhile (\c -> c /= ' ' || c /= '\n')


comment : PParser LogicalParagraph
comment =
    succeed Comment
        |. symbol (Token "%" ExpectingPercent)
        |= getChompedString (chompUntil (Token "\n" ChompUntileNewLine))
        |. spaces


paragraph : PParser LogicalParagraph
paragraph =
    succeed Paragraph
        |= getChompedString (chompUntil (Token "\n\n" ChompUntilTwoNewLines))
        |. spaces


outerBlock : PParser LogicalParagraph
outerBlock =
    blockStart |> andThen blockOfName


mathBlock : PParser LogicalParagraph
mathBlock =
    succeed MathBlock
        |. symbol (Token "$$" ExpectingDoubleDollarAtStart)
        |= getChompedString (chompUntil (Token "$$" ExpectingToChompUntilDoublelDollar))
        |. symbol (Token "$$" ExpectingDoubleDollarAtEnd)
        |. spaces


blockStart : PParser String
blockStart =
    --  inContext "envName" <|
    succeed identity
        |. spaces
        |. symbol (Token "\\begin{" ExpectingBeginWord)
        |= parseToSymbol "}"


blockOfName : String -> PParser LogicalParagraph
blockOfName name =
    let
        endWord =
            "\\end{" ++ name ++ "}"
    in
    succeed (\s -> OuterBlock name s)
        |= getChompedString (chompUntil (Token endWord (ChompUntilEndWord name)))
        |. symbol (Token endWord (ExpectingEndWord endWord))
        |. spaces


{-| chomp to end of the marker and return the
chomped string minus the marker.
-}
parseToSymbol : String -> PParser String
parseToSymbol marker =
    (getChompedString <|
        succeed identity
            |= chompUntilEndOr marker
            |. symbol (Token marker (ExpectingMarker marker))
    )
        |> map (String.dropRight (String.length marker))
