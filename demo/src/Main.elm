module Main exposing (main)

import Browser
import Debounce exposing (Debounce)
import Html exposing (..)
import Html.Attributes as HA exposing (..)
import Html.Events exposing (onClick, onInput)
import MiniLatex
import MiniLatex.Edit exposing (Data)
import MiniLatex.Render exposing (MathJaxRenderOption(..))
import Random
import StringsV1
import StringsV2
import Style exposing (..)
import Task


initialText =
    StringsV2.initialText


main : Program Flags (Model (Html Msg)) Msg
main =
    Browser.element
        { view = view
        , update = update
        , init = init
        , subscriptions = subscriptions
        }


type alias Model a =
    { sourceText : String
    , renderedText : a
    , macroText : String
    , editRecord : Data a
    , debounce : Debounce String
    , counter : Int
    , seed : Int
    }


type Msg
    = Clear
    | Render String
    | GetContent String
    | GetMacroText String
    | DebounceMsg Debounce.Msg
    | GenerateSeed
    | NewSeed Int
    | FullRender
    | RestoreText
    | ExampleText


debounceConfig : Debounce.Config Msg
debounceConfig =
    { strategy = Debounce.later 250
    , transform = DebounceMsg
    }


type alias Flags =
    { seed : Int
    , width : Int
    , height : Int
    }


init : Flags -> ( Model (Html msg), Cmd Msg )
init flags =
    let
        editRecord =
            MiniLatex.Edit.init NoDelay flags.seed initialText

        --            MiniLatex.Edit.init NoDelay model.seed (prependMacros initialMacroText initialText)
        model =
            { sourceText = initialText
            , macroText = initialMacroText
            , renderedText = render (prependMacros initialMacroText initialText)
            , editRecord = editRecord
            , debounce = Debounce.init
            , counter = 0
            , seed = flags.seed
            }
    in
    ( model, Cmd.none )


initialMacroText =
    normalize StringsV1.macros


subscriptions : Model (Html msg) -> Sub Msg
subscriptions model =
    Sub.none


update : Msg -> Model (Html msg) -> ( Model (Html msg), Cmd Msg )
update msg model =
    case msg of
        GetContent str ->
            let
                ( debounce, cmd ) =
                    Debounce.push debounceConfig str model.debounce
            in
            ( { model
                | sourceText = str
                , debounce = debounce
              }
            , cmd
            )

        GetMacroText str ->
            ( { model | macroText = str }, Cmd.none )

        DebounceMsg msg_ ->
            let
                ( debounce, cmd ) =
                    Debounce.update
                        debounceConfig
                        (Debounce.takeLast render_)
                        msg_
                        model.debounce
            in
            ( { model | debounce = debounce }, cmd )

        Render str ->
            let
                n =
                    String.fromInt model.counter

                newEditRecord =
                    MiniLatex.Edit.update NoDelay model.seed (prependMacros model.macroText str) model.editRecord
            in
            ( { model
                | editRecord = newEditRecord
                , renderedText = renderFromEditRecord model.counter newEditRecord
                , counter = model.counter + 2
              }
            , Random.generate NewSeed (Random.int 1 10000)
            )

        GenerateSeed ->
            ( model, Random.generate NewSeed (Random.int 1 10000) )

        NewSeed newSeed ->
            ( { model | seed = newSeed }, Cmd.none )

        Clear ->
            let
                editRecord =
                    MiniLatex.Edit.init NoDelay 0 ""
            in
            ( { model
                | sourceText = ""
                , editRecord = editRecord
                , renderedText = renderFromEditRecord model.counter editRecord
                , counter = model.counter + 1
              }
            , Cmd.none
            )

        FullRender ->
            let
                editRecord =
                    MiniLatex.Edit.init NoDelay model.seed (prependMacros model.macroText model.sourceText)
            in
            ( { model
                | counter = model.counter + 1
                , editRecord = editRecord
                , renderedText = renderFromEditRecord model.counter editRecord
              }
            , Cmd.none
            )

        RestoreText ->
            let
                editRecord =
                    MiniLatex.Edit.init NoDelay model.seed (prependMacros initialMacroText initialText)
            in
            ( { model
                | counter = model.counter + 1
                , editRecord = editRecord
                , sourceText = initialText
                , renderedText = renderFromEditRecord model.counter editRecord
              }
            , Cmd.none
            )

        ExampleText ->
            let
                editRecord =
                    MiniLatex.Edit.init Delay model.seed (prependMacros initialMacroText StringsV1.mathExampleText)
            in
            ( { model
                | counter = model.counter + 1
                , editRecord = editRecord
                , sourceText = StringsV1.mathExampleText
                , renderedText = renderFromEditRecord model.counter editRecord
              }
            , Cmd.none
            )


normalize : String -> String
normalize str =
    str |> String.lines |> List.filter (\x -> x /= "") |> String.join "\n"


prependMacros : String -> String -> String
prependMacros macros_ sourceText =
    "$$\n" ++ (macros_ |> normalize) ++ "\n$$\n\n" ++ sourceText


renderFromEditRecord : Int -> Data (Html msg) -> Html msg
renderFromEditRecord counter editRecord =
    MiniLatex.Edit.get editRecord
        |> List.map (\x -> Html.div [ HA.style "margin-bottom" "0.65em" ] [ x ])
        |> Html.div []


render_ : String -> Cmd Msg
render_ str =
    Task.perform Render (Task.succeed str)


render : String -> Html msg
render sourceText =
    let
        macroDefinitions =
            initialMacroText
    in
    MiniLatex.render NoDelay macroDefinitions sourceText



--
-- VIEW FUNCTIONS
---


view : Model (Html Msg) -> Html Msg
view model =
    div (outerStyle ++ [ HA.class "container" ])
        [ lhs model
        , renderedSource model
        ]


lhs model =
    div [ HA.class "lhs" ]
        [ h1 [ style "margin-left" "20px" ] [ text "MiniLatex Demo" ]
        , label "Edit or write new LaTeX below. It will be rendered in real time."
        , editor model
        , p [ style "margin-left" "20px", style "font-style" "italic" ]
            [ text "For more information about MiniLaTeX, please go to  "
            , a [ href "https://minilatex.io", target "_blank" ] [ text "minilatex.io" ]
            ]
        ]


display : Model (Html Msg) -> Html Msg
display model =
    div []
        [ h1 [ style "margin-left" "20px" ] [ text "MiniLatex Demo" ]
        , label "Edit or write new LaTeX below. It will be rendered in real time."
        , editor model
        , div [] [ renderedSource model ]

        -- , macroPanel model
        --        , p [ style "margin-left" "20px", style "font-style" "italic" ]
        --                    [ text "This app is a demo of the ongoing MiniLatex research project."
        --                    , br [] []
        --                    , text "See "
        --                    , a [ href "https://knode.io", target "_blank" ] [ text "knode.io" ]
        --                    , text " for a more substantial use of this technology."
        --                    ]]
        ]


label text_ =
    p labelStyle [ text text_ ]


editor : Model (Html msg) -> Html Msg
editor model =
    div []
        [ textarea (editorTextStyle ++ [ onInput GetContent, value model.sourceText ]) []
        , p [ style "clear" "left", style "margin-left" "20px", style "margin-top" "-20px" ] [ clearButton 60, restoreTextButton 80, fullRenderButton 100 ]
        ]


macroPanel : Model (Html msg) -> Html Msg
macroPanel model =
    Html.div []
        [ textarea (macroPanelStyle ++ [ onInput GetMacroText, value model.macroText ]) []
        , p [ style "clear" "left", style "margin-left" "20px", style "padding-top" "10px" ]
            [ text "Macros: write one macro per line (right panel)" ]
        ]


renderedSource : Model (Html msg) -> Html msg
renderedSource model =
    Html.div (renderedSourceStyle ++ [ HA.class "rhs" ])
        [ model.renderedText ]



--
-- BUTTONS
--


clearButton width =
    button ([ onClick Clear ] ++ buttonStyle colorBlue width) [ text "Clear" ]


fullRenderButton width =
    button ([ onClick FullRender ] ++ buttonStyle colorBlue width) [ text "Full Render" ]


restoreTextButton width =
    button ([ onClick RestoreText ] ++ buttonStyle colorBlue width) [ text "Restore" ]


exampleButton width =
    button ([ onClick ExampleText ] ++ buttonStyle colorBlue width) [ text "Example 2" ]
