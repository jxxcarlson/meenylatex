# MeenyLaTeX

Parse and render a subset of LaTeX to Html, and export it to standard LaTeX.
This is the MiniLaTeX compiler used by [Scripta](https://x-scripta.app).

The package exposes one module, `MiniLatex.API`.

## Rendering

```elm
import MiniLatex.API as API

-- One shot: parse and render.
view source =
    Html.div [] (API.render source)

-- Interactive editing: parse once, keep the Data in your model,
-- and update it as the source changes. Only changed paragraphs
-- are re-parsed.
init source =
    { data = API.parse source }

update newSource model =
    { model | data = API.update newSource model.data }

view model =
    Html.div [] (API.renderData model.data)
```

The rendered Html produces messages of type `API.LaTeXMsg` (a paragraph was
clicked); use `Html.map` to fit them into your own `Msg`, and
`API.clickedParagraphId` to read which paragraph it was.

Each rendered paragraph carries `data-line` / `data-lines` attributes (its
source line range), for editor ↔ preview synchronization.

## Table of contents

`API.tableOfContents data` lists the numbered headings (`\section`,
`\subsection`, `\subsubsection`) in order. Each entry has a `level` (1–3), a
`number` such as `"2.1"`, a `title`, and the `id` of the rendered heading, for
links and scrolling:

```elm
viewToc data =
    Html.ul []
        (API.tableOfContents data
            |> List.map
                (\entry ->
                    Html.li []
                        [ Html.a [ Html.Attributes.href ("#" ++ entry.id) ]
                            [ Html.text (entry.number ++ " " ++ entry.title) ]
                        ]
                )
        )
```

## Export to LaTeX

- `API.toLaTeX source` is a complete standard LaTeX document, with preamble,
  ready for `xelatex`.
- `API.toLaTeXBody source` is the body only, without the preamble.
- `API.images source` lists the document's images. The exported LaTeX refers
  to each one as `image/<filename>`; download each `url` to that path before
  compiling.

## Export to Markdown

`API.toMarkdown source` converts MiniLaTeX to Markdown: sections become
headings, math stays as `$...$` / `$$...$$`, and other macros and environments
map to their nearest Markdown equivalents.

## Math

Math is emitted as `<math-text>` custom elements, which the host page must
define. Without them, math source is not typeset. The example's
[`assets/math-text.js`](example/assets/math-text.js) defines `math-text` with
KaTeX: load KaTeX's script and stylesheet, then that file.

## CSS variables

The rendered Html takes two spacing values from CSS variables, so the host page
can match them to its own typography:

| Variable              | Used for                                              | Default  |
|-----------------------|-------------------------------------------------------|----------|
| `--paragraph-spacing` | space below each paragraph                            | `0.85em` |
| `--indent`            | left indent of lists and of `verbatim` blocks         | `1.5em`  |

Each has a fallback, the default above, so the output is laid out sensibly
without any setup. To change them, define them on an ancestor of the rendered
Html, for example:

```css
:root {
  --paragraph-spacing: 1em;
  --indent: 2em;
}
```

## Example

[`example/`](example) is a small app that renders a sample document through
`MiniLatex.API`. See its README for how to build and run it.

## Development

Develop and test here. `src/` is the package source, `tests/` its tests, and
`example/` compiles the package straight from `../src`, so it always shows the
current source.

```bash
elm make --docs=docs.json   # build and check documentation
elm-test                    # run the tests (elm-test 0.19.2-0 for elm 0.19.2)
```

To try a change inside an app before publishing, temporarily add this
directory's `src` to the app's `source-directories` and remove the package from
its dependencies.
