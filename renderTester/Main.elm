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
        , example <| LXString "This is a string"
        , example <| Comment "This is a comment"
        , example <| InlineMath "a^2 + b^2 = c^2"
        , example <| DisplayMath "a^2 + b^2 = c^2"
        , example <| LatexList [ LXString "Well,", LXString "he", LXString "said to the lady", LXString ". Howdy!" ]
        , example <| LatexList [ Macro "bozo" [] ([ arg1, arg2 ]) ]
        , example <| LatexList [ Macro "yada" [] ([ arg1, arg2 ]) ]
        , example <| LatexList [ LXString "He cried", Macro "italic" [] ([ LatexList ([ LXString "Justice!" ]) ]) ]
        , example <| LatexList [ LXString "He cried", Macro "strong" [] ([ LatexList ([ LXString "Justice!" ]) ]) ]
        , example <| LatexList [ LXString "one", Macro "bigskip" [] [], LXString "two" ]
        , example <| LatexList [ Macro "cite" [] ([ LatexList ([ LXString "Foo" ]) ]) ]
        , example <| LatexList [ LXString "Use", Macro "code" [] ([ LatexList ([ LXString "return x" ]) ]), LXString "." ]
        , example <| LatexList [ Macro "href" [] ([ LatexList ([ LXString "https://ellie-app.com/krQCWKwv2Ta1" ]), LatexList ([ LXString "Ellie" ]) ]) ]
        , example <| LatexList [ Macro "image" [] ([ LatexList ([ LXString "http://cooldigital.photography/wp-content/uploads/2015/09/Rosy-Butterfly-620x412.jpg" ]), LatexList ([ LXString "Butterfly" ]), LatexList ([ LXString "width: 300, float: left" ]) ]) ]
        , example <| LatexList [ Macro "index" [] ([ LatexList ([ LXString "foo" ]) ]) ]
        , example <| LatexList [ Macro "ellie" [] ([ LatexList ([ LXString "krQCWKwv2Ta1" ]), LatexList ([ LXString "Ellie" ]) ]) ]
        , renderString emptyLatexState "He said that \\strong{it is true!}"
        , renderString emptyLatexState "He said that \\italic{it is true!}"
        , renderString emptyLatexState "\\begin{equation}\n \\int_0^1 x^n dx = \\frac{1}{n+1}\n\\end{equation}\n"
        , renderString emptyLatexState "\\begin{theorem}This is a test.\\end{theorem}\n"
        , example <| LatexList [ Environment "equation" [] (LXString "\n  \\int_0^1 x^n dx = \\frac{1}{n+1}\n  ") ]
        , line (Debug.toString <| MeenyLatex.Parser.parse "\\begin{equation}\n \\int_0^1 x^n dx = \\frac{1}{n+1}\n\\end{equation}\n")
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
