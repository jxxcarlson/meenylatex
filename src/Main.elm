port module Main exposing (..)

{-| Test app for MiniLatex
-}

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Keyed as Keyed
import Json.Encode
import MiniLatex.Driver as MiniLatex
import MiniLatex.Differ exposing (EditRecord)


main =
    Html.program { view = view, update = update, init = init, subscriptions = subscriptions }


type alias Model =
    { sourceText : String, editRecord : EditRecord }


init : ( Model, Cmd Msg )
init =
    let
        initialSourceText =
            initialSourceText2

        model =
            { sourceText = initialSourceText
            , editRecord = MiniLatex.setup initialSourceText
            }
    in
        ( model, Cmd.none )


type Msg
    = FastRender
    | GetContent String
    | ReRender


port typeset : String -> Cmd msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        FastRender ->
            ( { model
                | editRecord = MiniLatex.update model.editRecord model.sourceText
              }
            , typeset "now"
            )

        ReRender ->
            ( { model
                | editRecord = MiniLatex.setup model.sourceText
              }
            , typeset "now"
            )

        GetContent str ->
            ( { model | sourceText = str }, Cmd.none )


view : Model -> Html Msg
view model =
    div []
        [ editor model
        , output model
        ]



{- VIEW FUNCTIONS -}


editor model =
    div [ style [ ( "float", "left" ) ] ]
        [ spacer 20
        , label "Source text"
        , editorPane model
        ]


output model =
    div [ style [ ( "float", "left" ) ] ]
        [ spacer 20
        , fastRenderButton 0
        , reRenderButton 0
        , showRenderedSource model
        ]


reRenderButton offSet =
    button [ onClick ReRender, buttonStyle offSet ] [ text "Render again" ]


fastRenderButton offSet =
    button [ onClick FastRender, buttonStyle offSet ] [ text "Fast render" ]


spacer n =
    div [ style [ ( "height", toString n ++ "px" ) ] ] []


label text_ =
    p [ labelStyle ] [ text text_ ]


editorPane model =
    textarea [ editorStyle, onInput GetContent ] [ text model.sourceText ]


showRenderedSource model =
    let
        renderedText =
            Debug.log "RT"
                (MiniLatex.getRenderedText model.editRecord)
    in
        div
            [ renderedSourceStyle
            , property "innerHTML" (Json.Encode.string renderedText)
            ]
            []


counterAsString model =
    toString model.counter



{- STYLE FUNCTIONS -}


buttonStyle : Int -> Html.Attribute msg
buttonStyle offSet =
    let
        realOffset =
            offSet + 20 |> toString |> \x -> x ++ "px"
    in
        style
            [ ( "backgroundColor", "rgb(100,100,100)" )
            , ( "color", "white" )
            , ( "width", "100px" )
            , ( "height", "25px" )
            , ( "margin-left", realOffset )
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


editorStyle =
    textStyle "400px" "635px" "20px" "#eef"


renderedSourceStyle =
    textStyle "400px" "600px" "20px" "#eee"


textStyle width height offset color =
    style
        [ ( "width", width )
        , ( "height", height )
        , ( "padding", "15px" )
        , ( "margin-left", offset )
        , ( "background-color", color )
        , ( "overflow", "scroll" )
        ]



{- Examples -}


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
\\tag{B}\\label{C}
\\int_0^1 x^n dx = \\frac{1}{n+1}
$$

\\begin{theorem}
There are infinitely many primes, and
each satisfies $a^{p-1} \\equiv 1 \\text{ mod } p$, provided
that $p$ does not divide $a$.
\\end{theorem}
"""


initialSourceText3 =
    """
\\begin{equation}
\\label{integral}
\\int_0^1 x^n dx = \\frac{1}{n+1}
\\end{equation}
"""
