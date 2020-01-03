module MiniLatex
    exposing
        ( render
        , renderWithSeed
        , emptyLatexState
        , LatexState
        , TocEntry
        , TableOfContents
        )

{-| This library exposes functions for rendering MiniLaTeX text into HTML.
Most users will need only (1) the functions exposed in the `MiniLatex` module
and (2) `EditRecord`, which is exposed in the `Differ` module.

See [MiniLatex Live](https://jxxcarlson.github.io/app/miniLatexLive/index.html)
for a no-login demo of the MiniLatex technology. [Source code](https://github.com/jxxcarlson/MiniLatexLive)

See this [Hackernoon article](https://hackernoon.com/towards-latex-in-the-browser-2ff4d94a0c08)
for an explanation of the theory behind the MiniLatex package.


# API

@docs render, renderWithSeed

@docs LatexState, TocEntry, TableOfContents

@docs emptyLatexState

-}

import Html exposing (Html)

import Internal.LatexDiffer as MiniLatexDiffer
import Internal.LatexState exposing (LatexState, emptyLatexState)
import Internal.Render2 as Render
import MiniLatex.Edit

{-| Auxiliary data compiled during parsing -}
type alias LatexState = Internal.LatexState.LatexState


{-| Describes an entry in the table of contents -}
type alias TocEntry = Internal.LatexState.TocEntry


{-| The table of contents -}
type alias TableOfContents = Internal.LatexState.TableOfContents


{-| Used for initialization -}
emptyLatexState : LatexState
emptyLatexState = Internal.LatexState.emptyLatexState

{-| The function call `render macros sourceTest` produces
an HTML element or Html msg value corresponding to the MiniLatex source text
`sourceText`. The macro definitions in `macros`
are prepended to this string and are used by MathJax
to render purely mathematical text. The `macros` string
may be empty.
-}
render : Bool -> String -> String -> Html msg
render delay macroDefinitions source =
    MiniLatexDiffer.init (Render.renderLatexList delay source) emptyLatexState (prependMacros macroDefinitions source)
        |> MiniLatex.Edit.get
        |> Html.div []


{-| Like render, but used the `seed` to define the ids for each paragraph.
-}
renderWithSeed : Bool -> Int -> String -> String -> Html msg
renderWithSeed delay seed macroDefinitions source =
    MiniLatexDiffer.initWithSeed seed (Render.renderLatexList delay source) emptyLatexState (prependMacros macroDefinitions source)
        |> MiniLatex.Edit.get
        |> Html.div []


prependMacros macros_ sourceText =
    "$$\n" ++ String.trim macros_ ++ "\n$$\n\n" ++ sourceText


