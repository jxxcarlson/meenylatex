
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

macros = "" -- your macro definitions

MiniLatex.render NoDelay macros text

```

See the code in `./example`

**NOTE:** (a) macro definitions can be either the empty 
string or a multiline string of definitions. (b)  With the
transition to MathJax 3, macro definitions are not working.
I will have a fix soon.


For interactive editors and live rendering, you may want to use
the functions in `MiniLaTeX.Edit`. For an example of how this is 
done, see the code in `./demo`


## This release

New method for using math-mode macros.  See
[MiniLaTeX Demo](https://demo.minilatex.app/), section
on math-mode macros.

## Recent releases

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
