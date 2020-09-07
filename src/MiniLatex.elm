module MiniLatex exposing
    ( parse, render, renderWithSeed
    , LatexExpression, LatexState, emptyLatexState
    , TocEntry, TableOfContents
    )

{-| This library exposes functions for rendering MiniLaTeX text into HTML.
Most users will need only (1) the functions exposed in the `MiniLatex` module
and (2) `EditRecord`, which is exposed in the `Differ` module.

See [MiniLatex Live](https://jxxcarlson.github.io/app/miniLatexLive/index.html)
for a no-login demo of the MiniLatex technology. [Source code](https://github.com/jxxcarlson/MiniLatexLive)

See this [Hackernoon article](https://hackernoon.com/towards-latex-in-the-browser-2ff4d94a0c08)
for an explanation of the theory behind the MiniLatex package.


# API

@docs parse, render, renderWithSeed

@docs LatexExpression, LatexState, emptyLatexState

@docs TocEntry, TableOfContents

-}

import Html exposing (Html)
import Html.Attributes as HA
import Internal.LatexDiffer
import Internal.LatexState exposing (LatexState, emptyLatexState)
import Internal.Parser exposing (LatexExpression)
import Internal.Render as Render
import MiniLatex.Edit exposing (LaTeXMsg)
import MiniLatex.Render exposing (MathJaxRenderOption)


{-| Type of the syntax tree
-}
type alias LatexExpression =
    Internal.Parser.LatexExpression


{-| Auxiliary data compiled during parsing
-}
type alias LatexState =
    Internal.LatexState.LatexState


{-| Describes an entry in the table of contents
-}
type alias TocEntry =
    Internal.LatexState.TocEntry


{-| The table of contents
-}
type alias TableOfContents =
    Internal.LatexState.TableOfContents


{-| Used for initialization
-}
emptyLatexState : LatexState
emptyLatexState =
    Internal.LatexState.emptyLatexState


{-| parse a string of LaTeX text and return its syntax tree
-}
parse : String -> List LatexExpression
parse =
    Internal.Parser.parse


{-| The function call

    render "" NoDelay sourceTest

produces an HTML value corresponding to the given MiniLaTeX source text.
In this example, the first parameter is an id of an element
to be highlighted. It can be left empty. The second parameter, here
`noDelay`, defines the way that MathJax will go about typesetting
the content passed to it. Use `NoDelay` for
documents with not too many math elements and for
editing all documents, since only changed text is re-rendered.
Use `Delay` for loading document containing many
math elements.

-}
render : String -> String -> Html LaTeXMsg
render selectedId source =
    Internal.LatexDiffer.init
        Internal.Parser.parse
        (Render.renderLatexList source)
        emptyLatexState
        source
        |> MiniLatex.Edit.get selectedId
        |> Html.div [ HA.attribute "id" "__RENDERED_TEXT__" ]


{-| Like render, but used the `seed` to define the ids for each paragraph:

    render NoDelay seed macros sourceTest

-}
renderWithSeed :
    String
    -> Int
    -> String
    -> String
    -> Html LaTeXMsg
renderWithSeed selectedId seed macroDefinitions source =
    Internal.LatexDiffer.initWithSeed
        seed
        Internal.Parser.parse
        (Render.renderLatexList source)
        emptyLatexState
        (prependMacros macroDefinitions source)
        |> MiniLatex.Edit.get selectedId
        |> Html.div []


prependMacros macros_ sourceText =
    let
        macros =
            case macros_ == "" of
                True ->
                    "\\newcommand{\\dummy}{Dummy!}"

                _ ->
                    macros_
    in
    "$$\n" ++ String.trim macros_ ++ "\n$$\n\n" ++ sourceText
