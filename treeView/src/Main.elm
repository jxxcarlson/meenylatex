module Main exposing (main)

{- This is a starter app which presents a text label, text field, and a button.
   What you enter in the text field is echoed in the label.  When you press the
   button, the text in the label is reverse.
   This version uses `mdgriffith/elm-ui` for the view functions.
-}

import Browser
import Html exposing (Html)
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import MiniLatex
import Paragraph


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { input : String
    , output : String
    }


type Msg
    = NoOp
    | InputText String
    | Parse


type alias Flags =
    {}


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { input = "Pythagoras said: $a^2 + b^2 = c^2$"
      , output = ""
      }
    , Cmd.none
    )


subscriptions model =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        InputText str ->
            ( { model | input = str, output = str }, Cmd.none )

        Parse ->
            ( { model | output = parseInput model.input }, Cmd.none )

parseInput : String -> String
parseInput str =
    MiniLatex.parse str
      |> Debug.toString


formatOptions =
   { maximumWidth = 460
    , optimalWidth = 400
    , stringWidth = String.length
    }
--
-- VIEW
--


view : Model -> Html Msg
view model =
    Element.layoutWith { options = [focusStyle noFocus]} [] (mainView model)

noFocus : Element.FocusStyle
noFocus =
    { borderColor = Nothing
    , backgroundColor = Nothing
    , shadow = Nothing
    }

mainView : Model -> Element Msg
mainView model =
    column mainColumnStyle
        [ column [  spacing 20 ]
            [ title "Parser Tool"
            , inputText model
            , appButton
            , outputDisplay model
            ]
        ]


title : String -> Element msg
title str =
    row [  Font.size 36 ] [ text str ]


outputDisplay : Model -> Element msg
outputDisplay model =
    row [ padding 12, width (fill), height (px 40), Background.color (gray 1.0)]
        [ text model.output ]


gray g = Element.rgb g g g

inputText : Model -> Element Msg
inputText model =
    el [moveLeft 5]
        (Input.multiline [width (px 560), height (px 200)]
            { onChange = InputText
            , text = model.input
            , placeholder = Nothing
            , spellcheck = False
            , label = Input.labelLeft [] <| el [] (text "")
            })


appButton : Element Msg
appButton =
    row [ ]
        [ Input.button buttonStyle
            { onPress = Just Parse
            , label = el [ centerX, centerY ] (text "Parse")
            }
        ]



--
-- STYLE
--


mainColumnStyle =
    [ centerX
    , centerY
    , Background.color (rgb255 240 240 240)
    , paddingXY 40 40
    , width fill
    , height fill
    ]


buttonStyle =
    [ Background.color (rgb255 40 40 40)
    , Font.color (rgb255 255 255 255)
    , paddingXY 15 8
    ]
