// <math-text> custom element: typesets MiniLaTeX math with KaTeX.
//
// MiniLaTeX renders math as <math-text> and sets three properties on it:
// `content` (the TeX source), `display` (true for display math) and `delay`
// (a MathJax-era option, ignored here). Load KaTeX before this file, and this
// file before the Elm program, so the element is defined when Elm creates it.

class MathText extends HTMLElement {
  set content(value) { this._content = value; this.typeset(); }
  get content() { return this._content || ""; }

  set display(value) { this._display = value; this.typeset(); }
  get display() { return !!this._display; }

  set delay(_value) {}

  connectedCallback() { this.typeset(); }

  typeset() {
    if (!this.isConnected) return;
    katex.render(this.content, this, { displayMode: this.display, throwOnError: false });
  }
}

customElements.define("math-text", MathText);
