
# MiniLaTeX


The MiniLatex package renders a subset of LaTeX to Html.  For a demo, see
[MiniLatex Live](https://jxxcarlson.github.io/app/miniLatexLive/index.htmll)
or [www.knode.io](http://www.knode.io).  There is a technical discussion in the
see the Hackernoon article, [Towards LaTeX in the Browser](https://hackernoon.com/towards-latex-in-the-browser-2ff4d94a0c08).

## Example

```
import MiniLatex
import MiniLatex.Render exposing(MathJaxRenderOption(..))


text = "Pythagoras says: $a^2 + b^2 = c^2$"

MiniLatex.render "" NoDelay text

```

See the code in `./example`

**NOTES.** The first parameter is `selectedId', used for highlighting
selected elements.  It can be left empty.  The second parameter
determines how MathJax renders text.  The third parameter is the 
source text.


For interactive editors and live rendering, you may want to use
the functions in `MiniLaTeX.Edit`. For an example of how this is 
done, see the code in `./demo`


## This release

- Added the exposed module `MiniLatex.EditSimple`. It is like
`MiniLatex.Edit`, except that it is record type that contains
no functions. This is need for Lamdera.


## Recent releases

- You have the option to render math-mode LaTeX using either
MathJax or KaTeX.  For now the latter is experimental, pending fixing
some bugs that affect the way KaTeX is used by the MiniLaTeX renderer.
See the README in the `examples` folder for more information.

- Eliminated `macros` as a parameter of `render`

- Added an `svg` environment.  See [demo.minilatex.app](https://demo.minilatex.app/)
for an example of how it is used.

- Changed `MiniLatex.Edit.get` so as to be able to 
highlight paragraphs in the rendered tex.  There are two 
parts to this.  First, when `get` retrieves rendered text
from a `Data` value, it adds click handlers to each paragraph.
When a paragraph is clicked, it sends the message `IDClicked id`,
where a typical `ID` is a string like "p.1.10", meaning paragaph 10,
version 1. The version of a paragraph is incremented when it is edited.
Second, a call to `MiniLatex.Edit.get` takes the form 
`get selectedId data`.  If the `selectedId` is found in the data,
the corresponding paragraph is highlighted.  The `get` function is
used in conjunction with a host app to synchronize source  and rendered text.

- Both math-mode and text-mode macros can be defined in the source text
using `\begin{mathmacro} ... \end{mathmacro}` and 
 `\begin{textmacro} ... \end{textmacro}`


- New method for using math-mode macros.  See
  [MiniLaTeX Demo](https://demo.minilatex.app/), section
  on math-mode macros.

- Added a **source map**. This is a dictionary whose
keys are pieces of source text and whose values are
the ids of the corresponding rendered text.  With a little
more work, this will allow one to have bidirectional
sync between source and rendered text: click on something
in one to bring the corresponding part of the
other into focus.

- Better LaTeX error reporting (to be still further improved).

- The below is used to optimize rendering by MathJax

        type MathJaxRenderOption = Delay | NoDelay
    
    This is necessitated by the single-threaded nature of Javascript.

## Acknowledgments
 

I wish to acknowledge the generous help that 
I have received throughout this project from 
the community at [elmlang.slack.com](http://elmlang.slack.com), with 
special thanks to Evan Czaplicki, Ilias van Peer, and
Luke Westby.  I  also wish to thank
 Davide Cervone (MathJax.org) for indispensible help
 with MathJax.
