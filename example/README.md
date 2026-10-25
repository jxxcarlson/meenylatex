# MiniLaTeX, simplest example

Renders the sample document in `src/Strings.elm` with `MiniLatex.API.render`.
It compiles the package straight from `../src` (see `source-directories` in
`elm.json`), so it always shows the current source, not the published version.

Requires elm 0.19.2.

```bash
cd example
elm make --optimize src/Main.elm --output=Main.js   # or ./make.sh
open index.html
```

`index.html` loads KaTeX from a CDN, then `assets/math-text.js`, which defines
the `<math-text>` element MiniLaTeX uses for math, then `Main.js`. It also sets
the `--paragraph-spacing` and `--indent` CSS variables the rendered output uses.
