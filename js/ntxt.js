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

/**
 * Block constructor
 * ntxtObj the root Ntxt object.
 * parentBlock the parent Block object.
 * startTxt the starting offset in ntxtObj.text where this starts
 * stopTxt the offset in ntxtObje.text after the startTxt position.
 *
 * The block of text submitted must be a valid block, meaning, it may
 * ONLY contain subblocks.
 *
 * A Block contains the members:
 *   - children - a list of child blocks.
 *   - tags - a list of tags.
 *   - start - the index to the block's text start.
 *   - offset - the length of the block of text from start.
 *   - ntxt - the NTxt object containing the text.
 *   - header - the header level. 0 is no header. 1-6 are valid levels.
 *   - indent - the indentation of this block's text, if any. 0 if none.
 *   - parent - the parent block, if any.
 */
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
    this.header = 0;
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
      
    this.rootBlock = (new ntxt.BlockParser()).parse(this);

}; // Close Ntxt.
    
ntxt.BlockParser = function() {
};

// ntxt.BlockParser definition.
(function(){

    /**
     * Pull tags out of a line.
     */
    this.extractTags = function(){
        var line = this.lines[this.currentLine];
        var re = /^\s*\[([^\[]+)\]/m;
        var m;
        while ( ( m = re.exec(line) ) ) {
            this.currentBlock.addTag(m[1]);
            line = line.substr(m[0].length);
        }
    };
      
    // Return an array of [ hlevel, text, linecount (1 or 2) ] or undefined.
    this.hlevel = function() {
        var line = this.lines[this.currentLine];
        var nextLine;

        if (this.lines.length > this.currentLine+1) {
            nextLine = this.lines[this.currentLine+1];
        } else {
            nextLine = undefined;
        }

        var m;
        if ( ( m = line.match( "^\\s*=([^=].*)=\\s*$") ) ) {
          return [ 1, m[1], 1 ];
        } else if ( ( m = line.match("^\\s*==([^=].*)==\\s*$") ) ) {
          return [ 2, m[1], 1 ];
        } else if ( ( m = line.match("^\\s*===([^=].*)===\\s*$") ) ) {
          return [ 3, m[1], 1 ];
        } else if ( ( m = line.match("^\\s*====([^=].*)====\\s*$") ) ) {
          return [ 4, m[1], 1 ];
        } else if ( ( m = line.match("^\\s*=====([^=].*)=====\\s*$") ) ) {
          return [ 5, m[1], 1 ];
        } else if ( ( m = line.match("^\\s*======([^=].*)======\\s*$") ) ) {
          return [ 6, m[1], 1 ];
        } else if ( ( m = line.match("^\\s*#\\s*(.*)$")) ) {
          return [ 1, m[1], 1 ];
        } else if ( ( m = line.match("^\\s*##\\s*(.*)$")) ) {
          return [ 2, m[1], 1 ];
        } else if ( ( m = line.match("^\\s*###\\s*(.*)$")) ) {
          return [ 3, m[1], 1 ];
        } else if ( ( m = line.match("^\\s*####\\s*(.*)$")) ) {
          return [ 4, m[1], 1 ];
        } else if ( ( m = line.match("^\\s*#####\\s*(.*)$")) ) {
          return [ 5, m[1], 1 ];
        } else if ( ( m = line.match("^\\s*######\\s*(.*)$") ) ) {
          return [ 6, m[1], 1 ];
        } else if ( !! nextLine && (m = nextLine.match("^\\s*==+\\s*$") ) ) {
          return [ 1, line, 2 ];
        } else if ( !! nextLine && (m = nextLine.match("^\\s*--+\\s*$") ) ) {
          return [ 2, line, 2 ];
        } else {
          return undefined;
        }
    }; // hlevel

    this.computeIndent = function(){
        var m = this.lines[this.currentLine].match("^(\\s*).*$");
        return m[1].length;
    };

    this.closeBlock = function()
    {
        this.currentBlock.offset =
            this.currentOffset - this.currentBlock.start-1;
        this.currentBlock = this.currentBlock.parent;
    }
      
    /**
     * Called by parse.
     * This does the parsing of this.lines.
     */
    this.parseLines = function() {
        while(this.currentLine < this.lines.length) {

            this.extractTags();

            // Check if there is an header.
            var hlevel = this.hlevel();

            // If there is a header, create a block for it.
            if (hlevel) {

                // While header > hlevel[0], close the current block.
                while (this.currentBlock.header >= hlevel[0]) {
                    this.closeBlock();
                }

                this.currentBlock = new ntxt.Block(
                    this.currentBlock.ntxt,
                    this.currentBlock,
                    this.currentOffset);
                this.currentBlock.header = hlevel[0];

                for (var i = 0; i < hlevel[2]; ++i) {
                    this.nextLine();
                }

                this.currentIndent = 0;

                continue;
            }

            var indent = this.computeIndent();
            if (indent < this.currentIndent) {
                this.closeBlock();
                this.currentIndent = indent;
            } else if (indent > this.currentIndent) {
                this.currentBlock = new ntxt.Block(
                    this.currentBlock.ntxt,
                    this.currentBlock,
                    this.currentOffset);
                this.currentBlock.indent = indent;
                this.currentIndent = indent;
            }

            this.nextLine();
        }

        while ( ! this.currentBlock.isRoot()) {
            this.closeBlock();
        }
    };

    this.nextLine = function()
    {
        // +1 for the split-on \n character.
        this.currentOffset += this.lines[this.currentLine].length + 1;
        this.currentLine += 1;
    }

    // Helper that sets up the parseLines function
    this.parse = function(ntxtObj) {
      
        if ( !(  ntxtObj instanceof ntxt.Ntxt ) ) {
            ntxtObj = new ntxt.Ntxt(ntxtObj);
        }
       
        var rootBlock = new ntxt.Block(ntxtObj);

        //this.stack = [];
        this.lines = ntxtObj.text.split("\n");
        this.currentLine = 0;
        this.currentOffset = 0;
        this.currentIndent = 0;
        this.currentBlock = rootBlock;

        this.parseLines();
        
        return rootBlock;
    };
}).call(ntxt.BlockParser.prototype);
  
