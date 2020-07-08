class MathText extends HTMLElement {

   // The "set content" code below detects the
   // argument to the custom element
   // and is necessary for innerHTML
   // to receive the argument.
   set content(value) {
  		this.innerHTML = value
  	}

  connectedCallback() {
    console.log(this.innerHTML)
    this.attachShadow({mode: "open"});
    this.shadowRoot.innerHTML =
     katex.render(this.innerHTML, {
          throwOnError: false
      });


  }


}

customElements.define('math-text', MathText)

