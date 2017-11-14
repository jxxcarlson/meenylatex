port module Main exposing (..)

{-| Test app for MiniLatex
-}

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Keyed as Keyed
import Json.Encode
import MiniLatex.Driver as MiniLatex


main =
    Html.program { view = view, update = update, init = init, subscriptions = subscriptions }


type alias Model =
    { sourceText : String, renderedText : String, counter : Int }


init : ( Model, Cmd Msg )
init =
    let
        initialSourceText =
            initialSourceText2

        model =
            { sourceText = initialSourceText
            , renderedText = Debug.log "Render (1)" (MiniLatex.render initialSourceText)
            , counter = 0
            }
    in
        ( model, Cmd.none )


type Msg
    = Render
    | GetContent String


port typeset : String -> Cmd msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        Render ->
            ( { model
                | renderedText = Debug.log "Rendered (2)" (MiniLatex.render model.sourceText)
                , counter = model.counter + 1
              }
            , typeset "now"
            )

        GetContent str ->
            ( { model | sourceText = str }, Cmd.none )


view : Model -> Html Msg
view model =
    div []
        [ spacer 20
        , label "Source text"
        , editor model
        , spacer 20
        , button [ onClick Render, buttonStyle ] [ text "Render" ]
        , showRenderedSource model
        ]


initialSourceText1 =
    "This \\strong{is} a test!\n\n$$\n\\int_0^1 x^n dx = \\frac{1}{n+1}\n$$"


initialSourceText2 =
    """
\\section{Introduction}

This \\strong{is} a test.  Here is the
Pythagorean Theorem: $a^2 + b^2 = c^2$.


Formula \\eqref{integral}
is one that you learned in Calculus class.

\\begin{equation}
\\label{integral}
\\int_0^1 x^n dx = \\frac{1}{n+1}
\\end{equation}

\\begin{equation}
\\int_0^1 x^n dx = \\frac{1}{n+1}
\\end{equation}


$$
\\tag{2}
\\int_0^1 x^n dx = \\frac{1}{n+1}
$$

\\begin{theorem}
There are infinitely many primes, and
each satisfies $a^{p-1} \\equiv 1 \\text{ mod } p$, provided
that $p$ does not divide $a$.
\\end{theorem}

$$
  \\int_0^a x^n dx = \\frac{a^{n+1}}{n+1}
$$
"""


initialSourceText3 =
    """
\\begin{equation}
\\label{integral}
\\int_0^1 x^n dx = \\frac{1}{n+1}
\\end{equation}
"""



{- VIEW FUNCTIONS -}


spacer n =
    div [ style [ ( "height", toString n ++ "px" ) ] ] []


label text_ =
    p [ labelStyle ] [ text text_ ]


editor model =
    textarea [ myTextStyle "#eef", onInput GetContent ] [ text model.sourceText ]


showSource model =
    div
        [ myTextStyle "#efe" ]
        [ text model.sourceText ]


showRenderedSource model =
    div
        [ myTextStyle "#eee"
        , property "innerHTML" (Json.Encode.string model.renderedText)
        ]
        []


showRenderedSourceRaw model =
    div
        [ myTextStyle "#eee" ]
        [ text model.renderedText ]


showRenderedSourceX model =
    Keyed.node "div"
        [ myTextStyle "#eee"
        , property "innerHTML" (Json.Encode.string model.renderedText)
        ]
        [ ( counterAsString model, text "" ) ]


counterAsString model =
    toString model.counter



{- STYLE FUNCTIONS -}


buttonStyle : Html.Attribute msg
buttonStyle =
    style
        [ ( "backgroundColor", "rgb(100,100,100)" )
        , ( "color", "white" )
        , ( "width", "100px" )
        , ( "height", "25px" )
        , ( "margin-left", "20px" )
        , ( "font-size", "12pt" )
        , ( "text-align", "center" )
        , ( "border", "none" )
        ]


labelStyle =
    style
        [ ( "margin-top", "5px" )
        , ( "margin-bottom", "0px" )
        , ( "margin-left", "20px" )
        , ( "font-style", "bold" )
        ]


myTextStyle =
    textStyle "400px" "250px"


textStyle width height color =
    style
        [ ( "width", width )
        , ( "height", height )
        , ( "padding", "15px" )
        , ( "margin-left", "20px" )
        , ( "background-color", color )
        , ( "overflow", "scroll" )
        ]
