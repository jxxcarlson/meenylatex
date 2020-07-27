module Internal.Paragraph2 exposing (logicalParagraphify)

import Parser exposing (..)


type LogicalParagraph
    = Paragraph String
    | OuterBlock String String
    | MathBlock String



-- logicalParagraphify : String -> List String


{-|

    > logicalParagraphify "$$ a == b $$\n\nAnd also:\n\n\\begin{foo}bar\\end{foo}  "
    ["$$ a == b $$","And also:","\\begin{foo}\nbar\\end{foo}"]

-}
logicalParagraphify str =
    case Parser.run parseMany str of
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


{-|

    > run parseMany"$$ a == b $$\n\nAnd also:\n\n\\begin{foo}bar\\end{foo}  "
    Ok [Paragraph ("$$ a == b $$"),Paragraph ("And also:"),OuterBlock "foo" "bar"]

-}
parseMany : Parser (List LogicalParagraph)
parseMany =
    many parse


many : Parser a -> Parser (List a)
many p =
    loop [] (manyHelp p)


manyHelp : Parser a -> List a -> Parser (Step (List a) (List a))
manyHelp p vs =
    oneOf
        [ succeed (\v -> Loop (v :: vs))
            |= p
            |. spaces
        , succeed ()
            |> map (\_ -> Done (List.reverse vs))
        ]


parse : Parser LogicalParagraph
parse =
    oneOf [ paragraph, outerBlock, mathBlock ]


paragraph : Parser LogicalParagraph
paragraph =
    succeed Paragraph
        |= getChompedString (chompUntil "\n\n")
        |. spaces


outerBlock : Parser LogicalParagraph
outerBlock =
    blockStart |> andThen blockOfName


mathBlock : Parser LogicalParagraph
mathBlock =
    succeed MathBlock
        |. symbol "$$"
        |= getChompedString (chompUntil "$$")
        |. symbol "$$"
        |. spaces


blockStart : Parser String
blockStart =
    --  inContext "envName" <|
    succeed identity
        |. spaces
        |. symbol "\\begin{"
        |= parseToSymbol "}"


blockOfName : String -> Parser LogicalParagraph
blockOfName name =
    let
        endWord =
            "\\end{" ++ name ++ "}"
    in
    succeed (\s -> OuterBlock name s)
        |= getChompedString (chompUntil endWord)
        |. spaces


{-| chomp to end of the marker and return the
chomped string minus the marker.
-}
parseToSymbol : String -> Parser String
parseToSymbol marker =
    (getChompedString <|
        succeed identity
            |= chompUntilEndOr marker
            |. symbol marker
    )
        |> map (String.dropRight (String.length marker))
