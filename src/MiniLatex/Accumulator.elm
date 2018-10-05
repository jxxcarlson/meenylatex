module MiniLatex.Accumulator exposing (parse, render, info)

import Dict
import MiniLatex.LatexState
    exposing
        ( Counters
        , CrossReferences
        , LatexState
        , addSection
        , getCounter
        , incrementCounter
        , setCrossReference
        , setDictionaryItem
        , updateCounter
        )
import MiniLatex.Parser as Parser exposing (LatexExpression(..), macro)
import MiniLatex.Render2 as Render exposing (renderLatexList)
import MiniLatex.StateReducerHelpers as SRH


{-| Given an initial state and list of inputs of type a,
produce a list of outputs of type b and a new state
-}
type alias Accumulator state a b =
    state -> List a -> ( state, List b )


type alias Reducer a b =
    a -> b -> b


{-| parse: Using a given LatexState, take a list of strings,
i.e., paragraphs, and compute a tuple consisting of the parsed
paragraphs and ad upodated LatexState.

parse : LatexState -> List String -> ( List (List LatexExpression), LatexState )

-}
parse :
    LatexState
    -> List String
    -> ( LatexState, List (List LatexExpression) )
parse latexState paragraphs =
    paragraphs
        |> List.foldl parseReducer ( latexState, [] )


parseReducer :
    String
    -> ( LatexState, List (List LatexExpression) )
    -> ( LatexState, List (List LatexExpression) )
parseReducer inputString ( latexState, inputList ) =
    let
        parsedInput =
            Parser.parse inputString

        newLatexState =
            latexStateReducer parsedInput latexState
    in
    ( newLatexState, inputList ++ [ parsedInput ] )


{-| render: Using a given LatexState, take a list of (List LatexExpressions)
and compute a tupe consisting of a new list of (List LatexExpressins) and an updated
LatexSttate.

render : LatexState -> List (List LatexExpression) -> ( List String, LatexState )

-}
render :
    (LatexState -> List LatexExpression -> a)
    -> LatexState
    -> List (List LatexExpression)
    -> ( LatexState, List a )
render renderer latexState paragraphs =
    paragraphs
        |> List.foldl (renderReducer renderer) ( latexState, [] )


renderReducer :
    (LatexState -> List LatexExpression -> a)
    -> List LatexExpression
    -> ( LatexState, List a )
    -> ( LatexState, List a )
renderReducer renderer input ( state, outputList ) =
    let
        newState =
            latexStateReducer input state

        renderedInput =
            renderer newState input
    in
    ( newState, outputList ++ [ renderedInput ] )


{-| LatexState Reducer
-}
latexStateReducer : List LatexExpression -> LatexState -> LatexState
latexStateReducer parsedParagraph latexState =
    let
        theInfo =
            parsedParagraph
                |> List.head
                |> Maybe.map info
                |> Maybe.withDefault (LatexInfo "null" "null" [] [])
    in
    latexStateReducerDispatcher ( theInfo.typ, theInfo.name ) theInfo latexState


type alias LatexInfo =
    { typ : String, name : String, options : List LatexExpression, value : List LatexExpression }


info : LatexExpression -> LatexInfo
info latexExpression =
    case latexExpression of
        Macro name optArgs args ->
            { typ = "macro", name = name, options = optArgs, value = args }

        SMacro name optArgs args body ->
            { typ = "smacro", name = name, options = optArgs, value = args }

        Environment name args body ->
            { typ = "env", name = name, options = args, value = [ body ] }

        _ ->
            { typ = "null", name = "null", options = [], value = [] }


latexStateReducerDispatcher : ( String, String ) -> (LatexInfo -> LatexState -> LatexState)
latexStateReducerDispatcher ( typ_, name ) =
    case Dict.get ( typ_, name ) latexStateReducerDict of
        Just f ->
            f

        Nothing ->
            \latexInfo latexState -> latexState


latexStateReducerDict : Dict.Dict ( String, String ) (LatexInfo -> LatexState -> LatexState)
latexStateReducerDict =
    Dict.fromList
        [ ( ( "macro", "setcounter" ), \x y -> SRH.setSectionCounters x y )
        , ( ( "macro", "section" ), \x y -> SRH.updateSectionNumber x y )
        , ( ( "macro", "subsection" ), \x y -> SRH.updateSubsectionNumber x y )
        , ( ( "macro", "subsubsection" ), \x y -> SRH.updateSubsubsectionNumber x y )
        , ( ( "macro", "title" ), \x y -> SRH.setDictionaryItemForMacro x y )
        , ( ( "macro", "author" ), \x y -> SRH.setDictionaryItemForMacro x y )
        , ( ( "macro", "date" ), \x y -> SRH.setDictionaryItemForMacro x y )
        , ( ( "macro", "email" ), \x y -> SRH.setDictionaryItemForMacro x y )
        , ( ( "macro", "host" ), \x y -> SRH.setDictionaryItemForMacro x y )
        , ( ( "macro", "setclient" ), \x y -> SRH.setDictionaryItemForMacro x y )
        , ( ( "macro", "setdocid" ), \x y -> SRH.setDictionaryItemForMacro x y )
        , ( ( "macro", "revision" ), \x y -> SRH.setDictionaryItemForMacro x y )
        , ( ( "env", "theorem" ), \x y -> SRH.setTheoremNumber x y )
        , ( ( "env", "proposition" ), \x y -> SRH.setTheoremNumber x y )
        , ( ( "env", "lemma" ), \x y -> SRH.setTheoremNumber x y )
        , ( ( "env", "definition" ), \x y -> SRH.setTheoremNumber x y )
        , ( ( "env", "corollary" ), \x y -> SRH.setTheoremNumber x y )
        , ( ( "env", "equation" ), \x y -> SRH.setEquationNumber x y )
        , ( ( "env", "align" ), \x y -> SRH.setEquationNumber x y )
        , ( ( "smacro", "bibitem" ), \x y -> SRH.setBibItemXRef x y )
        ]
