port module Main exposing (..)

{-| Test app for MiniLatex
-}

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Keyed as Keyed
import MiniLatex.HasMath
import MiniLatex.Driver as MiniLatex
import MiniLatex.Differ exposing (EditRecord)
import Random
import App.Source as Source
import App.View exposing (..)
import App.Types exposing (..)
import Json.Encode as Encode


main =
    Html.program { view = view, update = update, init = init, subscriptions = subscriptions }


init : ( Model, Cmd Msg )
init =
    let
        parseResult =
            MiniLatex.parse Source.initialText

        model =
            { sourceText = Source.initialText
            , editRecord = MiniLatex.setup 0 Source.initialText
            , parseResult = parseResult
            , hasMathResult = Debug.log "hasMathResult" (List.map MiniLatex.HasMath.listHasMath parseResult)
            , seed = 0
            , configuration = StandardView
            , lineViewStyle = Horizontal
            }
    in
        ( model, Random.generate NewSeed (Random.int 1 10000) )


port sendToJs : Encode.Value -> Cmd msg


encodeData model idList =
    let
        idValueList =
            Debug.log "idValueList"
                (List.map Encode.string idList)
    in
        [ ( "mode", Encode.string model )
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

                parseResult =
                    MiniLatex.parse model.sourceText

                hasMathResult =
                    Debug.log "hasMathResult" (List.map MiniLatex.HasMath.listHasMath parseResult)
            in
                ( { model
                    | editRecord = newEditRecord
                    , parseResult = parseResult
                    , hasMathResult = hasMathResult
                  }
                , Cmd.batch
                    [ sendToJs <| encodeData "fast" newEditRecord.idList
                    , Random.generate NewSeed (Random.int 1 10000)
                    ]
                )

        ReRender ->
            let
                editRecord =
                    MiniLatex.setup model.seed model.sourceText

                _ =
                    Debug.log "TOC" editRecord.latexState.tableOfContents
            in
                ( { model
                    | editRecord = editRecord
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
                | sourceText = Source.initialText
                , editRecord = MiniLatex.setup model.seed Source.initialText
              }
            , sendToJs <| encodeData "full" []
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
            useSource Source.nongeodesic model

        Grammar ->
            useSource Source.grammar model


useSource text model =
    ( { model
        | sourceText = text
        , editRecord = MiniLatex.setup model.seed text
      }
    , sendToJs <| encodeData "full" []
    )


appWidth : Configuration -> String
appWidth configuration =
    case configuration of
        StandardView ->
            "900px"

        ParseResultsView ->
            "1350px"

        RawHtmlView ->
            "1350px"


view : Model -> Html Msg
view model =
    div [ style [ ( "width", appWidth model.configuration ), ( "margin", "auto" ) ] ]
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


standardView model =
    div [ style [ ( "float", "left" ) ] ]
        [ headerRibbon
        , editor model
        , renderedSource model
        , spacer 5
        , footerRibbon model
        ]


parseResultsView model =
    div [ style [ ( "float", "left" ) ] ]
        [ headerRibbon
        , editor model
        , renderedSource model
        , showParseResult model
        , spacer 5
        , footerRibbon model
        ]


rawHtmlResultsView model =
    div [ style [ ( "float", "left" ) ] ]
        [ headerRibbon
        , editor model
        , renderedSource model
        , showHtmlResult model
        , spacer 5
        , footerRibbon model
        ]
