module Internal.Stack exposing (Stack(..), depth, empty, isEmpty, pop, popElement, push, top)


type Stack a
    = Stack (List a)


empty : Stack a
empty =
    Stack []


isEmpty : Stack a -> Bool
isEmpty (Stack list) =
    List.length list == 0


depth : Stack a -> Int
depth (Stack list) =
    List.length list


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


pop : Stack a -> Stack a
pop (Stack list) =
    case List.tail list of
        Nothing ->
            Stack []

        Just tail ->
            Stack tail


top : Stack a -> Maybe a
top (Stack list) =
    List.head list
