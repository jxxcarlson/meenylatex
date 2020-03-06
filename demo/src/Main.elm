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
import Task exposing(Task)
import Browser.Dom as Dom


initialText = StringsV2.initialText
  -- "Test: $a^2 = 1$\n\nooo\n\niii"
    --


main : Program Flags Model Msg
main =
    Browser.element
        { view = view
        , update = update
        , init = init
        , subscriptions = subscriptions
        }

-- MODEL

type alias Model =
    { sourceText : String
    , renderedText : Html Msg
    , macroText : String
    , editRecord : Data (Html MiniLatex.Edit.LaTeXMsg)
    , debounce : Debounce String
    , counter : Int
    , seed : Int
    , selectedId : String
    , message : String
    }


type Msg
    = NoOp
    | Clear
    | Render String
    | GetContent String
    | GetMacroText String
    | DebounceMsg Debounce.Msg
    | GenerateSeed
    | NewSeed Int
    | FullRender
    | RestoreText
    | ExampleText
    | SetViewPortForElement (Result Dom.Error ( Dom.Element, Dom.Viewport ))
    | LaTeXMsg MiniLatex.Edit.LaTeXMsg



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


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        editRecord =
            MiniLatex.Edit.init NoDelay flags.seed initialText


        model =
            { sourceText = initialText
            , macroText = ""
            , renderedText = render  "" initialText
            , editRecord = editRecord
            , debounce = Debounce.init
            , counter = 0
            , seed = flags.seed
            , selectedId  = ""
            , message = "No message yet ..."
            }
    in
    ( model, Cmd.none )


initialMacroText =
    normalize StringsV1.macros


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp -> (model, Cmd.none)

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
                    -- MiniLatex.Edit.update NoDelay model.seed (prependMacros model.macroText str) model.editRecord
                    MiniLatex.Edit.update NoDelay model.seed str model.editRecord
            in
            ( { model
                | editRecord = newEditRecord
                , renderedText = renderFromEditRecord model.selectedId model.counter newEditRecord
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
                , renderedText = renderFromEditRecord model.selectedId model.counter editRecord
                , counter = model.counter + 1
              }
            , Cmd.none
            )

        FullRender ->
            let
                editRecord =
                    MiniLatex.Edit.init NoDelay model.seed model.sourceText
            in
            ( { model
                | counter = model.counter + 1
                , editRecord = editRecord
                , renderedText = renderFromEditRecord model.selectedId model.counter editRecord
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
                , renderedText = renderFromEditRecord model.selectedId model.counter editRecord
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
                , renderedText = renderFromEditRecord model.selectedId model.counter editRecord
              }
            , Cmd.none
            )

        SetViewPortForElement result ->
            case result of
                Ok ( element, viewport ) ->
                    ( model, setViewPortForSelectedLine element viewport )

                Err _ ->
                    ( model , Cmd.none )

        LaTeXMsg laTeXMsg ->
            case laTeXMsg of
                MiniLatex.Edit.IDClicked id ->
                  ({model | message = "Clicked: " ++ id
                    , selectedId = id
                    , counter = model.counter + 2
                    , renderedText = renderFromEditRecord id model.counter model.editRecord}, Cmd.none)



normalize : String -> String
normalize str =
    str |> String.lines |> List.filter (\x -> x /= "") |> String.join "\n"


prependMacros : String -> String -> String
prependMacros macros_ sourceText =
    "$$\n" ++ (macros_ |> normalize) ++ "\n$$\n\n" ++ sourceText


renderFromEditRecord : String -> Int -> Data (Html MiniLatex.Edit.LaTeXMsg) -> Html Msg
renderFromEditRecord selectedId counter editRecord =
    MiniLatex.Edit.get selectedId  editRecord
        |> List.map (Html.map LaTeXMsg)
        |> List.map (\x -> Html.div [ HA.style "margin-bottom" "0.65em" ] [ x ])
        |> Html.div []


render_ : String -> Cmd Msg
render_ str =
    Task.perform Render (Task.succeed str)


render : String -> String -> Html Msg
render selectedId sourceText =
    let
        macroDefinitions =
            initialMacroText
    in
    MiniLatex.render selectedId NoDelay macroDefinitions sourceText |> Html.map LaTeXMsg



--
-- VIEW FUNCTIONS
---


view : Model -> Html Msg
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
         , p [style "margin-left" "20px"] [text model.message]
        ]


display : Model -> Html Msg
display model =
    div []
        [ h1 [ style "margin-left" "20px" ] [ text "MiniLatex Demo" ]
        , label "Edit or write new LaTeX below. It will be rendered in real time."
        , editor model
        , div [] [ renderedSource model ]
        ]


label text_ =
    p labelStyle [ text text_ ]


editor : Model -> Html Msg
editor model =
    div []
        [ textarea (editorTextStyle ++ [ onInput GetContent, value model.sourceText ]) []
        , p [ style "clear" "left", style "margin-left" "20px", style "margin-top" "-20px" ] [ clearButton 60, restoreTextButton 80, fullRenderButton 100 ]
        ]


macroPanel : Model -> Html Msg
macroPanel model =
    Html.div []
        [ textarea (macroPanelStyle ++ [ onInput GetMacroText, value model.macroText ]) []
        , p [ style "clear" "left", style "margin-left" "20px", style "padding-top" "10px" ]
            [ text "Macros: write one macro per line (right panel)" ]
        ]


renderedSource : Model -> Html Msg
renderedSource model =
    Html.div (renderedSourceStyle ++ [ HA.class "rhs" ])
        [ model.renderedText]

setViewportForElement : String -> Cmd Msg
setViewportForElement id =
    Dom.getViewportOf "__RENDERED_TEXT__"
        |> Task.andThen (\vp -> getElementWithViewPort vp id)
        |> Task.attempt SetViewPortForElement


setViewPortForSelectedLine : Dom.Element -> Dom.Viewport -> Cmd Msg
setViewPortForSelectedLine element viewport =
    let
        y =
            viewport.viewport.y + element.element.y - element.element.height - 100
    in
    Task.attempt (\_ -> NoOp) (Dom.setViewportOf "__RENDERED_TEXT__" 0 y)



getElementWithViewPort : Dom.Viewport -> String -> Task Dom.Error ( Dom.Element, Dom.Viewport )
getElementWithViewPort vp id =
    Dom.getElement id
        |> Task.map (\el -> ( el, vp ))

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
