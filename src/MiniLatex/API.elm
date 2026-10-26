module MiniLatex.API exposing
    ( LaTeXMsg, render
    , Data, parse, update, renderData, source
    , TocEntry, tableOfContents
    , toLaTeX, toLaTeXBody, images
    , toMarkdown
    )

{-| The public interface to MiniLaTeX: everything the frontend calls goes
through this module.

See this [Hackernoon article](https://hackernoon.com/towards-latex-in-the-browser-2ff4d94a0c08)
for an explanation of the theory behind the MiniLatex package.


# Rendering

@docs LaTeXMsg, render


# Parse once, update incrementally

@docs Data, parse, update, renderData, source


# Table of contents

@docs TocEntry, tableOfContents


# Export

@docs toLaTeX, toLaTeXBody, images


# Markdown

@docs toMarkdown

-}

import Html exposing (Html)
import Internal.Render
import MiniLatex.EditSimple
import MiniLatex.Export
import MiniLatex.Markdown


{-| Messages emitted by rendered MiniLaTeX (e.g. a paragraph was clicked).
-}
type alias LaTeXMsg =
    MiniLatex.EditSimple.LaTeXMsg


{-| A parsed MiniLaTeX document. Create it with `parse`, keep it in your model,
and refresh it with `update` when the source changes.
-}
type Data
    = Data { version : Int, record : MiniLatex.EditSimple.Data }


{-| Parse and render a MiniLaTeX source string. Each logical paragraph becomes
one element, carrying `data-line` / `data-lines` attributes for editor sync.
-}
render : String -> List (Html LaTeXMsg)
render =
    parse >> renderData


{-| Parse a MiniLaTeX source string.
-}
parse : String -> Data
parse text =
    Data { version = 1, record = MiniLatex.EditSimple.init 1 text Nothing }


{-| Bring `Data` up to date with new source text. Only the paragraphs that
changed are re-parsed.
-}
update : String -> Data -> Data
update text (Data d) =
    let
        version =
            d.version + 1
    in
    Data { version = version, record = MiniLatex.EditSimple.update version text Nothing d.record }


{-| Render parsed `Data`, with the same output as `render`.
-}
renderData : Data -> List (Html LaTeXMsg)
renderData (Data d) =
    MiniLatex.EditSimple.get "-" d.record


{-| The source text that `Data` was parsed from.
-}
source : Data -> String
source (Data d) =
    d.record.source


{-| One numbered heading: `level` is 1 for `\section`, 2 for `\subsection` and
3 for `\subsubsection`; `number` is its label, e.g. `"2.1"`; `id` is the DOM id
of the rendered heading, for links and scrolling.
-}
type alias TocEntry =
    { level : Int, number : String, title : String, id : String }


{-| The numbered headings of the document, in order.
-}
tableOfContents : Data -> List TocEntry
tableOfContents (Data d) =
    d.record.latexState.tableOfContents
        |> List.map
            (\e ->
                { level = e.level
                , number = e.label
                , title = String.join " " (String.words e.name)
                , id = Internal.Render.headingId e.level e.name
                }
            )


{-| Map MiniLaTeX source to a complete standard LaTeX document, ready for
xelatex: preamble, `\begin{document}`, body, `\end{document}`.
-}
toLaTeX : String -> String
toLaTeX =
    MiniLatex.Export.toLaTeX


{-| Map MiniLaTeX source to standard LaTeX: the document body only.
-}
toLaTeXBody : String -> String
toLaTeXBody =
    MiniLatex.Export.toLaTeXBody


{-| The images in MiniLaTeX source: each one's `url`, and the `filename` the
output of `toLaTeX` uses for it, as `image/<filename>`. Download the images
there before compiling.
-}
images : String -> List { url : String, filename : String }
images =
    MiniLatex.Export.images


{-| Convert MiniLaTeX source to Markdown: sections become headings, math stays
as `$...$` / `$$...$$`, and other macros and environments map to their nearest
Markdown equivalents.
-}
toMarkdown : String -> String
toMarkdown =
    MiniLatex.Markdown.convert
