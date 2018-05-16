module Types exposing (..)

import MeenyLatex.Parser exposing (LatexExpression)
import MeenyLatex.Differ exposing (EditRecord)


type alias Model =
    { counter : Int
    , sourceText : String
    , sourceText2 : String
    , parseResult : List (List LatexExpression)
    , inputString : String
    , hasMathResult : List Bool
    , editRecord : EditRecord
    , seed : Int
    , configuration : Configuration
    , lineViewStyle : LineViewStyle
    , windowHeight : Int
    , windowWidth : Int
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
    | ShowRenderToLatexView
    | SetHorizontalView
    | SetVerticalView
    | TechReport
    | WavePackets
    | WeatherApp
    | MathPaper
    | Grammar
    | Input String


type LineViewStyle
    = Horizontal
    | Vertical


type Configuration
    = StandardView
    | ParseResultsView
    | RawHtmlView
    | RenderToLatexView
