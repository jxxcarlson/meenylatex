# Changelog

## 15.2.0 — 2026-10-26

- **Single spaces between words.** The parser captured each word together with its trailing
  spaces and then joined words with another space, doubling every gap in rendered Html, LaTeX
  export and Markdown. Words are now joined with nothing, so output keeps the source's spacing.
- **`MiniLatex.API.clickedParagraphId : LaTeXMsg -> String`**: which paragraph was clicked.
- The `MiniLatex.API` doc comment describes the package rather than Scripta's frontend.

## 15.1.1 — 2026-10-26

Lower minimum dependency versions (`elm/html` 1.0.0, `elm/json` 1.1.3, `elm-bidict` 2.0.1,
`list-extra` 8.3.0, `maybe-extra` 5.2.0, `elm-syntax-highlight` 3.4.0, `elm-svg-parser` 1.0.0).
15.0.0 and 15.1.0 had taken them from Scripta's versions, which blocked apps pinning older ones.
The code compiles with both sets.

## 15.1.0 — 2026-10-26

- **`MiniLatex.API.toMarkdown`**: convert MiniLaTeX to Markdown.
- Equation numbers sit 1em from the right edge.

## 15.0.0 — 2026-10-26

Breaking: the package exposes a single module, `MiniLatex.API`; `MiniLatex`, `MiniLatex.Edit`,
`MiniLatex.EditSimple`, `MiniLatex.Export` and `MiniLatex.Markdown` are no longer public.

- `MiniLatex.API`: `render`; `parse` / `update` / `renderData` / `source` (parse once, update
  only changed paragraphs); `tableOfContents`; `toLaTeX`, `toLaTeXBody`, `images`.
- `update` now refreshes the document state (table of contents, cross-references, macros);
  it used to keep the state from the first parse.
- Subsubsections are recorded at level 3; `\newcommand` definitions are kept in LaTeX export;
  verbatim, listing and verse keep blank lines and indentation.
- CSS variables `--paragraph-spacing` and `--indent` fall back to `0.85em` / `1.5em`.
- Unused upstream folders removed; README rewritten.
