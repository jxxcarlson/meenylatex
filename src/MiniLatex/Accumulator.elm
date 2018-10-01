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



{- Types -}


{-| Given an initial state and list of inputs of type a,
produce a list of outputs of type b and a new state
-}
type alias Accumulator state a b =
    state -> List a -> ( List b, state )


type alias LatexInfo =
    { typ : String, name : String, options : List LatexExpression, value : List LatexExpression }


{-| parseParagraphs: Using a given LatexState, take a list of strings,
i.e., paragraphs, and compute a tuple consisting of the parsed
paragraphs and the upodated LatexState.

parseParagraphs : LatexState -> List String -> ( List (List LatexExpression), LatexState )

-}
parseParagraphs : Accumulator LatexState String (List LatexExpression)
parseParagraphs latexState paragraphs =
    paragraphs
        |> List.foldl parserReducer ( [], latexState )


parserReducer : String -> ( List (List LatexExpression), LatexState ) -> ( List (List LatexExpression), LatexState )
parserReducer inputList latexState =
    let
        ( outputList, state ) =
            latexState

        parsedInput =
            Parser.parse inputList

        newState =
            latexStateReducer parsedInput state
    in
    ( outputList ++ [ parsedInput ], newState )


{-| renderParagraphs: take a list of (List LatexExpressions)
and a LatexState and rehder the list into a list of strings.

renderParagraphs : LatexState -> List (List LatexExpression) -> ( List String, LatexState )

-}
renderParagraphs : (LatexState -> List LatexExpression -> a) -> Accumulator LatexState (List LatexExpression) a
renderParagraphs renderer latexState paragraphs =
    paragraphs
        |> List.foldl (renderReducer renderer) ( [], latexState )


renderReducer :
    (LatexState -> List LatexExpression -> a)
    -> List LatexExpression
    -> ( List a, LatexState )
    -> ( List a, LatexState )
renderReducer renderer input ( outputList, state ) =
    let
        newState =
            latexStateReducer input state

        renderedInput =
            renderer newState input
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



{- latexStateReducer -}


{-| Use a fold and a latexStateReducer to transform
a LatexState using a list of lists of LatexExpressions.
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
