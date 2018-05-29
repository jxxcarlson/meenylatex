
MeenyLaTeX
=========

MeenyLaTeX is an experimental version of MiniLatex,
which is in turn a subset of LaTeX that can be rendered
into pdf by standard tools such as `pdflatex` or
into HTML by a suitable application, e.g.,
[MiniLatex Demo](https://jxxcarlson.github.io/app/minilatex/src/index.html)
or [www.knode.io](http://www.knode.io)  For a technical discussion,
see the Hackernoon article, [Towards LaTeX in the Browser](https://hackernoon.com/towards-latex-in-the-browser-2ff4d94a0c08).

You can also experiment with the old MiniLaTeX using this
[Ellie](https://ellie-app.com/jNN8tyQdh2a1)  I will have an
Ellie version of MeenyLatex up soon.  For now, the best way
to test this package is with the demo app in `./demo`.
Better docs soon!

This new version renders LaTeX source text into `Html a` rather than
`String` representing Html.  The new
`Driver` module uses this renderer as does the demo app.  There is
also a major change in the way MathJax is called to render formulas.
Rather than use ports, one now uses custom elements courtesy of @luke.

I will also re-expose a `Driver` module which uses the `String` renderer.
This is needed for printing.

Note:  Since this is the experimental version,
the API may change (and be cleaned up) substantially.  
I've exposed much more than
is eventually needed in order to experiment better.



Note to myself
--------------
On my laptop, this repository is in /Users/carlson/dev/apps/MeenyLatex


Acknowledgments
---------------  

I wish to acknowledge the generous help that I have received throughout this project from the community at http://elmlang.slack.com, with special thanks to Ilias van Peer (@ilias), Luke Westby (@luke), and
Evan Czaplicki (@evancz).
