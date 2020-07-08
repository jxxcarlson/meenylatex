  const init =  async function(app) {

  console.log("I am starting elm-katex: init");
  var katexJs = document.createElement('script')
  katexJs.type = 'text/javascript'
  katexJs.src = "https://cdn.jsdelivr.net/npm/katex@0.11.1/dist/katex.min.js"

  document.head.appendChild(katexJs);
  console.log("elm-katex: I have appended katexJs to document.head");

}


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
    this.shadowRoot.innerHTML = document.head.katexJs.katex.renderToString("a^3 + b^3 = c^3", {
                                    throwOnError: false
                                });
  }


}

customElements.define('math-text', MathText)
