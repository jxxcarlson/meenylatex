module MiniLatex.Accumulator exposing
    ( parseParagraphs
    , parserReducerTransformer
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



{- Types -}


{-| Given an initial state and list of inputs of type a,
produce a list of outputs of type b and a new state
-}
type alias Accumulator state a b =
    state -> List a -> ( List b, state )


{-| A reducer (a -> b -> b) is used by foldl : (a -> b -> b) -> b -> List a -> b
to produce a new b from an initial b and a list of a's .
-}
type alias Reducer a b =
    a -> b -> b


{-| A ParserReducer is used to produce a new LatexState from an initial LatexState
given a list of lists of LatexExpressions.
-}
type alias ParserReducer =
    Reducer (List LatexExpression) LatexState


{-| A RenderReducer is used to produce a new (List String, LatexState)
from an initial (List String, LatexState and a list of lists of LatexExpressions
-}
type alias RenderReducer =
    Reducer (List LatexExpression) ( List String, LatexState )


{-| Transform a reducer using (a -> b)

Start with a Reducer that transforms c using
a list of b's . Make a new Reducer that
transforms values of type (List b, c) using a list
of a's

-}
type alias ParserReducerTransformer a b c =
    (a -> b)
    -> Reducer b c
    -> Reducer a ( List b, c )


{-| Transform a reducer using (a -> b -> c)
-}
type alias RenderReducerTransformer a b c =
    (a -> b -> c)
    -> Reducer b a
    -> Reducer b ( List c, a )


type alias LatexInfo =
    { typ : String, name : String, options : List LatexExpression, value : List LatexExpression }



{- EXPORTED FUNCTIONS -}
-- transformParagraphs : LatexState -> List String -> ( List String, LatexState )
-- transformParagraphs latexState paragraphs =
--     paragraphs
--         |> accumulator Parser.parse renderParagraph latexStateReducer latexState
--
--
-- renderParagraphs : List LatexExpression -> LatexState -> String
-- renderParagraphs parsedParagraph latexState =
--     renderLatexList latexState parsedParagraph
--         |> \paragraph -> "<p>" ++ paragraph ++ "</p>"


{-| parseParagraphs: Using a given LatexState, take a list of strings,
i.e., paragraphs, and compute a tuple consisting of the parsed
paragraphs and the upodated LatexState.

parseParagraphs : LatexState -> List String -> ( List (List LatexExpression), LatexState )

-}
parseParagraphs : Accumulator LatexState String (List LatexExpression)
parseParagraphs latexState paragraphs =
    paragraphs
        |> List.foldl parserAccumulatorReducer ( [], latexState )


parserAccumulatorReducer : Reducer String ( List (List LatexExpression), LatexState )
parserAccumulatorReducer =
    parserReducerTransformer Parser.parse latexStateReducer


{-| renderParagraphs: take a list of (List LatexExpressions)
and a LatexState and rehder the list into a list of strings.

renderParagraphs : LatexState -> List (List LatexExpression) -> ( List String, LatexState )

-}
renderParagraphs : (LatexState -> List LatexExpression -> a) -> Accumulator LatexState (List LatexExpression) a
renderParagraphs renderer latexState paragraphs =
    paragraphs
        |> List.foldl (renderAccumulatorReducer renderer) ( [], latexState )


renderAccumulatorReducer : (LatexState -> List LatexExpression -> a) -> Reducer (List LatexExpression) ( List a, LatexState )
renderAccumulatorReducer renderer =
    renderTransformer renderer latexStateReducer



{- ACCUMULATORS AND TRANSFORMERS -}


{-| parserReducerTransformer parse latexStateReducer is a Reducer input acc
-}
parserReducerTransformer : ParserReducerTransformer String (List LatexExpression) LatexState
parserReducerTransformer parse latexStateReducer_ input acc =
    let
        ( outputList, state ) =
            acc

        parsedInput =
            parse input

        newState =
            latexStateReducer_ parsedInput state
    in
    ( outputList ++ [ parsedInput ], newState )


{-| renderTransformer render latexStateReducer is a Reducer input acc
-}
renderTransformer : RenderReducerTransformer LatexState (List LatexExpression) a
renderTransformer render latexStateReducer_ input acc =
    let
        ( outputList, state ) =
            acc

        newState =
            latexStateReducer_ input state

        renderedInput =
            render newState input
    in
    ( outputList ++ [ renderedInput ], newState )


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



{- UPDATERS -}


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


latexStateReducerDispatcher : ( String, String ) -> (LatexInfo -> LatexState -> LatexState)
latexStateReducerDispatcher ( typ_, name ) =
    case Dict.get ( typ_, name ) latexStateReducerDict of
        Just f ->
            f

        Nothing ->
            \latexInfo latexState -> latexState


{-| Use a fold and a latexStateReducer to transform
a LatexState using a list of lists of LatexExpressions.
-}
latexStateReducer : Reducer (List LatexExpression) LatexState
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



{-

   |> Maybe.withDefault (LatexInfo "null" "null" [ Macro "null" [] [] ])

-}
