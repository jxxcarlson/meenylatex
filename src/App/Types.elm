module App.Types exposing (..)

import MiniLatex.Parser exposing (LatexExpression)
import MiniLatex.Differ exposing (EditRecord)


type alias Model =
    { sourceText : String
    , parseResult : List (List LatexExpression)
    , textToExport : String
    , inputString : String
    , hasMathResult : List Bool
    , editRecord : EditRecord
    , seed : Int
    , configuration : Configuration
    , lineViewStyle : LineViewStyle
    }


type Msg
    = FastRender
    | GetContent String
    | ReRender
    | Reset
    | Restore
    | GenerateSeed
    | NewSeed Int
    | ShowStandardView
    | ShowParseResultsView
    | ShowRawHtmlView
    | ShowExportLatexView
    | SetHorizontalView
    | SetVerticalView
    | TechReport
    | WavePackets
    | WeatherApp
    | MathPaper
    | Grammar
    | ExportLatex
    | Input String


type LineViewStyle
    = Horizontal
    | Vertical


type Configuration
    = StandardView
    | ParseResultsView
    | RawHtmlView
    | ExportLatexView
