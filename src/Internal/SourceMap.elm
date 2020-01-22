module Internal.SourceMap exposing (generate, SourceMap)

import Internal.Parser exposing(LatexExpression(..))
import Dict exposing(Dict)


getText : List LatexExpression -> List String
getText list =
    list
      |> List.map text
      |> List.concat


text : LatexExpression -> List String
text expr =
    case expr of
        LXString str -> [str]
        Comment str -> [str]
        Item _ expr2 -> text expr2
        InlineMath str -> [str]
        DisplayMath str -> [str]
        SMacro _ _ _ expr2 -> text expr2
        Macro _ _ _ -> ["Macro"]
        Environment name _ expr2 ->  name :: text expr2
        LatexList list -> (List.map text list |> List.concat)
        NewCommand _ _ _ -> ["NewCommand"]
        LXError _ -> ["LXError"]

type alias SourceMap = Dict String String

{-|
    lexpr = parse "Ho ho ho: $a^2 = 7$"
    --> [LXString ("Ho  ho  ho: "),InlineMath ("a^2 = 7")]

    idList = ["1", "2"]
    --> ["1","2"]

    generate lexpr idList
    --> Dict.fromList [("Ho  ho  ho: ","1"),("a^2 = 7","2")]

-}
generate : List LatexExpression -> List String -> SourceMap
generate listExpr listId =
    List.map2 (\a b -> (a,b)) (getText listExpr) listId
      |> Dict.fromList