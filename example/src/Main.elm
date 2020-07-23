module Main exposing (..)

import Browser
import Html exposing (Html, div, h1, img, text)
import Html.Attributes exposing (src, style)
import MiniLatex
import MiniLatex.Edit
import MiniLatex.Render exposing (MathJaxRenderOption(..))



---- MODEL ----


type alias Model =
    {}


init : ( Model, Cmd Msg )
init =
    ( {}, Cmd.none )



---- UPDATE ----


type Msg
    = NoOp
    | LatexMsg MiniLatex.Edit.LaTeXMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



---- VIEW ----


sourceText =
    """

Pythagoras: $a^2 + b^2 = c^2$.

Calculus:

$$
  \\int_0^1 x^n dx = \\frac{1}{n + 1}
$$

$$
\\begin{pmatrix}
2 & 1 \\\\
1 & 2 \\\\
\\end{pmatrix}
$$


"""


view : Model -> Html Msg
view model =
    div [ style "margin" "50px" ]
        [ h1 [] [ text "Example" ]
        , div [ style "font-size" "18px" ]
            [ MiniLatex.render "noSelectedId" NoDelay sourceText |> Html.map LatexMsg
            ]
        ]



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }
