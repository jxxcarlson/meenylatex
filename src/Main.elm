port module Main exposing (..)

{-| Test app for MiniLatex
-}

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Keyed as Keyed
import Json.Encode as Encode
import MiniLatex.Driver as MiniLatex
import MiniLatex.Differ exposing (EditRecord)
import MiniLatex.Parser exposing (LatexExpression)
import Random


main =
    Html.program { view = view, update = update, init = init, subscriptions = subscriptions }


type alias Model =
    { sourceText : String, parseResult : List (List LatexExpression), editRecord : EditRecord, seed : Int }


init : ( Model, Cmd Msg )
init =
    let
        model =
            { sourceText = initialSourceText
            , editRecord = MiniLatex.setup 0 initialSourceText
            , parseResult = MiniLatex.parse initialSourceText
            , seed = 0
            }
    in
        ( model, Random.generate NewSeed (Random.int 1 10000) )


type Msg
    = FastRender
    | GetContent String
    | ReRender
    | Reset
    | Restore
    | GenerateSeed
    | NewSeed Int


port sendToJs : Encode.Value -> Cmd msg


encodeData mode idList =
    let
        idValueList =
            Debug.log "idValueList"
                (List.map Encode.string idList)
    in
        [ ( "mode", Encode.string mode )
        , ( "idList", Encode.list idValueList )
        ]
            |> Encode.object


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FastRender ->
            let
                newEditRecord =
                    MiniLatex.update model.seed model.editRecord model.sourceText
            in
                ( { model
                    | editRecord = newEditRecord
                    , parseResult = MiniLatex.parse model.sourceText
                  }
                , Cmd.batch
                    [ sendToJs <| encodeData "fast" newEditRecord.idList
                    , Random.generate NewSeed (Random.int 1 10000)
                    ]
                )

        ReRender ->
            ( { model
                | editRecord = MiniLatex.setup model.seed model.sourceText
                , parseResult = MiniLatex.parse model.sourceText
              }
            , sendToJs <| encodeData "full" []
            )

        Reset ->
            ( { model
                | sourceText = ""
                , editRecord = MiniLatex.setup model.seed ""
              }
            , sendToJs <| encodeData "full" []
            )

        Restore ->
            ( { model
                | sourceText = initialSourceText
                , editRecord = MiniLatex.setup model.seed initialSourceText
              }
            , sendToJs <| encodeData "full" []
            )

        GetContent str ->
            ( { model | sourceText = str }, Cmd.none )

        GenerateSeed ->
            ( model, Random.generate NewSeed (Random.int 1 10000) )

        NewSeed newSeed ->
            ( { model | seed = newSeed }, Cmd.none )


view : Model -> Html Msg
view model =
    div [ style [ ( "width", "1350px" ), ( "margin", "auto" ) ] ]
        [ mainView model
        ]


mainView model =
    div []
        [ headerRibbon
        , editor model
        , renderedSource model
        , showParseResult model
        , spacer 5
        , footerRibbon
        ]



{- VIEW FUNCTIONS -}


headerRibbon =
    div
        [ ribbonStyle "#555" ]
        [ span [ style [ ( "margin-left", "5px" ) ] ] [ text "MiniLatex Demo" ]
        , link "http://www.knode.io" "www.knode.io"
        ]


link url linkText =
    a
        [ class "linkback"
        , style
            [ ( "float", "right" )
            , ( "margin-right", "10px" )
            ]
        , href url
        , target "_blank"
        ]
        [ text linkText ]


footerRibbon =
    div
        [ ribbonStyle "#777" ]
        [ text "Fast render updates only those paragraphs which have changed."
        , link "http://jxxcarlson.github.io" "jxxcarlson.github.io"
        ]


editor model =
    div [ style [ ( "float", "left" ) ] ]
        [ spacer 20
        , buttonBarLeft
        , spacer 5
        , editorPane model
        ]


editorPane model =
    textarea [ editorStyle, onInput GetContent, value model.sourceText ] [ text model.sourceText ]


renderedSource model =
    div [ style [ ( "float", "left" ) ] ]
        [ spacer 20
        , buttonBarRight
        , spacer 5
        , renderedSourcePane model
        ]


showParseResult model =
    div [ style [ ( "float", "left" ) ] ]
        [ spacer 20
        , buttonBarBlank
        , spacer 5
        , parseResultPane model
        ]


parseResultPane model =
    div
        [ renderedSourceStyle ]
        [ text (toString model.parseResult) ]


renderedSourcePane model =
    let
        renderedText =
            MiniLatex.getRenderedText "" model.editRecord
    in
        div
            [ renderedSourceStyle
            , id "renderedText"
            , property "innerHTML" (Encode.string (Debug.log "RT" renderedText))
            ]
            []



{- Buttons -}


buttonBarLeft =
    div
        [ style [ ( "margin-left", "20px" ) ] ]
        [ resetButton 0
        , restoreButton 0
        ]


buttonBarRight =
    div
        [ style [ ( "margin-left", "20px" ) ] ]
        [ reRenderButton 0
        , fastRenderButton 0
        ]


buttonBarBlank =
    div
        [ style [ ( "margin-left", "20px" ), ( "margin-top", "25px" ) ] ]
        []


reRenderButton offSet =
    button [ onClick ReRender, buttonStyle offSet ] [ text "Render" ]


fastRenderButton offSet =
    button [ onClick FastRender, buttonStyle offSet ] [ text "Fast Render" ]


resetButton offSet =
    button [ onClick Reset, buttonStyle offSet ] [ text "Reset" ]


restoreButton offSet =
    button [ onClick Restore, buttonStyle offSet ] [ text "Restore" ]



{- Elements -}


spacer n =
    div [ style [ ( "height", toString n ++ "px" ), ( "clear", "left" ) ] ] []


label text_ =
    p [ labelStyle ] [ text text_ ]



{- STYLE FUNCTIONS -}


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


buttonStyle : Int -> Html.Attribute msg
buttonStyle offSet =
    let
        realOffset =
            offSet + 0 |> toString |> \x -> x ++ "px"
    in
        style
            [ ( "backgroundColor", "rgb(100,100,200)" )
            , ( "color", "white" )
            , ( "width", "85px" )
            , ( "height", "25px" )
            , ( "margin-left", realOffset )
            , ( "margin-right", "8px" )
            , ( "font-size", "9pt" )
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

Feel free to edit and re-render the text on the left.

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

Articles and code:

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
 under development &mdash;  we need people to test it and give feedback.
Also, contributions to help improve the open-source
MiniLatex Parser-Renderer are most welcome.
Here is the \\href{https://github.com/jxxcarlson/minilatex}{GitHub repository}.
The MiniLatex Demo as well as the app at knode.io are written in
\\href{http://elm-lang.org/}{Elm}.

Please send comments to jxxcarlson at gmail.
"""
