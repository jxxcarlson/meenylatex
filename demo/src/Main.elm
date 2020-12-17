module Main exposing (main)

import Browser
import Browser.Dom as Dom
import Debounce exposing (Debounce)
import File.Download as Download
import Html exposing (..)
import Html.Attributes as HA exposing (..)
import Html.Events exposing (onClick, onInput)
import MiniLatex
import MiniLatex.Edit exposing (Data)
import MiniLatex.Export
import Random
import StringsV1
import TestData
import Renzo
import Style exposing (..)
import Task exposing (Task)


sourceText = TestData.text
    -- Renzo.text
    -- TestData.text
    -- StringsV2.initialText



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
    , images : List String
    , imageUrl : String
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
    | Export


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
            MiniLatex.Edit.init flags.seed sourceText

        model =
            { sourceText = sourceText
            , macroText = ""
            , renderedText = render "" sourceText
            , editRecord = editRecord
            , debounce = Debounce.init
            , counter = 0
            , seed = flags.seed
            , selectedId = ""
            , message = "No message yet ..."
            , images = []
            , imageUrl = ""
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
        NoOp ->
            ( model, Cmd.none )

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

        GetMacroText str ->
            ( { model | macroText = str }, Cmd.none )

        Render str ->
            let
                n =
                    String.fromInt model.counter

                newEditRecord =
                    MiniLatex.Edit.update model.seed str model.editRecord
            in
            ( { model
                | editRecord = newEditRecord
                , renderedText = renderFromEditRecord model.selectedId model.counter newEditRecord
                , counter = model.counter + 2
              }
            , Random.generate NewSeed (Random.int 1 10000)
            )

        Export ->
            let
                ( contentForExport, images ) =
                    model.sourceText |> MiniLatex.Export.toLaTeXWithImages
            in
            ( { model | images = images }, Download.string "mydocument.tex" "text/x-tex" contentForExport )

        GenerateSeed ->
            ( model, Random.generate NewSeed (Random.int 1 10000) )

        NewSeed newSeed ->
            ( { model | seed = newSeed }, Cmd.none )

        Clear ->
            let
                editRecord =
                    MiniLatex.Edit.init 0 ""
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
                    MiniLatex.Edit.init model.seed model.sourceText
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
                    MiniLatex.Edit.init model.seed (prependMacros initialMacroText sourceText)
            in
            ( { model
                | counter = model.counter + 1
                , editRecord = editRecord
                , sourceText = sourceText
                , renderedText = renderFromEditRecord model.selectedId model.counter editRecord
              }
            , Cmd.none
            )

        ExampleText ->
            let
                editRecord =
                    MiniLatex.Edit.init model.seed (prependMacros initialMacroText sourceText)
            in
            ( { model
                | counter = model.counter + 1
                , editRecord = editRecord
                , sourceText = sourceText
                , renderedText = renderFromEditRecord model.selectedId model.counter editRecord
              }
            , Cmd.none
            )

        SetViewPortForElement result ->
            case result of
                Ok ( element, viewport ) ->
                    ( model, setViewPortForSelectedLine element viewport )

                Err _ ->
                    ( model, Cmd.none )

        LaTeXMsg laTeXMsg ->
            case laTeXMsg of
                MiniLatex.Edit.IDClicked id ->
                    ( { model
                        | message = "Clicked: " ++ id
                        , selectedId = id
                        , counter = model.counter + 2
                        , renderedText = renderFromEditRecord id model.counter model.editRecord
                      }
                    , Cmd.none
                    )


normalize : String -> String
normalize str =
    str |> String.lines |> List.filter (\x -> x /= "") |> String.join "\n"


prependMacros : String -> String -> String
prependMacros macros_ sourceText_ =
    "$$\n" ++ (macros_ |> normalize) ++ "\n$$\n\n" ++ sourceText_


renderFromEditRecord : String -> Int -> Data (Html MiniLatex.Edit.LaTeXMsg) -> Html Msg
renderFromEditRecord selectedId counter editRecord =
    MiniLatex.Edit.get selectedId editRecord
        |> List.map (Html.map LaTeXMsg)
        |> List.map (\x -> Html.div [ HA.style "margin-bottom" "0.65em" ] [ x ])
        |> Html.div []


render_ : String -> Cmd Msg
render_ str =
    Task.perform Render (Task.succeed str)


render : String -> String -> Html Msg
render selectedId sourceText_ =
    let
        macroDefinitions =
            initialMacroText
    in
    MiniLatex.render selectedId sourceText_ |> Html.map LaTeXMsg



-- VIEW FUNCTIONS


view : Model -> Html Msg
view model =
    div (outerStyle ++ [ HA.class "container" ])
        [ lhs model
        , renderedSource model
        , viewImages model
        ]


viewImages model =
    div [ HA.style "overflow" "scroll", HA.style "height" "500px" ] (List.map viewImage model.images)


viewImage : String -> Html Msg
viewImage url =
    div []
        [ Html.a
            [ HA.style "margin-left" "18px"
            , HA.style "padding-bottom" "9px"
            , HA.href url
            ]
            [ Html.img [ HA.src url, HA.style "height" "30px" ] []
            ]
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
        , p [ style "margin-left" "20px" ] [ text model.message ]
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
        , p [ style "clear" "left", style "margin-left" "20px", style "margin-top" "-20px" ]
            [ clearButton 60
            , restoreTextButton 80
            , fullRenderButton 100
            , exportButton 80
            ]
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
        [ model.renderedText ]


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


exportButton width =
    button ([ onClick Export ] ++ buttonStyle colorBlue width) [ text "Export" ]


exampleButton width =
    button ([ onClick ExampleText ] ++ buttonStyle colorBlue width) [ text "Example 2" ]
