module MacroTest2 exposing (..)

import Dict exposing (Dict)


{- Lines of code: 39

   *Directions:* In `elm repl` do

    ```
    > import MacroTest2
    > render m1

    This should crash Elm with the message

       `ReferenceError: author$project$MacroTest1$cyclic$macroDict is not defined>`

    Here is one more test argument:

      `m2 = Macro "\\wasup" ([Arg ([Macro "\\lol" ([Arg ([MXString "foo"])])]),Arg ([MXString ("bar,  baz")])])``

    The values `m1` and `m2` were created with parser for MXExpression.
    See https://staging.ellie-app.com/gWSCH7s4K8a1/2

    The parser and renderer are simplified versions of what is used in MiniLaTeX.

-}


m1 =
    Macro "\\wasup" ([ Arg ([ MXString "foo" ]), Arg ([ MXString ("bar,  baz") ]) ])



--
-- m2 =
--     Macro "\\wasup" ([ Arg ([ Macro "\\lol" ([ Arg ([ MXString "foo" ]) ]) ]), Arg ([ MXString ("bar,  baz") ]) ])
--


type alias MacroDict =
    Dict String (MacroExpression -> String)


macroDict : MacroDict
macroDict =
    Dict.fromList
        [ ( "wasup", renderWasup )
        , ( "lol", renderLol )
        ]


evalDict : MacroDict -> String -> List MacroExpression -> String
evalDict dict macroName_ argList =
    case (Dict.get macroName_ dict) of
        Just f ->
            (List.map f argList) |> String.join " "

        Nothing ->
            "Nothing"


renderWasup argList =
    "<wasup>" ++ render argList ++ "</wasup>"


renderLol argList =
    "<lol>" ++ render argList ++ "</lol>"


render : MacroExpression -> String
render macroExpression =
    case macroExpression of
        MXString str ->
            str

        Macro name argList ->
            evalDict macroDict name argList

        Arg argList ->
            List.map render argList |> String.join " "

        MXError _ ->
            "Error"


type MacroExpression
    = MXString String
    | Macro String (List MacroExpression)
    | Arg (List MacroExpression)
    | MXError (List DeadEnd)
