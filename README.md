# MeenyLaTeX

Parse and render a subset of LaTeX to Html. This is the MiniLaTeX compiler used
by [Scripta](https://x-scripta.app).

## Usage

`MiniLatex.API` is the entry point.

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

Each rendered paragraph carries `data-line` / `data-lines` attributes (its
source line range), for editor ↔ preview synchronization.

Math is emitted as `<math-text>` custom elements. The host page must define
`math-text` (Scripta's KaTeX-based definition is in `frontend/index.html`);
without it, math source is not typeset.

## Development

The source of truth is the vendored copy in the Scripta app
(`scripta-app-v4/frontend/minilatex/` and its MiniLaTeX tests). Changes are made
and tested there, then copied here with `scripts/sync-meenylatex.sh` in that
repository and published from this directory. Don't edit `src/` or `tests/` here
directly: the next sync overwrites them.

```bash
elm make --docs=docs.json   # build and check documentation
elm-test                    # run the tests (elm-test 0.19.2-0 for elm 0.19.2)
```
