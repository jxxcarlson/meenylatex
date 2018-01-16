port module Main exposing (..)

{-| Test app for MiniLatex
-}

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Keyed as Keyed
import Json.Encode as Encode
import MiniLatex.Driver as MiniLatex
import MiniLatex.HasMath
import MiniLatex.Differ exposing (EditRecord)
import MiniLatex.Parser exposing (LatexExpression)
import Random
import String.Extra


main =
    Html.program { view = view, update = update, init = init, subscriptions = subscriptions }


type alias Model =
    { sourceText : String
    , parseResult : List (List LatexExpression)
    , hasMathResult : List Bool
    , editRecord : EditRecord
    , seed : Int
    , configuration : Configuration
    , lineViewStyle : LineViewStyle
    }


type Configuration
    = StandardView
    | ParseResultsView
    | RawHtmlView


type LineViewStyle
    = Horizontal
    | Vertical


init : ( Model, Cmd Msg )
init =
    let
        parseResult =
            MiniLatex.parse initialSourceText

        model =
            { sourceText = initialSourceText
            , editRecord = MiniLatex.setup 0 initialSourceText
            , parseResult = parseResult
            , hasMathResult = Debug.log "hasMathResult" (List.map MiniLatex.HasMath.listHasMath parseResult)
            , seed = 0
            , configuration = StandardView
            , lineViewStyle = Horizontal
            }
    in
        ( model, Random.generate NewSeed (Random.int 1 10000) )


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
    | SetHorizontalView
    | SetVerticalView


port sendToJs : Encode.Value -> Cmd msg


encodeData mode idList =
    let
        idValueList =
            Debug.log "idValueList"
                (List.map Encode.string idList)
    in
        [ ( "mode", Encode.string mode )
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
                | sourceText = initialSourceText
                , editRecord = MiniLatex.setup model.seed initialSourceText
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
    div []
        [ headerRibbon
        , editor model
        , renderedSource model
        , spacer 5
        , footerRibbon
        ]


parseResultsView model =
    div []
        [ headerRibbon
        , editor model
        , renderedSource model
        , showParseResult model
        , spacer 5
        , footerRibbon
        ]


rawHtmlResultsView model =
    div []
        [ headerRibbon
        , editor model
        , renderedSource model
        , showHtmlResult model
        , spacer 5
        , footerRibbon
        ]



{- VIEW FUNCTIONS -}


headerRibbon =
    div
        [ ribbonStyle "#555" ]
        [ span [ style [ ( "margin-left", "5px" ) ] ] [ text "MiniLatex Demo" ]
        , link "http://www.knode.io" "www.knode.io"
        ]


link url linkText =
    a
        [ class "linkback"
        , style
            [ ( "float", "right" )
            , ( "margin-right", "10px" )
            ]
        , href url
        , target "_blank"
        ]
        [ text linkText ]


footerRibbon =
    div
        [ ribbonStyle "#777" ]
        [ text "Fast render updates only those paragraphs which have changed."
        , link "http://jxxcarlson.github.io" "jxxcarlson.github.io"
        ]


editor model =
    div [ style [ ( "float", "left" ) ] ]
        [ spacer 20
        , buttonBarLeft
        , spacer 5
        , editorPane model
        ]


editorPane model =
    textarea [ editorStyle, onInput GetContent, value model.sourceText ] [ text model.sourceText ]


renderedSource model =
    div [ style [ ( "float", "left" ) ] ]
        [ spacer 20
        , buttonBarRight model
        , spacer 5
        , renderedSourcePane model
        ]


showParseResult model =
    div [ style [ ( "float", "left" ) ] ]
        [ spacer 20
        , buttonBarParserResults model
        , spacer 5
        , parseResultPane model
        ]


showHtmlResult model =
    div [ style [ ( "float", "left" ) ] ]
        [ spacer 20
        , buttonBarRawHtmlResults model
        , spacer 5
        , rawRenderedSourcePane model
        ]


prettyPrint : LineViewStyle -> List (List LatexExpression) -> String
prettyPrint lineViewStyle parseResult =
    case lineViewStyle of
        Vertical ->
            parseResult |> List.map toString |> List.map (String.Extra.replace " " "\n ") |> String.join "\n\n"

        Horizontal ->
            parseResult |> List.map toString |> String.join "\n\n"


parseResultPane model =
    pre
        [ parseResultsStyle ]
        [ text (prettyPrint model.lineViewStyle model.parseResult) ]


rawRenderedSourcePane model =
    let
        renderedText =
            MiniLatex.getRenderedText "" model.editRecord
    in
        pre
            [ parseResultsStyle ]
            [ text renderedText ]


renderedSourcePane model =
    let
        renderedText =
            MiniLatex.getRenderedText "" model.editRecord
    in
        div
            [ renderedSourceStyle
            , id "renderedText"
            , property "innerHTML" (Encode.string (Debug.log "RT" renderedText))
            ]
            []



{- Buttons -}


buttonBarLeft =
    div
        [ style [ ( "margin-left", "20px" ) ] ]
        [ resetButton 93
        , restoreButton 93
        , reRenderButton 93
        , fastRenderButton 96
        ]


buttonBarRight model =
    div
        [ style [ ( "margin-left", "20px" ) ] ]
        [ viewLabel "View" 80
        , standardViewButton model 108
        , parseResultsViewButton model 108
        , rawHtmlViewButton model 108
        ]


buttonBarRawHtmlResults model =
    div
        [ style [ ( "margin-left", "20px" ), ( "margin-top", "0" ) ] ]
        [ optionaViewTitleButton model 190 ]


buttonBarParserResults model =
    div
        [ style [ ( "margin-left", "20px" ), ( "margin-top", "0" ) ] ]
        [ optionaViewTitleButton model 190
        , setHorizontalViewButton model 90
        , setVerticalViewButton model 90
        ]


reRenderButton width =
    button [ onClick ReRender, buttonStyle colorBlue width ] [ text "Render" ]


fastRenderButton width =
    button [ onClick FastRender, buttonStyle colorBlue width ] [ text "Fast Render" ]


resetButton width =
    button [ onClick Reset, buttonStyle colorBlue width ] [ text "Clear" ]


restoreButton width =
    button [ onClick Restore, buttonStyle colorBlue width ] [ text "Restore" ]


setHorizontalViewButton model width =
    if model.lineViewStyle == Horizontal then
        button [ onClick SetHorizontalView, buttonStyle colorBlue width ] [ text "Horizontal" ]
    else
        button [ onClick SetHorizontalView, buttonStyle colorLight width ] [ text "Horizontal" ]


setVerticalViewButton model width =
    if model.lineViewStyle == Vertical then
        button [ onClick SetVerticalView, buttonStyle colorBlue width ] [ text "Vertical" ]
    else
        button [ onClick SetVerticalView, buttonStyle colorLight width ] [ text "Vertical" ]


standardViewButton model width =
    if model.configuration == StandardView then
        button [ onClick ShowStandardView, buttonStyle colorBlue width ] [ text "Basic" ]
    else
        button [ onClick ShowStandardView, buttonStyle colorLight width ] [ text "Basic" ]


parseResultsViewButton model width =
    if model.configuration == ParseResultsView then
        button [ onClick ShowParseResultsView, buttonStyle colorBlue width ] [ text "Parse Results" ]
    else
        button [ onClick ShowParseResultsView, buttonStyle colorLight width ] [ text "Parse Results" ]


rawHtmlViewButton model width =
    if model.configuration == RawHtmlView then
        button [ onClick ShowRawHtmlView, buttonStyle colorBlue width ] [ text "Raw Html" ]
    else
        button [ onClick ShowRawHtmlView, buttonStyle colorLight width ] [ text "Raw Html" ]


optionaViewTitleButton model width =
    case model.configuration of
        StandardView ->
            button [ buttonStyle colorDark width ] [ text "Basic" ]

        ParseResultsView ->
            button [ buttonStyle colorDark width ] [ text "Parse results" ]

        RawHtmlView ->
            button [ buttonStyle colorDark width ] [ text "Raw HTML" ]


viewLabel text_ width =
    button [ buttonStyle colorDark width ] [ text text_ ]



{- Elements -}


spacer n =
    div [ style [ ( "height", toString n ++ "px" ), ( "clear", "left" ) ] ] []


label text_ =
    p [ labelStyle ] [ text text_ ]



{- STYLE FUNCTIONS -}


ribbonStyle color =
    style
        [ ( "width", "835px" )
        , ( "height", "20px" )
        , ( "margin-left", "20px" )
        , ( "margin-bottom", "-16px" )
        , ( "padding", "8px" )
        , ( "clear", "left" )
        , ( "background-color", color )
        , ( "color", "#eee" )
        ]


colorBlue =
    "rgb(100,100,200)"


colorLight =
    "#88a"


colorDark =
    "#444"


buttonStyle : String -> Int -> Html.Attribute msg
buttonStyle color width =
    let
        realWidth =
            width + 0 |> toString |> \x -> x ++ "px"
    in
        style
            [ ( "backgroundColor", color )
            , ( "color", "white" )
            , ( "width", realWidth )
            , ( "height", "25px" )
            , ( "margin-right", "8px" )
            , ( "font-size", "9pt" )
            , ( "text-align", "center" )
            , ( "border", "none" )
            ]


labelStyle =
    style
        [ ( "margin-top", "5px" )
        , ( "margin-bottom", "0px" )
        , ( "margin-left", "20px" )
        , ( "font-style", "bold" )
        ]


editorStyle =
    textStyle "400px" "635px" "20px" "#eef"


renderedSourceStyle =
    textStyle "400px" "600px" "20px" "#eee"


parseResultsStyle =
    textStyle2 "400px" "600px" "20px" "#eee"


textStyle width height offset color =
    style
        [ ( "width", width )
        , ( "height", height )
        , ( "padding", "15px" )
        , ( "margin-left", offset )
        , ( "background-color", color )
        , ( "overflow", "scroll" )
        ]


textStyle2 width height offset color =
    style
        [ ( "width", width )
        , ( "height", height )
        , ( "padding", "15px" )
        , ( "margin-top", "0" )
        , ( "margin-left", offset )
        , ( "background-color", color )
        , ( "overflow", "scroll" )
        ]



{- Examples -}


initialSourceText =
    """
\\title{MiniLaTeX Demo}

\\author{James Carlson}

\\email{jxxcarlson at gmail}

\\date{November 13, 2017}

\\revision{January 16, 2018}

\\maketitle

\\tableofcontents

\\section{Introduction}

\\italic{This a MiniLatex test document.}
See the article
\\href{http://www.knode.io/#@public/559}{MiniLatex}
at \\href{http://www.knode.io}{www.knode.io} for more info.

Feel free to edit and re-render the text on the left.

\\section{Examples}

The Pythagorean Theorem, $a^2 + b^2 = c^2$,
is useful for computing distances.


Formula \\eqref{integral}
is one that you learned in Calculus class.

\\begin{equation}
\\label{integral}
\\int_0^1 x^n dx = \\frac{1}{n+1}
\\end{equation}

\\begin{theorem}
There are infinitely many primes, and
each satisfies $a^{p-1} \\equiv 1 \\text{ mod } p$, provided
that $p$ does not divide $a$.
\\end{theorem}

\\strong{Light Elements}
\\begin{tabular}{l l l l}
Hydrogen & H & 1 & 1.008 \\\\
Helium & He & 2 & 4.003 \\\\
Lithium & Li & 3 &  6.94 \\\\
Beryllium & Be & 4 & 9.012 \\\\
\\end{tabular}

\\image{http://psurl.s3.amazonaws.com/images/jc/propagator_t=2-6feb.png}{Free particle propagator}{width: 300, align: center}


Note that in the \\italic{source} of the listing below,
there are no line numbers.

\\strong{MiniLaTeX Abstract Syntax Tree (AST)}

\\begin{listing}
type LatexExpression
    = LXString String
    | Comment String
    | Item Int LatexExpression
    | InlineMath String
    | DisplayMath String
    | Macro String (List LatexExpression)
    | Environment String LatexExpression
    | LatexList (List LatexExpression)
\\end{listing}

The MiniLaTeX parser reads text and produces
an AST.  A rendering function converts the AST
into HTML.  One could easily write
functions \\code{render: LatexExpression -> String}
to make other conversions.

\\section{More about MiniLaTeX}

Articles and code:

\\begin{itemize}

\\item \\href{https://hackernoon.com/towards-latex-in-the-browser-2ff4d94a0c08}{Towards LaTeX in the Browser}

\\item \\href{https://github.com/jxxcarlson/minilatexDemo}{Code for the Demo App}

\\item \\href{http://package.elm-lang.org/packages/jxxcarlson/minilatex/latest}{The MiniLatex Elm Library}

\\end{itemize}

To try out MiniLatex for real, sign up for a free account at
 \\href{http://www.knode.io}{www.knode.io}.  The app is still
 under development &mdash;  we need people to test it and give feedback.
Contributions to help improve the open-source
MiniLatex Parser-Renderer are most welcome.
Here is the \\href{https://github.com/jxxcarlson/minilatex}{GitHub repository}.
The MiniLatex Demo as well as the app at knode.io are written in
\\href{http://elm-lang.org/}{Elm}.  We also plan a Haskell version.

Please send comments, bug reports, etc. to jxxcarlson at gmail.

\\section{Technical Note}
There is a \\italic{very rough} \\href{http://www.knode.io/#@public/628}{draft grammar}
for MiniLaTeX, written mostly in EBNF.  However, there are a few
productions, notably for enviroments, which are not context-free.
Recall that in a context-free grammar, all productions are
of the form $A \\Rightarrow \\beta$, where $A$ is a terminal symbol
and $\\beta$ is a sequence of terminals and nonterminals.  There
are some productions of the form $A\\beta \\Rightarrow \\gamma$,
where $\\beta$ is a terminal symbol.  These are
context-sensitive productions, with $\\beta$ providing the context.



\\section{Restrictions, Limitations, and Todos}

Below
are some of the current restrictions and limitations.

\\begin{enumerate}

\\item The enumerate and itemize environments cannot be nested (but can containe inline math and macros).

\\item The tabular environment ignores formatting information
and left-justifies everything in the cell.

\\item We plan to make the table of contents entries into live links
in the next few days.

\\end{enumerate}


We are working on these and other issues  to expand the scope of MiniLatex.
The project is still in the R&D phase -- we welcome comments (jxxcarlson at gmail)

\\bigskip

\\image{https://cdn-images-1.medium.com/max/1200/1*HlpVE5TFBUp17ua1AdiKpw.gif}{The way we used to do it.}{align: center}

"""
