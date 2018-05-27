module View exposing (..)

import Html exposing (..)
import Html.Attributes as Attr exposing (..)
import Html.Events as Events exposing (onClick, onInput)
import Html.Keyed as Keyed
import Http
import Types exposing (..)
import String
import MeenyLatex.Parser exposing (LatexExpression)
import MeenyLatex.Driver as MeenyLatex
import MeenyLatex.RenderToLatex
import Json.Encode as Encode
import MeenyLatex.Paragraph
import MeenyLatex.RenderLatexForExport


{- Word count -}


wordCount : String -> Int
wordCount str =
    String.split " " str |> List.length


textInfo model =
    let
        wc =
            (String.fromInt <| wordCount model.sourceText) ++ " words, "

        cc =
            (String.fromInt <| String.length model.sourceText) ++ " characters"
    in
        wc ++ cc



{- VIEW FUNCTIONS -}


appWidth : Configuration -> String
appWidth configuration =
    case configuration of
        StandardView ->
            "900px"

        RenderToLatexView ->
            "1350px"

        ParseResultsView ->
            "1350px"

        RawHtmlView ->
            "1350px"


headerRibbon =
    div
        (ribbonStyle "#555")
        [ span [ style "margin-left" "5px" ] [ text "MeenyLatex Demo" ]
        , link "http://www.knode.io" "www.knode.io"
        ]


link url linkText =
    a
        [ class "linkback"
        , style "float" "right"
        , style "margin-right" "10px"
        , href url
        , target "_blank"
        ]
        [ text linkText ]


footerRibbon model =
    div
        (ribbonStyle "#777")
        [ text <| textInfo model
        , link "http://jxxcarlson.github.io" "jxxcarlson.github.io"
        ]


editor model =
    div [ style "float" "left" ]
        [ spacer 20
        , buttonBarLeft
        , spacer 5
        , editorPane model
        , spacer 5
        , buttonBarBottomLeft
        ]


editorPane model =
    Keyed.node "textarea" (editorStyle ++ [ onInput GetContent, value model.sourceText ]) [ ( String.fromInt model.counter, text model.sourceText ) ]


renderedSource : Model msg -> Html msg
renderedSource model =
    div [ style "float" "left" ]
        [ spacer 20
        , buttonBarRight model
        , spacer 5
        , renderedSourcePane model
        , spacer 5
        , buttonBarBottomRight model
        ]


renderToLatex model =
    div [ style "float" "left" ]
        [ spacer 20
        , viewLabel "Text parsed and rendered back to LaTeX (Almost Identity)" 400 --buttonBarRight model
        , spacer 5
        , renderToLatexPane model
        , spacer 5
        , buttonBarBottomRight model
        ]


showParseResult model =
    div [ style "float" "left" ]
        [ spacer 20
        , buttonBarParserResults model
        , spacer 5
        , parseResultPane model
        ]


showHtmlResult model =
    div [ style "float" "left" ]
        [ spacer 20
        , buttonBarRawHtmlResults model
        , spacer 5
        , rawRenderedSourcePane model
        ]


exporterTextArea model =
    Html.textarea ([ Events.onInput Types.Input, Attr.value model.inputString ] ++ textAreaStyle) []


exporterLink model =
    Html.a ([ Attr.href (dataUrl model.inputString), Attr.download "file.html" ] ++ downloadStyle)
        [ text "Export" ]


textAreaStyle =
    [ style "position" "absolute"
    , style "top" "-400px"
    ]


downloadStyle =
    [ style "margin-left" "0px"
    , style "margin-right" "8px"
    , style "padding" "4px"
    , style "padding-left" "10px"
    , style "padding-right" "10px"
    , style "background-color" "#aaa"
    , style "font-size" "11pt"
    ]



{-
   dataUrl : String -> String
   dataUrl data =
       "data:text/plain;charset=utf-8," ++ Url.percentEncode data
-}


dataUrl : String -> String
dataUrl data =
    "data:text/plain;charset=utf-8," ++ "FOO"


prettyPrint : LineViewStyle -> List (List LatexExpression) -> String
prettyPrint lineViewStyle parseResult =
    case lineViewStyle of
        Vertical ->
            parseResult |> List.map Debug.toString |> List.map (String.replace " " "\n ") |> String.join "\n\n"

        Horizontal ->
            parseResult |> List.map Debug.toString |> String.join "\n\n"



{-
   ertical ->
       parseResult |> List.map String.fromInt |> List.map (String.replace " " "\n ") |> String.join "\n\n"

   Horizontal ->
       parseResult |> List.map String.fromInt |> String.join "\n\n"
-}


parseResultPane model =
    pre
        parseResultsStyle
        [ text (prettyPrint model.lineViewStyle model.parseResult) ]


rawRenderedSourcePane model =
    let
        renderedText =
            MeenyLatex.getRenderedText "" model.editRecord
    in
        pre
            parseResultsStyle
            [ Html.text "Not currently available" ]


renderToLatexPane model =
    let
        -- rerenderedText =
        --     MeenyLatex.RenderToLatex.renderBackToLatex model.sourceText
        rerenderedText =
            MeenyLatex.RenderLatexForExport.renderLatexForExport model.sourceText

        --|> MeenyLatex.RenderToLatex.eval
    in
        pre
            reRenderedLatexStyle
            [ text rerenderedText ]


exportLatexPane model =
    pre
        parseResultsStyle
        [ text model.textToExport ]


renderedSourcePane : Model (Html msg) -> Html msg
renderedSourcePane model =
    MeenyLatex.getRenderedText "" model.editRecord
        |> Html.div []



{- Buttons -}


buttonBarLeft =
    div
        [ style "margin-left" "20px" ]
        [ resetButton 93
        , restoreButton 93
        , reRenderButton 93
        , fastRenderButton 96
        ]


buttonBarRight model =
    div
        [ style "margin-left" "20px" ]
        [ exporterTextArea model
        , exporterLink model
        , standardViewButton model 98
        , parseResultsViewButton model 106
        , rawHtmlViewButton model 85
        , renderToLatexViewButton model 40
        ]


buttonBarBottomLeft =
    div
        [ style "margin-left" "20px" ]
        [ techReportButton 93
        , grammarButton 93
        , wavePacketButton 93
        , mathPaperButton 96
        ]


buttonBarBottomRight model =
    div
        [ style "margin-left" "20px" ]
        []


buttonBarRawHtmlResults model =
    div
        [ style "margin-left" "20px", style "margin-top" "0" ]
        [ optionaViewTitleButton model 190 ]


buttonBarParserResults model =
    div
        [ style "margin-left" "20px", style "margin-top" "0" ]
        [ optionaViewTitleButton model 190
        , setHorizontalViewButton model 90
        , setVerticalViewButton model 90
        ]


reRenderButton width =
    button ([ onClick ReRender ] ++ buttonStyle colorBlue width) [ text "Render" ]


fastRenderButton width =
    button ([ onClick FastRender ] ++ buttonStyle colorBlue width) [ text "Fast Render" ]


resetButton width =
    button ([ onClick Reset ] ++ buttonStyle colorBlue width) [ text "Clear" ]


restoreButton width =
    button ([ onClick Restore ] ++ buttonStyle colorBlue width) [ text "Restore" ]


techReportButton width =
    button ([ onClick TechReport ] ++ buttonStyle colorBlue width) [ text "Tech Report" ]


grammarButton width =
    button ([ onClick Grammar ] ++ buttonStyle colorBlue width) [ text "Grammar" ]


wavePacketButton width =
    button ([ onClick WavePackets ] ++ buttonStyle colorBlue width) [ text "WavePacket" ]


weatherAppButton width =
    button ([ onClick WeatherApp ] ++ buttonStyle colorBlue width) [ text "Weather App" ]


mathPaperButton width =
    button ([ onClick MathPaper ] ++ buttonStyle colorBlue width) [ text "Math Paper" ]


setHorizontalViewButton model width =
    if model.lineViewStyle == Horizontal then
        button ([ onClick SetHorizontalView ] ++ buttonStyle colorBlue width) [ text "Horizontal" ]
    else
        button ([ onClick SetHorizontalView ] ++ buttonStyle colorLight width) [ text "Horizontal" ]


setVerticalViewButton model width =
    if model.lineViewStyle == Vertical then
        button ([ onClick SetVerticalView ] ++ buttonStyle colorBlue width) [ text "Vertical" ]
    else
        button ([ onClick SetVerticalView ] ++ buttonStyle colorLight width) [ text "Vertical" ]


standardViewButton model width =
    if model.configuration == StandardView then
        button ([ onClick ShowStandardView ] ++ buttonStyle colorBlue width) [ text "Basic View" ]
    else
        button ([ onClick ShowStandardView ] ++ buttonStyle colorLight width) [ text "Basic View" ]


renderToLatexViewButton model width =
    if model.configuration == RenderToLatexView then
        button ([ onClick ShowRenderToLatexView ] ++ buttonStyle colorBlue width) [ text "AI" ]
    else
        button ([ onClick ShowRenderToLatexView ] ++ buttonStyle colorLight width) [ text "AI" ]


parseResultsViewButton model width =
    if model.configuration == ParseResultsView then
        button ([ onClick ShowParseResultsView ] ++ buttonStyle colorBlue width) [ text "Parse Results" ]
    else
        button ([ onClick ShowParseResultsView ] ++ buttonStyle colorLight width) [ text "Parse Results" ]


rawHtmlViewButton model width =
    if model.configuration == RawHtmlView then
        button ([ onClick ShowRawHtmlView ] ++ buttonStyle colorBlue width) [ text "Raw Html" ]
    else
        button ([ onClick ShowRawHtmlView ] ++ buttonStyle colorLight width) [ text "Raw Html" ]



-- exportLatexViewButton model width =
--     if model.configuration == ExportLatexView then
--         button [ onClick ShowExportLatexView, buttonStyle colorBlue width ] [ text "Export" ]
--     else
--         button [ onClick ShowExportLatexView, buttonStyle colorLight width ] [ text "Export" ]


optionaViewTitleButton model width =
    case model.configuration of
        StandardView ->
            button (buttonStyle colorDark width) [ text "Basic" ]

        ParseResultsView ->
            button (buttonStyle colorDark width) [ text "Parse results" ]

        RawHtmlView ->
            button (buttonStyle colorDark width) [ text "Raw HTML" ]

        RenderToLatexView ->
            button (buttonStyle colorDark width) [ text "Latex (2)" ]


viewLabel text_ width =
    button ((buttonStyle colorDark width) ++ [ style "margin-left" "20px" ]) [ text text_ ]



{- Elements -}


spacer n =
    div [ style "height" (String.fromInt n ++ "px"), style "clear" "left" ] []


label text_ =
    p labelStyle [ text text_ ]



{- STYLE FUNCTIONS -}


ribbonStyle color =
    [ style "width" "840px"
    , style "height" "20px"
    , style "margin-left" "20px"
    , style "margin-bottom" "-16px"
    , style "padding" "8px"
    , style "clear" "left"
    , style "background-color" color
    , style "color" "#eee"
    ]


colorBlue =
    "rgb(100,100,200)"


colorLight =
    "#88a"


colorDark =
    "#444"


buttonStyle : String -> Int -> List (Html.Attribute msg)
buttonStyle color width =
    let
        realWidth =
            width + 0 |> String.fromInt |> \x -> x ++ "px"
    in
        [ style "backgroundColor" color
        , style "color" "white"
        , style "width" realWidth
        , style "height" "25px"
        , style "margin-right" "8px"
        , style "font-size" "9pt"
        , style "text-align" "center"
        , style "border" "none"
        ]


labelStyle =
    [ style "margin-top" "5px"
    , style "margin-bottom" "0px"
    , style "margin-left" "20px"
    , style "font-style" "bold"
    , style "background-color" "#444"
    , style "color" "#ddd"
    , style "width" "90px"
    ]


editorStyle =
    textStyle "400px" "635px" "20px" "#eef"


renderedSourceStyle =
    textStyle "400px" "600px" "20px" "#eee"


parseResultsStyle =
    textStyle2 "400px" "600px" "20px" "#eee"


reRenderedLatexStyle =
    textStyle3 "400px" "600px" "20px" "#eee"


textStyle width height offset color =
    [ style "width" width
    , style "height" height
    , style "padding" "15px"
    , style "margin-left" offset
    , style "background-color" color
    , style "overflow" "scroll"
    ]


textStyle2 width height offset color =
    [ style "width" width
    , style "height" height
    , style "padding" "15px"
    , style "margin-top" "0"
    , style "margin-left" offset
    , style "background-color" color
    , style "overflow" "scroll"
    ]


textStyle3 width height offset color =
    [ style "width" width
    , style "height" height
    , style "padding" "15px"
    , style "margin-top" "0"
    , style "margin-left" offset
    , style "background-color" color
    , style "overflow" "scroll"
    , style "white-space" "pre-line"
    ]
