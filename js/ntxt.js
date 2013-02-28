ntxt = {
    // Factory.
    fetchNtxt : function(url) {
      url = url || 'n.txt';
      var xmlr = new XMLHttpRequest();
      xmlr.open('GET', url, false);
      xmlr.send();
      return new ntxt.Ntxt(xmlr.responseText);
    }
};

// Block constructor
// ntxtObj the root Ntxt object.
// parentBlock the parent Block object.
// startTxt the starting offset in ntxtObj.text where this starts
// stopTxt the offset in ntxtObje.text after the startTxt position.
// The block of text submitted must be a valid block, meaning, it may
// ONLY contain subblocks.
ntxt.Block = function(ntxtObj, parentBlock, startTxt, stopTxt) {
    
    // Ensure that this function is only ever called as a constructor.
    if ( ! ( this instanceof ntxt.Block ) ) {
        return new ntxt.Block(ntxtObj);
    }
      
    this.children = [];         // child blocks.
    this.tags = [];             // all tags found in this block and children
    this.start = startTxt || 0;
    this.offset = stopTxt || ntxtObj.text.length;
    this.ntxt = ntxtObj;
    this.parent = parentBlock;

    // Set the indent to possibly non-zero if there is a parent block.
    if( this.parent ) {
        // Compute the indent of the first line of this Block.
        var re = /\s*\S/mg;
        re.lastIndex = this.start;      // set lastIndex
        if( re.test(ntxtObj.text) ) {  // move lastIndex over the whitespace.
          this.indent = re.lastIndex - this.start;
        } else {
          this.indent = 0;
        }
        this.parent.children.push(this);
    } else {
        this.indent = 0;
    }
};

(function(){
    // Add tags to this block and all parent blocks.
    this.addTag = function(tag) {
        this.tags.push(tag);
        
        if( this.parent ) {
            this.parent.addTag(tag);
        }
    }; // addTag

    // Call substring on the ntxt array and return the text for this block.
    this.text = function() {
        return this.ntxt.text.substr(this.start, this.offset);
    }; // text
      
    this.isRoot = function() { return this.parent };
      
    this.walk = function(f) {
        f(this);

        for ( c in this.children ) {
            this.children[c].walk(f);
        }
    };

    // Takes a function that takes:
    //   f(text, depth, node)
    this.walkText = function(printFunc, enterChild, exitChild) {
        this.walkTextHelper(printFunc, enterChild, exitChild, 0);
    };
      
    this.walkTextHelper = function(printFunc, enterChild, exitChild, depth) {

        enterChild(depth, this);
        
        if ( this.children.length == 0 ) {
            printFunc(this.text(), depth, this);
        } else {
      
            var prevEnd = this.start;
          
            for ( var c in this.children ) {
                var child = this.children[c];
                var start = prevEnd;
                var offset = child.start - start;
                printFunc(this.ntxt.text.substr(start, offset), depth, this);
                this.children[c].walkTextHelper(printFunc,
                                                enterChild,
                                                exitChild,
                                                depth+1);
                prevEnd = child.start + child.offset;
            }
          
            var lastChild = this.children[this.children.length-1];
            var start = lastChild.start + lastChild.offset;
            var offset = this.start + this.offset - start;

            printFunc(this.ntxt.text.substr(start, offset), depth, this);
        }
        
        exitChild(depth, this);
    }; // this.walkTextHelper
}).call(ntxt.Block.prototype);

// Ntxt Constructor.
ntxt.Ntxt = function(txt) {

    if ( ! ( this instanceof ntxt.Ntxt ) ) {
        return new ntxt.Ntxt(txt);
    }
    
    this.text = txt;
      
    this.rootBlock = (new ntxt.BlockParser).parse(this);

}; // Close Ntxt.
    

ntxt.State = function (lines, block, lineStart, start, lineEnd) {
    this.lines = lines;         // array of lines.
    this.block = block;         // context.
    this.lineStart = lineStart; // start of frame.
    this.line = lineStart;      // current line.
    this.lineEnd = lineEnd;     // end of frame.
    this.start = start;         // starting character
    this.offset = 0;            // current character offset from start.
}; // State

// ntxt.State definition.
(function(){
    this.currLine = function() {
        if (this.line < this.lineEnd && this.line >= this.lineStart) {
            return this.lines[this.line];
        } else {
            return undefined;
        } 
    };

    this.nextLine = function() {
        
        if (this.line >= this.lineEnd) {
            return undefined;
        } else {
            this.offset = this.offset + this.lines[this.line].length + 1;
            this.line = this.line + 1;
            return (this.line < this.lineEnd) ? this.lines[this.line] : undefined;
        }
    };

    this.prevLine = function() {
        if ( this.line < this.lineStart ) {
            return undefined;
        } else {
            var nLine = this.line - 1;
            this.offset = this.offset - this.lines[nLine].length - 1;
            this.line = nLine;
            return this.lines[nLine];
        }
    };
        
    // Shift our starting points to our current points. This
    // effectively consumes text.
    this.consume = function() {
        this.start = this.start + this.offset;
        this.offset = 0;
        this.lineStart = this.line;
    };
        
    this.toString = function() {
        return  "lineStart: "+this.lineStart+
                ", lineEnd: " +this.lineEnd+
                ", line: "+this.line+
                ", start: "+this.start+
                ", offset: "+this.offset;
    };
        
    // Seek this stat's position to the given state's position.
    this.seek = function(state) {
        this.line = state.line;
        this.offset = Math.abs(state.start + state.offset - this.start);
    };
}).call(ntxt.State.prototype);

ntxt.BlockParser = function() {
    this.stack = [] // stack of states to resume parsing
};

// ntxt.BlockParser definition.
(function(){

    var extractTags = function(block, line) {
        var re = /^\s*\[([^\[]+)\]/m;
        var m;
        while ( ( m = re.exec(line) ) ) {
            block.addTag(m[1]);
            line = line.substr(m[0].length);
        }
    };
      
    // Return an array of [ hlevel, and the text in the h level ] or null.
    var hlevel = function(line) {
        var m;
        if ( ( m = line.match( "^\\s*=([^=].*)=\\s*$") ) ) {
          return [ 1, m[1] ];
        } else if ( ( m = line.match("^\\s*==([^=].*)==\\s*$") ) ) {
          return [ 2, m[1] ];
        } else if ( ( m = line.match("^\\s*===([^=].*)===\\s*$") ) ) {
          return [ 3, m[1] ];
        } else if ( ( m = line.match("^\\s*====([^=].*)====\\s*$") ) ) {
          return [ 4, m[1] ];
        } else if ( ( m = line.match("^\\s*=====([^=].*)=====\\s*$") ) ) {
          return [ 5, m[1] ];
        } else if ( ( m = line.match("^\\s*======([^=].*)======\\s*$") ) ) {
          return [ 6, m[1] ];
        } else {
          return undefined;
        }
    }; // hlevel
      
    this.parseLines = function() {
        var state = this.stack[this.stack.length-1];

        var line = state.currLine();
        
        while (undefined != line){
        
            var tmp = hlevel(line);
        
            if ( tmp ) {
                state.consume();
                this.parseHlevel(parseInt(tmp[0]), tmp[1]);
                line = state.currLine();
            } else if ( ( tmp = line.match(/^(\s*)(\S.*)$/) ) ) {
                state.consume();
                this.parseIndent(tmp[1].length, tmp[2]);
                line = state.currLine();
            } else {
                line = state.nextLine();
            }
        }
    };

    // Parse a uniformly indented body of text.
    this.parseIndent = function(indentLevel, text) {
        var state = this.stack[this.stack.length-1];
        var line = state.currLine();
        
        // Build the block. Update the offset.
        var block = new ntxt.Block(state.block.ntxt, 
                                   state.block, 
                                   state.start, 
                                   state.offset);
                               
        // Position state at the end of the block.
        // Blocks are ended by empty lines or lines with = starting them.
        while ( line != undefined ) {
          
            if (hlevel(line))
                break;
              
            var m = line.match(/^(\s*)(..*)$/);
          
            // Found a header. Break.
            if ( m == undefined )
                break;
          
            var nextIndentLevel = m[1].length;
            var nextLine = m[2];
          
            // Higher level block. Break.
            if ( nextIndentLevel < indentLevel )
              break;

            if ( nextIndentLevel > indentLevel ) {
                // Advance to the next line after parsing a subblock
                var subState = new ntxt.State(
                    state.lines,
                    block,
                    state.line,
                    state.start + state.offset,
                    state.lineEnd);
            
                this.stack.push(subState);
                this.parseIndent(nextIndentLevel, nextLine);
                this.stack.pop();
                state.seek(subState);
                line = state.currLine();
            } else {
                // Advance to the next line. Indentation is equal.
                extractTags(block, line);
            
                line = state.nextLine();
            }
        } // while
        
        // Update the offset of the partially constructed block.
        block.offset = state.offset;
        state.consume();
      };

      // Consume an entier h-level block and build it.
      this.parseHlevel = function(level, title) {
          var state = this.stack[this.stack.length-1];
          var line = state.nextLine();
        
          while (line != null) {

              var hl = hlevel( line );
          
              if ( hl && parseInt(hl[0]) <= level )
                  break;           // We're done.
          
              line = state.nextLine();
          }
        
          var block = new ntxt.Block(
              state.block.ntxt, 
              state.block, 
              state.start, 
              state.offset);
          var subState = new ntxt.State(
              state.lines,
              block,
              state.lineStart + 1,
              state.start + state.lines[state.lineStart].length + 1,
              state.line);
        
          this.stack.push(subState);
          this.parseLines();
          this.stack.pop();
        
          state.consume();
      };

      // Helper that sets up the parseLines function
      this.parse = function(ntxtObj) {
      
          if ( !(  ntxtObj instanceof ntxt.Ntxt ) ) {
              ntxtObj = new ntxt.Ntxt(ntxtObj);
          }
        
          var lines = ntxtObj.text.split("\n");
        
          var rootBlock = new ntxt.Block(ntxtObj);
        
          this.stack = [ new ntxt.State( lines, rootBlock, 0, 0, lines.length ) ];

          this.parseLines();
        
          if ( this.stack.length == 1 ) {
              // parse success!
              return rootBlock;
          } else {
              // parse fail!
              return undefined;
          }
      };
}).call(ntxt.BlockParser.prototype);
  
