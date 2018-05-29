
MeenyLaTeX
=========

MeenyLaTeX is an experimental version of MiniLatex,
which is in turn a subset of LaTeX that can be rendered
into pdf by standard tools such as `pdflatex` or
into HTML by a suitable application, e.g.,
<a href="https://jxxcarlson.github.io/app/minilatex/src/index.html">MiniLateX Demo</a>
or <a href="http://www.knode.io">www.knode.io</a>.  For a technical discussion,
see the Hackernoon article,
<a href="https://hackernoon.com/towards-latex-in-the-browser-2ff4d94a0c08">Towards LaTeX in the Browser</a>.

You can also experiment with the old MiniLaTeX using this <a href="https://ellie-app.com/3n2QNQdTMa1/1">Ellie</a>.  I will have an
Ellie version of MeenyLatex up soon.

Note:  The API will change substantially.  I've exposed much more than
is eventually needed in order to experiment better.


Basics
------

Example.  First, import MeenyLatex
```
> import MeenyLatex.Driver as MeenyLatex
```
Second, make these definitions
```
> text = "\\begin{itemize}\n\\item Eggs\n\\item Milk\n\\item Bread\n\\end{itemize}"
> macroDefinitions = ""
```
Third, run `MeenyLatex.render`;
```
> MeenyLatex.render macroDefinitions text
```
to get the HTML
```
"<p>\n \n<ul>\n <li class=\"item1\"> Eggs</li>\n <li class=\"item1\"> Milk</li>\n <li class=\"item1\"> Bread</li>\n\n</ul>\n\n</p>"
    : String
```
In this case, there are no macro definitions; the rendered text is
```
  <p>

  <ul>
   <li class="item1"> Eggs</li>
   <li class="item1"> Milk</li>
   <li class="item1"> Bread</li>

  </ul>

  </p>
```

API
---

If your applications simply renders strings of MeenyLatex
text to HTML, `Driver.renderMiniLatex` is all you
need from this package.  If you wish to do some
kind of live editing on a piece of text, there is a another,
slightly more complex method which involves the notion of
an `EditRecord`. An EditorRecord keeps track of various
types of information about the text being processed, e.g.,
a list of paragraphs and a list of rendered paragraphs.
When the document is changed, then rendered, the `update`
function figures out which paragraphs have changed, renders
them, and updates the list of rendered paragraphs accordingly.
Other optimizations for rendering equations by Mathjax require
a "random" integer seed.  Its role is explained in the documentation
of the `Differ` module.

An edit record record can be set up using `MeenyLatex.setup`.  
It is generally stored in the application model, e.g.,


```
seed = 1234
model.editRecord = MeenyLatex.setup seed text
```

At this point, `editRecord` contains a list of strings
representing paragraphs of the text, and another list of
strings representing those paragraphs rendered into HTML.

To extract the rendered text from the `EditRecord`, use

```
MeenyLatex.getRenderedText macroDefinitions editRecord
```

Here `macroDefinitions` is a string representing
macros that MathJax will use in rendering mathematical text.
Here is an example:
```
"""
  $$
  \def\bbR{\mathbb{Z}}
  \def\caP{\mathcal{P}}
  \newcommand{\bra}{\langle}
  \newcommand{\ket}{\rangle}
  \newcommand{\set}[1]{\{#1\}}
  \newcommand{\sett}[2]{\{ #1 | #2 \}}
  $$
"""
```
Note that the definitions are enclosed in double dollar signs.

To update the `EditRecord` with modified text, use

```
MeenyLatex.update seed editRecord text
```

The integer seed should be either chosen at random or
given sequentially.

In applications which make use of an `EditRecord` stored
in the model, you will need to initialize that data
structure.  For this use the 0-ary `emptyEditRecord` function,
e.g., `model.editRecord = emptyEditRecord`.

Summary
-------

To summarize, most work can be done with five points of contact
with the MeenyLatex API:

1. `MeenyLatex.render macroDefinitions text           : String`
2. `MeenyLatex.setup seed text                        : EditRecord`
3. `MeenyLatex.getRenderedText macroDefs editRecord   : String`
4. `MeenyLatex.update seed editRecord text            : EditRecord`
5. `MeenyLatex.emptyEditRecord                        : EditRecord`

The above assumes `import MeenyLatex.Driver as MeenyLatex`

Note to myself
--------------
On my laptop, this repository is in /Users/carlson/dev/apps/MeenyLatex


Acknowledgments
---------------  

I wish to acknowledge the generous help that I have received throughout this project from the community at http://elmlang.slack.com, with special thanks to Ilias van Peer (@ilias).
