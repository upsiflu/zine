import '../js/squire-raw.js'

/** @typedef {{load: (Promise<unknown>); flags: (unknown)}} ElmPagesInit */

/** @type ElmPagesInit */
export default {
  load: async function (elmLoaded) {
    const app = await elmLoaded;
  },
  flags: function () {
    return "You can decode this in Shared.elm using Json.Decode.string!";
  },
};

/* Squire-specific functions (Hypertext editing and formatting)
*/

Squire.prototype.replaceBlockWith = function(tag) {
  this.modifyBlocks(frag => {
      var output = this._doc.createDocumentFragment();
      var block = frag;
      while (block = Squire.getNextBlock(block)) {
          output.appendChild(
              this.createElement(tag, [Squire.empty(block)])
          );
      }
      return output;
  });
}



/* A custom Element hides the state of the editor (Squire) from Elm's vDOM differ.
* reference: https://guide.elm-lang.org/interop/custom_elements.html
*/

customElements.define('custom-editor',
  class extends HTMLElement {
      // required by Custom Elements 
      constructor() {
          super();

          this.field = document.createElement("article");

          this.squire = new Squire(this.field, {
              blockTag: 'p'
          });
          this.preview = document.createElement("article");

          this.squire.addEventListener("pathChange", e => {
              let caret = new CustomEvent("caret", {
                  detail: {
                      caret: ["b", "strong", "i", "emph", "h1", "h2", "h3", "h4", "p", "div", "ul", "ol", "li", "a"]
                        .filter(f => this.squire.hasFormat(f)),
                      id: this.id
                  }
              });
              this.dispatchEvent(caret);
          })

          this.squire.addEventListener("input", e => {
              let draft = new CustomEvent("draft", {
                  detail: {
                      draft: this.draft,
                      id: this.id
                  }
              });
              this.dispatchEvent(draft);
          })
      }

      static get observedAttributes() {
          return ['release', 'caret', 'id', 'state', 'format'];
      }

      connectedCallback() {
          //this.reflectState("connected callback", this.id);

      }
      disconnectedCallback() {
          console.log ("-------", this.id, "was disconnected from the DOM")
          //this.innerHTML = "";
      }
      attributeChangedCallback(attr, oldVal, newVal) {
        console.log ("-------", this.id, "changed", attr, "from", oldVal, "to", newVal)
          let doCommand = (command) => {
              switch (command) {
                  case "increaseLevel":
                      if (this.squire.hasFormat('LI'))
                          this.squire.increaseListLevel();
                      else this.squire.increaseQuoteLevel();
                      break;
                  case "decreaseLevel":
                      if (this.squire.hasFormat('LI'))
                          this.squire.decreaseListLevel();
                      else this.squire.decreaseQuoteLevel();
                      break;
                  case "makeUnorderedList":
                      this.squire.makeUnorderedList();
                      break;
                  case "makeOrderedList":
                      this.squire.makeOrderedList();
                      break;
                  case "removeList":
                      this.squire.removeList();
                      break;
                  case "makeTitle":
                      this.squire.replaceBlockWith('h1');
                      break;
                  case "makeHeader":
                      this.squire.replaceBlockWith('h2');
                      break;
                  case "makeSubheader":
                      this.squire.replaceBlockWith('h3');
                      break;
                  case "removeHeader":
                      this.squire.replaceBlockWith('p');
                      break;
                  case "bold":
                      this.squire.bold();
                      break;
                  case "removeBold":
                      this.squire.removeBold();
                      break;
                  case "italic":
                      this.squire.italic();
                      break;
                  case "removeItalic":
                      this.squire.removeItalic();
                      break;
                  case "undo":
                      this.squire.undo();
                      break;
                  case "redo":
                      this.squire.redo();
                      break;
                  case "removeAllFormatting":
                      this.squire.removeAllFormatting();
                      break;
              }
              this.squire.focus();
          };


          switch (attr) {
              case 'state':
                  this.reflectState('state changed');
                  break;
              case 'release':
                  console.log (this.getAttribute('state'));
                  if (this.getAttribute('state') === "done")
                    this.preview.innerHTML = newVal;
                  else if (this.squire) this.squire.setHTML(newVal);
                  break;
              case 'format':
                  if (newVal != "") doCommand(newVal);
          }
      }
      reflectState(origin) {
          console.log("____________________________________")
          console.log(origin)
          console.log("state:", this.getAttribute('state'))
          console.log("release:", this.getAttribute('release'))
          
          if (this.hasAttribute('state') && this.getAttribute('state') == 'editing') {
              if (this.contains(this.preview)) this.removeChild(this.preview);
              if (!this.contains(this.field)) this.appendChild(this.field);
          } else {
              if (this.contains(this.field))
                  this.removeChild(this.field);
              if (this.preview && !this.contains(this.preview)) {
                  if (this.hasAttribute("release"))
                      this.preview.innerHTML = this.getAttribute("release");
                  this.appendChild(this.preview);
              }
          }
          
      }
      get draft() {
          return this.squire.getHTML();
      }
      set draft(val) {
          this.squire.setHTML(val);
      }
  }
)
