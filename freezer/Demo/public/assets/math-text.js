class MathText extends HTMLElement {


  connectedCallback() {
      const content_ =
        this.display
          ? '$$' + this.content + '$$'
          : '$' + this.content + '$' ;
      this.attachShadow({mode: "open"});
      this.shadowRoot.innerHTML =
          '<mjx-doc><mjx-head></mjx-head><mjx-body>' + content_ + '</mjx-body></mjx-doc>';
           MathJax.typesetShadow(this.shadowRoot)
  }
}

customElements.define('math-text', MathText)

