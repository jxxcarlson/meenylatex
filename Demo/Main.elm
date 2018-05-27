port module Main exposing (..)

{-| Test app for MeenyLatex
-}

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Keyed as Keyed
import MeenyLatex.HasMath
import MeenyLatex.Driver as MeenyLatex
import MeenyLatex.Differ exposing (EditRecord)
import Random
import Source
import View exposing (..)
import Types exposing (..)
import Json.Encode as Encode


main =
    Browser.embed
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }



--
-- { init : { flags : flags, url : Url.Parser.Url } -> ( model, Cmd msg )
-- , onNavigation : Maybe (Url.Parser.Url -> msg)
-- , subscriptions : model -> Sub msg
-- , update : msg -> model -> ( model, Cmd msg )
-- , view : model -> Browser.Page msg
-- }


type alias Flags =
    { width : Int
    , height : Int
    }


init : Flags -> ( Model (Html msg), Cmd Msg )
init flags =
    let
        parseResult =
            MeenyLatex.parse Source.initialText

        editRecord =
            MeenyLatex.setup 0 Source.initialText

        _ =
            Debug.log "RENDERED TEXT" (MeenyLatex.getRenderedText "" editRecord)

        model =
            { counter = 0
            , sourceText = Source.initialText
            , sourceText2 = Source.initialText
            , editRecord = editRecord
            , inputString = exportLatex2Html editRecord
            , parseResult = parseResult
            , hasMathResult = Debug.log "hasMathResult" (List.map MeenyLatex.HasMath.listHasMath parseResult)
            , seed = 0
            , configuration = StandardView
            , lineViewStyle = Horizontal
            , windowWidth = flags.width
            , windowHeight = flags.height
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
                    MeenyLatex.update model.seed model.editRecord model.sourceText

                parseResult =
                    MeenyLatex.parse model.sourceText

                hasMathResult =
                    Debug.log "hasMathResult" (List.map MeenyLatex.HasMath.listHasMath parseResult)
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
                , editRecord = MeenyLatex.setup model.seed ""
              }
            , Cmd.none
              -- sendToJs <| encodeData "full" []
            )

        Restore ->
            ( { model
                | counter = model.counter + 1
                , sourceText = Source.initialText
                , editRecord = MeenyLatex.setup model.seed Source.initialText
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
            useSource Source.nongeodesic model

        Grammar ->
            useSource Source.grammar model

        Types.Input s ->
            ( { model | inputString = s }, Cmd.none )


useSource : String -> Model (Html msg) -> ( Model (Html msg), Cmd Msg )
useSource text model =
    let
        editRecord =
            MeenyLatex.setup model.seed text
    in
        ( { model
            | counter = model.counter + 1
            , sourceText = text
            , editRecord = editRecord
            , parseResult = MeenyLatex.parse text
            , inputString = exportLatex2Html editRecord
          }
        , Cmd.none
        )


exportLatex2Html : EditRecord (Html msg) -> String
exportLatex2Html editRecord =
    editRecord
        |> MeenyLatex.getRenderedText ""
        |> \text -> Source.htmlPrefix ++ text ++ Source.htmlSuffix



{-
   encodeData : Model -> List String -> Encode.Value
   encodeData model idList =
       [ ( "model", Encode.string model )
       , ( "idList", Encode.list Encode.string idList )
       ]
           |> Encode.object
-}
{- VIEW FUNCTIONS -}
-- view : Model (Html msg) -> Html msg


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


standardView : Model (Html msg) -> Html msg
standardView model =
    div [ style "float" "left" ]
        [ headerRibbon
        , editor model
        , renderedSource model
        , spacer 5
        , footerRibbon model
        ]


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
