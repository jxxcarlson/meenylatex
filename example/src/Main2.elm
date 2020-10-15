module Main2 exposing (..)

import Browser
import Element exposing (..)
import Element.Background as Background
import Html exposing (Html, div, h1, img, text)
import Html.Attributes exposing (src, style)
import MiniLatex.EditSimple
import Strings



---- MODEL ----


type alias Model =
    {}


init : ( Model, Cmd Msg )
init =
    ( {}, Cmd.none )



---- UPDATE ----


type Msg
    = NoOp
    | LatexMsg MiniLatex.EditSimple.LaTeXMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    Element.layoutWith { options = [] }
        [ width fill, height fill, padding 40 ]
        (mainColumn model)


mainColumn model =
    column []
        [ MiniLatex.EditSimple.render Strings.sourceText |> Html.map LatexMsg |> Element.html ]



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }
