class MathText extends HTMLElement {


   // The "set content" code below detects the
   // argument to the custom element
   // and is necessary for innerHTML
   // to receive the argument.
//   set content(value) {
//        console.log('katex set content', value )
//  		this.innerHTML = value
//  	}

   get content(value) {
          console.log('katex get content', value )
    		this.source = value
    	}

  connectedCallback() {
    console.log('katex connectedCallback (1)',this.innerHTML );
    console.log('katex connectedCallback (2)',this.source );

    this.attachShadow({mode: "open"});
    this.shadowRoot.innerHTML = document.head.katexJs.renderToString(source, {
                                    throwOnError: false
                                });
  }


}

customElements.define('math-text', MathText)

