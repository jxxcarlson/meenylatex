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
    | Reset
    | Restore


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

        Reset ->
            ( { model
                | sourceText = Debug.log "Restore src" ""
                , editRecord = Debug.log "Reset" (MiniLatex.setup "")
              }
            , typeset "now"
            )

        Restore ->
            ( { model
                | sourceText = Debug.log "Restore src" initialSourceText
                , editRecord = Debug.log "Restore" (MiniLatex.setup initialSourceText)
              }
            , typeset "now"
            )

        GetContent str ->
            ( { model | sourceText = str }, Cmd.none )


view : Model -> Html Msg
view model =
    div []
        [ headerPanel
        , editor model
        , output model
        , spacer 5
        , infoPanel
        ]



{- VIEW FUNCTIONS -}


ribbonStyle color =
    style
        [ ( "width", "835px" )
        , ( "height", "20px" )
        , ( "margin-left", "20px" )
        , ( "margin-bottom", "-16px" )
        , ( "padding", "8px" )
        , ( "clear", "left" )
        , ( "background-color", color )
        , ( "color", "#eee" )
        ]


headerPanel =
    div
        [ ribbonStyle "#555" ]
        [ text "MiniLatex Demo" ]


infoPanel =
    div
        [ ribbonStyle "#777" ]
        [ text "^^^ You can scroll both the source and rendered text panes to see more text.    ^^^" ]


editor model =
    div [ style [ ( "float", "left" ) ] ]
        [ spacer 20
        , label "Source text"
        , spacer 5
        , editorPane model
        ]


output model =
    div [ style [ ( "float", "left" ) ] ]
        [ spacer 20
        , reRenderButton 0
        , resetButton 0
        , restoreButton 0
        , spacer 5
        , showRenderedSource model
        ]


reRenderButton offSet =
    button [ onClick ReRender, buttonStyle offSet ] [ text "Render" ]


fastRenderButton offSet =
    button [ onClick FastRender, buttonStyle offSet ] [ text "Fast render" ]


resetButton offSet =
    button [ onClick Reset, buttonStyle offSet ] [ text "Reset" ]


restoreButton offSet =
    button [ onClick Restore, buttonStyle offSet ] [ text "Restore" ]


spacer n =
    div [ style [ ( "height", toString n ++ "px" ), ( "clear", "left" ) ] ] []


label text_ =
    p [ labelStyle ] [ text text_ ]


editorPane model =
    textarea [ editorStyle, onInput GetContent, value model.sourceText ] [ text model.sourceText ]


showRenderedSource model =
    let
        renderedText =
            Debug.log "RT"
                (MiniLatex.getRenderedText model.editRecord)
    in
        div
            [ renderedSourceStyle
            , id "renderedText"
            , property "innerHTML" (Json.Encode.string renderedText)
            ]
            []



{- STYLE FUNCTIONS -}


buttonStyle : Int -> Html.Attribute msg
buttonStyle offSet =
    let
        realOffset =
            offSet + 20 |> toString |> \x -> x ++ "px"
    in
        style
            [ ( "backgroundColor", "rgb(100,100,200)" )
            , ( "color", "white" )
            , ( "width", "90px" )
            , ( "font-size", "10pt" )
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


initialSourceText =
    """
\\section{Introduction}

\\italic{This a MiniLatex test document.}
See the article
\\href{http://www.knode.io/#@public/445}{MiniLatex}
at \\href{http://www.knode.io}{www.knode.io} for more info.

\\section{Examples}

The Pythagorean Theorem, $a^2 + b^2 = c^2$,
is useful for computing distances.


Formula \\eqref{integral}
is one that you learned in Calculus class.

\\begin{equation}
\\label{integral}
\\int_0^1 x^n dx = \\frac{1}{n+1}
\\end{equation}

\\begin{theorem}
There are infinitely many primes, and
each satisfies $a^{p-1} \\equiv 1 \\text{ mod } p$, provided
that $p$ does not divide $a$.
\\end{theorem}

\\strong{Light Elements}
\\begin{tabular}{l l l l}
Hydrogen & H & 1 & 1.008 \\\\
Helium & He & 2 & 4.003 \\\\
Lithium & Li & 3 &  6.94 \\\\
Beryllium & Be & 4 & 9.012 \\\\
\\end{tabular}

\\image{http://psurl.s3.amazonaws.com/images/jc/propagator_t=2-6feb.png}{Free particle propagator}{width: 300, align: center}

\\section{Appendix}


\\begin{itemize}
%%
\\item \\href{https://hackernoon.com/towards-latex-in-the-browser-2ff4d94a0c08}{Towards LaTeX in the Browser}
%%
\\item \\href{https://github.com/jxxcarlson/minilatexDemo}{Code for the Demo App}
%%
\\item \\href{http://package.elm-lang.org/packages/jxxcarlson/minilatex/latest}{The MiniLatex Elm Library}
%%
\\end{itemize}

To try out MiniLatex for real, sign up for a free account at
 \\href{http://www.knode.io}{www.knode.io}.  The app is still
 in beta, and we need people to test it and give feedback.
Also, contributions to help improve the open-source
\\href{https://github.com/jxxcarlson/minilatex}{MiniLatex Parser-Renderer}
are most welcome.

Please send comments to jxxcarlson at gmail.
"""
