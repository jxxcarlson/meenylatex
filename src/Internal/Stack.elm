module Internal.Stack exposing (Stack(..), depth, empty, isEmpty, pop, popElement, push, top)


type Stack a
    = Stack (List a)


empty : Stack a
empty =
    Stack []

{-|
     isEmpty empty
     --> True

     isEmpty (push 1 empty)
     --> False

-}
isEmpty : Stack a -> Bool
isEmpty (Stack list) =
    List.length list == 0

{-|

    depth empty
    --> 0

    depth (push 1 empty)
    --> 1

 -}
depth : Stack a -> Int
depth (Stack list) =
    List.length list


{-|

    st : Stack Int
    st = empty

    push 1 st |> popElement
    --> (empty, Just 1)

-}
push : a -> Stack a -> Stack a
push element (Stack list) =
    Stack (element :: list)


popElement : Stack a -> ( Stack a, Maybe a )
popElement (Stack list) =
    case List.tail list of
        Nothing ->
            ( Stack [], Nothing )

        Just tail ->
            ( Stack tail, List.head list )

{-|

   push 1 empty |> pop
   empty


-}
pop : Stack a -> Stack a
pop (Stack list) =
    case List.tail list of
        Nothing ->
            Stack []

        Just tail ->
            Stack tail

{-|
    top (push 1 empty)
    --> Just 1

-}
top : Stack a -> Maybe a
top (Stack list) =
    List.head list
