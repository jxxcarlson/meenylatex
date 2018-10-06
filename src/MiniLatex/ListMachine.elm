 
module MiniLatex.ListMachine exposing(runMachine, State)  

{-| 

A `ListMachine` takes as input a `List a` and produces
as output a `List b`.  Processing occurs as follows.
The machine reads the input list element by element
adding an element to the output list at each step.
Call the input element that is being read at the moment
the "current." Then one has the notions of the element
before the current one and after the current one.
We model these as values of type `Maybe a`, since
`Nothing` can occur, e.g., when the first element
of the input list is being read.  To be more precise,
the `State` of the machine holds a record
with fields `before`, `current`, and `after`.  The 
new output element is a function of these three
fields.

`ListMachine` exposes one function, `runMachine`,
and one type, `State`.  To define a `ListMachine`,
it is enough to define an "output function" of type
`State a -> b`.  In the example, below,
a ListMachine is defined with an output function that
sends the interenal state to `before + current + after`:

```
sumState : State Int -> Int 
sumState internalState = 
  let
    a = internalState.before  |> Maybe.withDefault 0 
    b = internalState.current |> Maybe.withDefault 0 
    c = internalState.after   |> Maybe.withDefault 0 
  in  
    a + b + c
```

Given these definitions, one runs the machine like this:

```
runMachine sumState [0,1,2,3,4]
```

@docs runMachine, State

See [Making Functional Machines with Elm](https://medium.com/@jxxcarlson/making-functional-machines-with-elm-c07700bba13c)

-}



-- TYPES
     
{-|

A `ListMachine` computes outputs by looking at its internal state
and applying the `nextState` function. The internal 
state is initialized using `initialState`.

-}
type alias State a = {before: Maybe a, current: Maybe a, after: Maybe a, inputList: List a}

type alias TotalState a b = {state: State a, outputList: List b}

type alias Reducer a b = a -> TotalState a b -> TotalState a b


-- RUNNERS

{-|
`runMachine` operates a `ListMachine`. Given an
output function of type `State a -> b` and
an input list of type `List a`, it computes a `List b`.
-} 
runMachine : (State a -> b) -> List a -> List b 
runMachine outputFunction inputList = 
  run (makeReducer outputFunction) inputList 
  

run : Reducer a b -> List a -> List b
run reducer inputList =
  let
    initialTotalState_ = initialTotalState inputList
    finalTotalState = (makeAccumulator reducer) initialTotalState_ inputList
  in
    List.reverse finalTotalState.outputList


makeAccumulator : Reducer a b -> TotalState a b -> List a -> TotalState a b
makeAccumulator reducer initialMachineState_ inputList = 
  List.foldl reducer initialMachineState_ inputList
  


-- INITIALIZERS
    
initialTotalState : List a -> TotalState a b
initialTotalState inputList = 
  {state =  initialState inputList, outputList = []}
  
initialState : List a -> State a
initialState inputList = 
  {before = Nothing
   , current = List.head inputList 
   , after = List.head (List.drop 1 inputList)
   , inputList = inputList
   }
   

-- NEXT state FUNCTION

nextState : State a -> State a
nextState internalState_ = 
  let 
     nextInputList_ = List.drop 1 internalState_.inputList
  in
  {  
    before = internalState_.current
   , current = internalState_.after 
   , after = List.head (List.drop 1 nextInputList_)
   , inputList = nextInputList_
  }


-- A REDUCER MAKER

makeReducer : (State a -> b) -> Reducer a b
makeReducer computeOutput input machineState =
  let 
    nextInputList = List.drop 1 machineState.state.inputList  
    nextInternalState_ = nextState machineState.state
    newOutput = computeOutput machineState.state
    outputList = newOutput::machineState.outputList 
  in
    {state = nextInternalState_, outputList = outputList}

  
