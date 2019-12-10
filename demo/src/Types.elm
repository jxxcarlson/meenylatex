module Types exposing (..)

import Internal.Parser exposing (LatexExpression)
import MiniLatex.Edit
import Html exposing (Html)
import Time exposing (Posix)


type alias Model a =
    { counter : Int
    , sourceText : String
    , sourceText2 : String
    , parseResult : List (List LatexExpression)
    , inputString : String
    , hasMathResult : List Bool
    , editData : MiniLatex.Edit.Data a
    , seed : Int
    , configuration : Configuration
    , lineViewStyle : LineViewStyle
    , windowHeight : Int
    , windowWidth : Int
    , startTime : Posix
    , stopTime : Posix
    , message : String
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
    | RequestStartTime
    | RequestStopTime
    | ReceiveStartTime Posix
    | ReceiveStopTime Posix


type LineViewStyle
    = Horizontal
    | Vertical


type Configuration
    = StandardView
    | ParseResultsView
    | RawHtmlView
    | RenderToLatexView
