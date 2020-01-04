
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

For interactive editors and live rendering, you may want to use
the functions in `MiniLaTeX.Edit`. For an example of how this is 
done, see the code in `./demo`


## This release

    type MathJaxRenderOption = Delay | NoDelay
    
is used for optimizing rendering by MathJax

## Acknowledgments
 

I wish to acknowledge the generous help that 
I have received throughout this project from 
the community at http://elmlang.slack.com, with 
special thanks to Ilias van Peer (@ilias), 
Luke Westby (@luke), Davide Cervone (MathJax.org), and
Evan Czaplicki (@evancz).
