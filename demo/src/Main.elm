port module Main exposing (..)

{-| Test app for MiniLatex
-}

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Keyed as Keyed
import MeenyLatex.HasMath as HasMath
import MeenyLatex.MiniLatex as MiniLatex
import MeenyLatex.Differ exposing (EditRecord)
import Random
import Source
import View exposing (..)
import Types exposing (..)
import Json.Encode as Encode
import Time exposing (Posix)
import Task


main =
    Browser.element
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }


type alias Flags =
    { width : Int
    , height : Int
    }


init : Flags -> ( Model (Html msg), Cmd Msg )
init flags =
    let
        parseResult =
            MiniLatex.parse Source.initialText

        editRecord =
            MiniLatex.setup 0 Source.initialText

        model =
            { counter = 0
            , sourceText = Source.initialText
            , sourceText2 = Source.initialText
            , editRecord = editRecord
            , inputString = exportLatex2Html editRecord
            , parseResult = parseResult
            , hasMathResult = (List.map HasMath.listHasMath parseResult)
            , seed = 0
            , configuration = StandardView
            , lineViewStyle = Horizontal
            , windowWidth = flags.width
            , windowHeight = flags.height
            , startTime = Time.millisToPosix 0
            , stopTime = Time.millisToPosix 0
            , message = ""
            }
    in
        ( model, Random.generate NewSeed (Random.int 1 10000) )


port sendToJs : Encode.Value -> Cmd msg


subscriptions : Model (Html msg) -> Sub Msg
subscriptions model =
    Sub.none


update : Msg -> Model (Html msg) -> ( Model (Html msg), Cmd Msg )
update msg model =
    case msg of
        FastRender ->
            let
                newEditRecord =
                    MiniLatex.update model.seed model.editRecord model.sourceText

                parseResult =
                    MiniLatex.parse model.sourceText

                hasMathResult =
                    (List.map HasMath.listHasMath parseResult)
            in
                ( { model
                    | counter = model.counter + 1
                    , editRecord = newEditRecord
                    , parseResult = parseResult
                    , hasMathResult = hasMathResult
                  }
                , Cmd.batch
                    [ -- sendToJs <| encodeData "fast" newEditRecord.idList
                      Random.generate NewSeed (Random.int 1 10000)
                    ]
                )

        ReRender ->
            useSource model.sourceText model

        Reset ->
            ( { model
                | counter = model.counter + 1
                , sourceText = ""
                , editRecord = MiniLatex.setup model.seed ""
              }
            , Cmd.none
              -- sendToJs <| encodeData "full" []
            )

        Restore ->
            ( { model
                | counter = model.counter + 1
                , sourceText = Source.initialText
                , editRecord = MiniLatex.setup model.seed Source.initialText
              }
            , Cmd.none
              -- sendToJs <| encodeData "full" []
            )

        GetContent str ->
            ( { model | sourceText = str }, Cmd.none )

        GenerateSeed ->
            ( model, Random.generate NewSeed (Random.int 1 10000) )

        NewSeed newSeed ->
            ( { model | seed = newSeed }, Cmd.none )

        ShowStandardView ->
            ( { model | configuration = StandardView }, Cmd.none )

        ShowParseResultsView ->
            ( { model | configuration = ParseResultsView }, Cmd.none )

        ShowRenderToLatexView ->
            ( { model | configuration = RenderToLatexView }, Cmd.none )

        ShowRawHtmlView ->
            ( { model | configuration = RawHtmlView }, Cmd.none )

        SetHorizontalView ->
            ( { model | lineViewStyle = Horizontal }, Cmd.none )

        SetVerticalView ->
            ( { model | lineViewStyle = Vertical }, Cmd.none )

        TechReport ->
            useSource Source.report model

        WavePackets ->
            useSource Source.wavePackets model

        WeatherApp ->
            useSource Source.weatherApp model

        MathPaper ->
            useSource Source.basicExample model
            -- useSource Source.nongeodesic model

        Grammar ->
            useSource Source.grammar model

        Types.Input s ->
            ( { model | inputString = s }, Cmd.none )

        RequestStartTime ->
            ( model, Task.perform ReceiveStartTime Time.now )

        RequestStopTime ->
            ( model, Task.perform ReceiveStopTime Time.now )

        ReceiveStartTime startTime ->
            let
                start =
                    toFloat
                        (Time.toMillis Time.utc startTime)

                message =
                    "Start: " ++ String.fromFloat start
            in
                ( { model | startTime = startTime, message = message }, Cmd.none )

        ReceiveStopTime stopTime ->
            let
                start =
                    toFloat
                        (Time.toMillis Time.utc model.startTime)

                stop =
                    toFloat
                        (Time.toMillis Time.utc stopTime)

                elapsedMilliseconds =
                    (stop - start)

                message =
                    "Elapsed: " ++ String.fromFloat elapsedMilliseconds
            in
                ( { model | stopTime = stopTime, message = message }, Cmd.none )


useSource : String -> Model (Html msg) -> ( Model (Html msg), Cmd Msg )
useSource text model =
    let
        editRecord =
            MiniLatex.setup model.seed text
    in
        ( { model
            | counter = model.counter + 1
            , sourceText = text
            , editRecord = editRecord
            , parseResult = MiniLatex.parse text
            , inputString = exportLatex2Html editRecord
          }
        , getStartTime
        )


getStopTime =
    Task.perform ReceiveStopTime Time.now


getStartTime =
    Task.perform ReceiveStartTime Time.now


exportLatex2Html : EditRecord (Html msg) -> String
exportLatex2Html editRecord =
    "NOT IMPLEMENTED"



view model =
    div [ style "width" (appWidth model.configuration), style "margin" "auto" ]
        [ mainView model
        ]


mainView model =
    case model.configuration of
        StandardView ->
            standardView model

        ParseResultsView ->
            parseResultsView model

        RawHtmlView ->
            rawHtmlResultsView model

        RenderToLatexView ->
            renderToLatexView model


standardView : Model (Html Msg) -> Html Msg
standardView model =
    div [ style "float" "left" ]
        [ headerRibbon
        , editor model
        , Keyed.node "div" renderedLatexStyle [ ((String.fromInt model.counter), renderedSource model) ]
        , spacer 5
        , footerRibbon model
        ]



--
-- standardView : Model (Html Msg) -> Html Msg
-- standardView model =
--     div []
--         [ renderedSource model
--         ]
--


renderToLatexView model =
    div [ style "float" "left" ]
        [ headerRibbon
        , editor model
        , renderedSource model
        , renderToLatex model
        , spacer 5
        , footerRibbon model
        ]


parseResultsView model =
    div [ style "float" "left" ]
        [ headerRibbon
        , editor model
        , renderedSource model
        , showParseResult model
        , spacer 5
        , footerRibbon model
        ]


rawHtmlResultsView model =
    div [ style "float" "left" ]
        [ headerRibbon
        , editor model
        , renderedSource model
        , showHtmlResult model
        , spacer 5
        , footerRibbon model
        ]
