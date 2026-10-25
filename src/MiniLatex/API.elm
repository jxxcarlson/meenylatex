module MiniLatex.API exposing
    ( LaTeXMsg, render
    , Data, parse, update, renderData, source
    )

{-| The public interface to MiniLaTeX: everything the frontend calls goes
through this module.


# Rendering

@docs LaTeXMsg, render


# Parse once, update incrementally

@docs Data, parse, update, renderData, source

-}

import Html exposing (Html)
import MiniLatex.EditSimple


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
