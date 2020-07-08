class MathText extends HTMLElement {


   // The "set content" code below detects the
   // argument to the custom element
   // and is necessary for innerHTML
   // to receive the argument.
   set content(value) {
        console.log('katex set content', value )
  		this.innerHTML = value
  	}

  connectedCallback() {
    console.log('katex connectedCallback',this.innerHTML )
    this.attachShadow({mode: "open"});
    this.shadowRoot.innerHTML = document.head.katexJs.renderToString("c = \\pm\\sqrt{a^2 + b^2}", {
                                    throwOnError: false
                                });
  }


}

customElements.define('math-text', MathText)

