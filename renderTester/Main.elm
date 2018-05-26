module Main exposing (main)

import Browser
import Html exposing (Html, text)
import Html.Attributes
import Json.Encode
import MeenyLatex.Render2 exposing (render)
import MeenyLatex.LatexState exposing (emptyLatexState)
import MeenyLatex.Parser exposing (LatexExpression(..))


-- https://19.ellie-app.com/khLv95pjTZa1


line str =
    Html.p [] [ text str ]


main =
    Browser.embed
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }


type alias Flags =
    {}


type alias Model =
    { message : String }


type Msg
    = NoOp


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { message = "start" }, Cmd.none )


update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )


example expr =
    Html.div [] [ render emptyLatexState expr ]


view model =
    Html.div []
        [ line <| "Rendering experiment"
        , example <| LXString "This is a string"
        , example <| Comment "This is a comment"
        , example <| InlineMath "a^2 + b^2 = c^2"
        , example <| DisplayMath "a^2 + b^2 = c^2"
        , example <| LatexList [ LXString "Well,", LXString "he", LXString "said to the lady", LXString ". Howdy!" ]
        , example <| LatexList [ LXString "He said", Macro "italic" [] ([ LatexList ([ LXString "Justice!" ]) ]) ]
        , example <| LatexList [ Macro "bozo" [] ([ arg1, arg2 ]) ]
        , example <| LatexList [ Macro "yada" [] ([ arg1, arg2 ]) ]
        ]


arg1 =
    LatexList ([ LXString "Foo" ])


arg2 =
    LatexList ([ LXString "Bar" ])


subscriptions model =
    Sub.none


mathText : String -> Html msg
mathText content =
    Html.node "math-text"
        [ Html.Attributes.property "content" (Json.Encode.string content) ]
        []
