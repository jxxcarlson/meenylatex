module Internal.Utility exposing (addLineNumbers, addLineNumbers_, capitalize, getAt)

{-| From List.Extra
-}


getAt : Int -> List a -> Maybe a
getAt idx xs =
    if idx < 0 then
        Nothing

    else
        List.head <| List.drop idx xs


{-| Add line numbers to a piece of text.
-}
addLineNumbers : String -> String
addLineNumbers text =
    text
        |> String.trim
        |> String.split "\n"
        |> List.foldl addNumberedLine ( 0, [] )
        |> Tuple.second
        |> List.reverse
        |> String.join "\n"


addLineNumbers_ : String -> List String
addLineNumbers_ text =
    text
        |> String.trim
        |> String.split "\n"
        |> List.foldl addNumberedLine ( 0, [] )
        |> Tuple.second
        |> List.reverse


addNumberedLine : String -> ( Int, List String ) -> ( Int, List String )
addNumberedLine line data =
    let
        ( k, lines ) =
            data
    in
    ( k + 1, [ numberedLine (k + 1) line ] ++ lines )


numberedLine : Int -> String -> String
numberedLine k line =
    String.padLeft 2 ' ' (String.fromInt k) ++ " " ++ line


capitalize : String -> String
capitalize str =
    (String.left 1 str |> String.toUpper) ++ String.dropLeft 1 str
