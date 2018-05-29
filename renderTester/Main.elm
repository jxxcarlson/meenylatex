module Main exposing (main)

import Browser
import Html exposing (Html, text)
import Html.Attributes
import Json.Encode
import MeenyLatex.Render2 exposing (render, renderString)
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
        , example <| LatexList [ Macro "ellie" [] ([ LatexList ([ LXString "krQCWKwv2Ta1" ]), LatexList ([ LXString "Ellie" ]) ]) ]
        , Html.iframe [ Html.Attributes.src "http://nytimes.com/embed" ] [ text "NYT" ]
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
