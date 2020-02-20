module Internal.SourceMap exposing (SourceMap, generate)

import Dict exposing (Dict)
import BiDict exposing(BiDict)
import Internal.Parser exposing (LatexExpression(..))


type alias SourceMap =
    BiDict String String



getText : List LatexExpression -> List String
getText list =
    list
        |> List.map text
        |> List.concat


text : LatexExpression -> List String
text expr =
    case expr of
        LXString str ->
            [ str ]

        Comment str ->
            [ str ]

        Item _ expr2 ->
            text expr2

        InlineMath str ->
            [ str ]

        DisplayMath str ->
            [ str ]

        SMacro _ _ _ expr2 ->
            text expr2

        Macro _ _ _ ->
            [ "Macro" ]

        Environment name _ expr2 ->
            name :: text expr2

        LatexList list ->
            List.map text list |> List.concat

        NewCommand _ _ _ ->
            [ "NewCommand" ]

        LXError _ ->
            [ "LXError" ]




--
-- generateSimple : a -> b -> List c -> List d -> List (c, d)


generate : List String -> List String -> SourceMap
generate  idList paragraphs =
    List.map2 (\id p -> ( id, p )) paragraphs idList
        |> BiDict.fromList
