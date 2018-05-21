module Experiment2 exposing (..)

import Dict exposing (Dict)
import MeenyLatex.Parser exposing (LatexExpression)
import MeenyLatex.LatexState exposing (LatexState)


-- import MeenyLatex.Render exposing (renderBozo, renderBigSkip, renderCite)


type alias FDict a =
    Dict String (a -> a -> a)


fDict : FDict Float
fDict =
    Dict.fromList
        [ ( "add", add )
        , ( "mul", mul )
        ]


add x y =
    x + y


mul x y =
    x * y



--
-- boost : (x -> z -> output) -> (x -> y -> z -> output)
-- boost f =
--     \x y z -> f x z


evalDict : FDict a -> String -> a -> a -> Maybe a
evalDict dict str x y =
    case (Dict.get str dict) of
        Just g ->
            Just (g x y)

        Nothing ->
            Nothing
