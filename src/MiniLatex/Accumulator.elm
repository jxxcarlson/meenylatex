module MiniLatex.Accumulator exposing (parse, render, info, 
  latexStateReducerDispatcher, latexStateReducer, latexStateReducer2, latexStateReducer3)

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
import MiniLatex.StateReducerHelpers2 as SRH2


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
renderReducer renderer listLatexExpression ( state, inputList ) =
    let
        newState =
            latexStateReducer3 listLatexExpression state

        renderedInput =
            renderer newState listLatexExpression
    in
    ( newState, inputList ++ [ renderedInput ] )


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
    (latexStateReducerDispatcher  theInfo) theInfo latexState

{-

> z = LatexList [Macro "title" [] [LatexList [LXString "foo"]],InlineMath ("x^2 = 1"),LXString (", "),Macro "strong" [] [LatexList [LXString "bar"]]]
LatexList [Macro "title" [] [LatexList [LXString "foo"]],InlineMath ("x^2 = 1"),LXString (", "),Macro "strong" [] [LatexList [LXString "bar"]]]
    : LatexExpression

> latexStateReducer2 z emptyLatexState
{ counters = Dict.fromList [("eqno",0),("s1",0),("s2",0),("s3",0),("tno",0)], crossReferences = Dict.fromList [], dictionary = Dict.fromList [("title","foo")], macroDictionary = Dict.fromList [], tableOfContents = [] }

-}

latexStateReducer3 : List LatexExpression -> LatexState -> LatexState 
latexStateReducer3 list state =
  List.foldr latexStateReducer2 state list

latexStateReducer2 : LatexExpression -> LatexState -> LatexState
latexStateReducer2 lexpr state = 
  case lexpr of 
    Macro name optionalArgs args -> 
       macroReducer name optionalArgs args state
    SMacro name optionalArgs args latexExpression -> 
       smacroReducer name optionalArgs args latexExpression state
    NewCommand name nArgs body ->
       SRH2.setMacroDefinition name body state
    Environment name optonalArgs body ->
       envReducer name optonalArgs body state
    LatexList list -> List.foldr latexStateReducer2 state list
    _ -> state

envReducer : String -> (List LatexExpression) -> LatexExpression -> LatexState -> LatexState
envReducer name optonalArgs body state = 
  if List.member name theoremWords then 
    SRH2.setTheoremNumber body state
  else  
  case name of 
    "equation" -> SRH2.setEquationNumber body state 
    "align" -> SRH2.setEquationNumber body state 
    _ -> state

{- 

> env3
LatexList [Macro "label" [] [LatexList [LXString "foo"]],LXString ("ho  ho  ho ")]
    : LatexExpression

> latexStateReducer2 env2 emptyLatexState
{ counters = Dict.fromList [("eqno",0),("s1",0),("s2",0),("s3",0),("tno",1)]
, crossReferences = Dict.fromList [("foo","0.1")], dictionary = Dict.fromList []
, macroDictionary = Dict.fromList [], tableOfContents = [] }

-}

theoremWords = ["theorem", "proposition", "corollary", "lemma", "definition"]   

dictionaryWords = ["title", "author", "data", "email",  "revision", "host", "setclient", "setdocid"]

macroReducer : String -> (List LatexExpression) -> (List LatexExpression)  -> LatexState -> LatexState 
macroReducer name optionalArgs args state =
  if List.member name dictionaryWords then 
    SRH2.setDictionaryItemForMacro name args state
  else
  case name of 
   "section" -> SRH2.updateSectionNumber args state
   "subsection" -> SRH2.updateSubsectionNumber args state
   "subsubsection" -> SRH2.updateSubsubsectionNumber args state
   "setcounter" -> SRH2.setSectionCounters args state
   _ -> state   

smacroReducer : String -> (List LatexExpression) -> (List LatexExpression)  -> LatexExpression -> LatexState -> LatexState 
smacroReducer name optionalArgs args latexExpression state =
  case name of 
   "bibitem" -> SRH2.setBibItemXRef optionalArgs args state
   _ -> state   

type alias LatexInfo =
    { typ : String, name : String, options : List LatexExpression, value : List LatexExpression }


info : LatexExpression -> LatexInfo
info latexExpression =
    case latexExpression of
        Macro name optArgs args ->
            { typ = "macro", name = name, options = optArgs, value = args }

        NewCommand name nArgs definition ->
            { typ = "newCommand", name = name, options = [], value = [definition] }

        SMacro name optArgs args body ->
            { typ = "smacro", name = name, options = optArgs, value = args }

        Environment name args body ->
            { typ = "env", name = name, options = args, value = [ body ] }

        _ ->
            { typ = "null", name = "null", options = [], value = [] }


latexStateReducerDispatcher : LatexInfo -> LatexInfo -> (LatexState -> LatexState)
latexStateReducerDispatcher theInfo =
    case Dict.get ( theInfo.typ, theInfo.name ) latexStateReducerDict of
        Just f ->
            f

        Nothing ->
           case theInfo.typ of 
             "newCommand" -> \latexInfo latexState -> SRH.setMacroDefinition theInfo latexState
             _ -> \latexInfo latexState -> latexState




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
