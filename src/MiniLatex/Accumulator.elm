module MiniLatex.Accumulator exposing
    ( parseParagraphs
    , renderParagraphs
    )

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
import MiniLatex.Parser as Parser exposing (LatexExpression(..), macro, parse)
import MiniLatex.Render2 as Render exposing (renderLatexList)
import MiniLatex.StateReducerHelpers as SRH


{-| Given an initial state and list of inputs of type a,
produce a list of outputs of type b and a new state
-}
type alias Accumulator state a b =
    state -> List a -> ( List b, state )


type alias Reducer a b =
    a -> b -> b


{-| parseParagraphs: Using a given LatexState, take a list of strings,
i.e., paragraphs, and compute a tuple consisting of the parsed
paragraphs and ad upodated LatexState.

parseParagraphs : LatexState -> List String -> ( List (List LatexExpression), LatexState )

-}
parseParagraphs :
    LatexState
    -> List String
    -> ( List (List LatexExpression), LatexState )
parseParagraphs latexState paragraphs =
    paragraphs
        |> List.foldl parserParagraphsReducer ( [], latexState )


parserParagraphsReducer :
    String
    -> ( List (List LatexExpression), LatexState )
    -> ( List (List LatexExpression), LatexState )
parserParagraphsReducer str ( inputList, state ) =
    let
        parsedInput =
            Parser.parse str

        newState =
            latexStateReducer parsedInput state
    in
    ( inputList ++ [ parsedInput ], newState )


{-| renderParagraphs: Using a given LatexState, take a list of (List LatexExpressions)
and compute a tupe consisting of a new list of (List LatexExpressins) and an updated
LatexSttate.

renderParagraphs : LatexState -> List (List LatexExpression) -> ( List String, LatexState )

-}
renderParagraphs :
    (LatexState -> List LatexExpression -> a)
    -> LatexState
    -> List (List LatexExpression)
    -> ( List a, LatexState )
renderParagraphs renderer latexState paragraphs =
    paragraphs
        |> List.foldl (renderParagraphsReducer renderer) ( [], latexState )


renderParagraphsReducer :
    (LatexState -> List LatexExpression -> a)
    -> List LatexExpression
    -> ( List a, LatexState )
    -> ( List a, LatexState )
renderParagraphsReducer renderer input ( outputList, state ) =
    let
        newState =
            latexStateReducer input state

        renderedInput =
            renderer newState input
    in
    ( outputList ++ [ renderedInput ], newState )


{-| LatexState Reducer
-}
latexStateReducer : List LatexExpression -> LatexState -> LatexState
latexStateReducer parsedParagraph latexState =
    let
        headElement =
            parsedParagraph
                |> List.head
                |> Maybe.map info
                |> Maybe.withDefault (LatexInfo "null" "null" [] [])

        he =
            { typ = "macro", name = "setcounter", value = [ LatexList [ LXString "section" ], LatexList [ LXString "7" ] ] }
    in
    latexStateReducerDispatcher ( headElement.typ, headElement.name ) headElement latexState


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
