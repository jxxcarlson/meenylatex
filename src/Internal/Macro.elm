module Internal.Macro exposing (expandMacro)

import Internal.LatexState exposing (emptyLatexState)
import Internal.Parser exposing (LatexExpression(..))
import Internal.RenderToString
import Parser


{-| EXAMPLE

    import Parser exposing(run)
    import Internal.Parser exposing(..)
    import Internal.Macro exposing(..)

    run latexExpression "\\newcommand{\\hello}[1]{Hello \\strong{#1}!}"
    --> Ok (NewCommand "hello" 1 (LatexList [LXString ("Hello "),Macro "strong" [] [LatexList [LXString "#1"]],LXString "!"]))

    run latexExpression "\\hello{John}"
    --> Ok (Macro "hello" [] [LatexList [LXString "John"]])

    macroDef : LatexExpression
    macroDef = NewCommand "hello" 1 (LatexList [LXString ("Hello "),Macro "strong" [] [LatexList [LXString "#1"]],LXString "!"])

    macro : LatexExpression
    macro = Macro "hello" [] [LatexList [LXString "John"]]

    expandMacro macro macroDef
    --> LatexList [LXString ("Hello "),Macro "strong" [] [LatexList [LXString "John"]],LXString "!"]

-}
expandMacro : LatexExpression -> LatexExpression -> LatexExpression
expandMacro macro macroDef =
    case expandMacro_ macro macroDef of
        NewCommand _ _ latexList ->
            latexList

        _ ->
            LXString "error"


expandMacro_ : LatexExpression -> LatexExpression -> LatexExpression
expandMacro_ macro macroDef =
    case macroDef of
        Comment str ->
            Comment str

        Macro name optArgs args ->
            Macro name optArgs (List.map (expandMacro_ macro) args)

        SMacro name optArgs args le ->
            SMacro name optArgs (List.map (expandMacro_ macro) args) (expandMacro_ macro le)

        Item level latexExpr ->
            Item level (expandMacro_ macro latexExpr)

        InlineMath str ->
            InlineMath str

        DisplayMath str ->
            DisplayMath str

        Environment name args body ->
            Environment name args (expandMacro_ macro body)

        LatexList latexList ->
            LatexList (List.map (expandMacro_ macro) latexList)

        LXString str ->
            LXString (substitute macro str)

        NewCommand commandName numberOfArgs commandBody ->
            NewCommand commandName numberOfArgs (expandMacro_ macro commandBody)

        LXError error ->
            LXError error



-- SUBSTITUTION


substitute : LatexExpression -> String -> String
substitute macro str =
    substituteMany (nArgs macro) macro str


substituteOne : Int -> LatexExpression -> String -> String
substituteOne k macro str =
    let
        arg =
            renderArg k macro

        hashK =
            "#" ++ String.fromInt k
    in
    String.replace hashK arg str


nArgs : LatexExpression -> Int
nArgs latexExpression =
    case latexExpression of
        Macro name optArgs args ->
            List.length args

        _ ->
            0


substituteMany : Int -> LatexExpression -> String -> String
substituteMany k macro str =
    if k == 0 then
        str

    else
        substituteMany (k - 1) macro (substituteOne k macro str)


renderArg : Int -> LatexExpression -> String
renderArg k macro =
    case macro of
        Macro name optArgs args ->
            Internal.RenderToString.renderArg (k - 1) emptyLatexState args

        _ ->
            ""
