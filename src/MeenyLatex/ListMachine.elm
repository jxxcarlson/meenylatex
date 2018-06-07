 
module ListMachine exposing(runMachine, InternalState)  

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
the `InternalState` of the machine holds a record
with fields `before`, `current`, and `after`.  The 
new output element is a function of these three
fields.

`ListMachine` exposes one function, `runMachine`,
and one type, `InternalState`.  To define a `ListMachine`,
it is enough to define an "output function" of type
`InternalState a -> b`.  In the example, below,
a ListMachine is defined with an output function that
sends the interenal state to `before + current + after`:

```
sumState : InternalState Int -> Int 
sumState internalState = 
  let
    a = internalState.before  |> Maybe.withDefault 0 
    b = internalState.current |> Maybe.withDefault 0 
    c = internalState.after   |> Maybe.withDefault 0 
  in  
    a + b + c
```

Given these definitins, one runs the machine like this:

```
runMachine sumState [0,1,2,3,4]
```

@docs runMachine, InternalState

See [Making Functional Machines with Elm](https://medium.com/@jxxcarlson/making-functional-machines-with-elm-c07700bba13c)

-}



-- TYPES
     
{-|

A `ListMachine` computes outputs by looking at its internal state
and applying the `nextInternalState` function. The internal 
state is initialized using `initialInternalState`.

-}
type alias InternalState a = {before: Maybe a, current: Maybe a, after: Maybe a, inputList: List a}

type alias MachineState a b = {internalstate: InternalState a, outputList: List b}

type alias Reducer a b = a -> MachineState a b -> MachineState a b


-- RUNNERS

run_ : Reducer a b -> MachineState a b -> List a -> MachineState a b
run_ reducer initialMachineState_ inputList = 
  List.foldl reducer initialMachineState_ inputList
  
 
run : Reducer a b -> List a -> List b
run reducer inputList = 
  let
    initialMachineState_ = initialMachineState inputList 
    finalState = run_ reducer initialMachineState_ inputList
  in
    List.reverse finalState.outputList  
 

{-|

`runMachine` opearates a `ListMachine`. Givcen an
output function of type `InternalState a -> b` and
an input list of type `List a`, it computes a
`List b`.

-} 
runMachine : (InternalState a -> b) -> List a -> List b 
runMachine outputFunction inputList = 
  run (makeReducer outputFunction) inputList 


-- INITIALIZERS
    
initialMachineState : List a -> MachineState a b
initialMachineState inputList = 
  {internalstate =  initialInternalState inputList, outputList = []}
  
initialInternalState : List a -> InternalState a
initialInternalState inputList = 
  {before = Nothing
   , current = List.head inputList 
   , after = List.head (List.drop 1 inputList)
   , inputList = inputList
   }
   

-- NEXT internalstate FUNCTION

nextInternalState : InternalState a -> InternalState a
nextInternalState internalState_ = 
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

makeReducer : (InternalState a -> b) -> Reducer a b
makeReducer computeOutput input machineState =
  let 
    nextInputList = List.drop 1 machineState.internalstate.inputList  
    nextInternalState_ = nextInternalState machineState.internalstate
    newOutput = computeOutput machineState.internalstate
    outputList = newOutput::machineState.outputList 
  in
    {internalstate = nextInternalState_, outputList = outputList}

  
