module MiniLatex.Render exposing (MathJaxRenderOption(..))

{-| This module exports a type used to control rendering by MathJax v3

@docs MathJaxRenderOption

-}


{-| Values of this type are used to control rending by
MathJax v3. With the option NoDelay, the custom element
defined by assets/math-text.js is used and typesetting of
the text begins immediately. In the case of Delay,
assets/math-text-delatyed.js is used. Typesetting
begins after teh delay specified by the custom element.

The intent is to use Delay when loading a document.
NoDelay when editing it.

-}
type MathJaxRenderOption
    = Delay
    | NoDelay
