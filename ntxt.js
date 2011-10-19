  
  ntxt = {
    Exception : function(msg, obj) {
      if ( ! ( this instanceof ntxt.Exception ) ) {
        return new ntxt.Exception(msg, obj)
      }
      this.message = msg
      this.object = obj
    },
    
    BlockParser : function() {
      var parser = this
      parser.stack = [] // stack of states to resume parsing
      
      function State(lines, block, lineStart, start, lineEnd) {
        this.lines = lines          // array of lines.
        this.block = block          // context.
        this.lineStart = lineStart  // start of frame.
        this.lineEnd = lineEnd      // end of frame.
        this.line = lineStart       // current line.
        this.start = start          // starting character
        this.offset = 0        // current character offset from start.
        this.currLine = function() { return this.lines[this.line] }
        this.nextLine = function() {
          var nextLine = this.line + 1
          if ( nextLine < this.lineEnd ) {
            var nextOffset = this.offset + this.lines[this.line].length + 1
            this.offset = nextOffset
            this.line = nextLine
            return this.lines[nextLine]
          } else { 
            return null
          }
        }
        this.prevLine = function() {
          var nextLine = this.line - 1
          if ( nextLine >= this.lineStart ) {
            var nextOffset = this.offset - this.lines[nextLine].length - 1
            this.offset = nextOffset
            this.line = nextLine
            return this.lines[nextLine]
          } else { 
            return null
          }
        }
        
        // Shift our starting points to our current points. This
        // effectively consumes text.
        this.consume = function() {
          this.start = this.start + this.offset
          this.offset = 0
          this.lineStart = this.line
        }
        
        // Create a new state that is framed from the lineStart+1 of this state
        // and ends at the current line of the given state.
        this.lowerSubState = function() {
          var endOfFrame = this.line+1  
          
          if ( endOfFrame > this.lineEnd ) {
            endOfFrame = this.lineEnd
          }
          
          // function State(lines, block, lineStart, start, lineEnd) {
          var s = new State( this.lines,
                             this.block,
                             this.lineStart+1,
                             this.start+this.lines[this.lineStart].length+1,
                             endOfFrame )
                             
          return s            
        }
        
        // Create a new state that is framed with the remaining contents of 
        // this state.
        this.upperSubState = function() {
          var s = new State( this.lines,
                             this.block,
                             this.line,
                             this.start + this.offset,
                             this.lineEnd )
          return s
        }
        
        this.toString = function() {
          return  "lineStart: "+this.lineStart+
                  ", lineEnd: " +this.lineEnd+
                  ", line: "+this.line+
                  ", start: "+this.start+
                  ", offset: "+this.offset
        }
        
        // Seek this stat's position to the given state's position.
        this.seek = function(state) {
          this.line = state.line
          this.offset = Math.abs(state.start + state.offset - this.start)
        }
      } // State
      
      // Return an array of [ hlevel, and the text in the h level ] or null.
      function hlevel(line) {
        var m
        if ( ( m = line.match( "^\\s*=([^=].*)=\\s*$") ) ) {
          return [ 1, m[1] ]
        } else if ( ( m = line.match("^\\s*==([^=].*)==\\s*$") ) ) {
          return [ 2, m[1] ]
        } else if ( ( m = line.match("^\\s*===([^=].*)===\\s*$") ) ) {
          return [ 3, m[1] ]
        } else if ( ( m = line.match("^\\s*====([^=].*)====\\s*$") ) ) {
          return [ 4, m[1] ]
        } else if ( ( m = line.match("^\\s*=====([^=].*)=====\\s*$") ) ) {
          return [ 5, m[1] ]
        } else if ( ( m = line.match("^\\s*======([^=].*)======\\s*$") ) ) {
          return [ 6, m[1] ]
        } else {
          return null
        }
      } // hlevel
      
      function extractTags(block, line) {
        var re = /^\s*\[([^\[]+)\]/m
        var m
        while ( ( m = re.exec(line) ) ) {
          block.addTag(m[1])
          line = line.substr(m[0].length)
        }
      }
      
      // Helper that sets up the parseLines function
      parser.parse = function(ntxtObj) {
      
        if ( !(  ntxtObj instanceof ntxt.Ntxt ) ) {
          ntxtObj = new ntxt.Ntxt(ntxtObj)
        }
        
        var lines = ntxtObj.text.split("\n")
        
        var rootBlock = new ntxt.Block(ntxtObj)
        
        this.stack = [ new State( lines, rootBlock, 0, 0, lines.length ) ]

        this.parseLines()
        
        if ( this.stack.length == 1 ) {
          // parse success!
          return rootBlock
        } else {
          // parse fail!
          return null
        }
      }

      // Consume an entier h-level block and build it.
      parser.parseHlevel = function(level, title) {
        var state = this.stack[this.stack.length-1]
        var line;
        var subState
        var block
        do {
          line = state.nextLine()
          
          if ( line ) {
            var hl = hlevel( line )
            if ( hl && parseInt(hl[0]) <= level ) {
              state.prevLine() // rewind
              break;           // we're done.
            }
          }
          
        } while (line!=null);
        
        block = new ntxt.Block(state.block.ntxt, 
                               state.block, 
                               state.start, 
                               state.offset)
        block.title = title
        subState = state.lowerSubState()
        subState.block = block
        this.stack.push(subState)
        this.parseLines()
        this.stack.pop()
        state.consume()        
        
      }
      
      // Parse a uniformly indented body of text.
      parser.parseIndent = function(indentLevel, text) {
        var state = this.stack[this.stack.length-1]
        var subState
        var nextIndentLevel
        var block
        var line = state.currLine()
        
        // Build the block. Update the offset.
        block = new ntxt.Block(state.block.ntxt, 
                               state.block, 
                               state.start, 
                               state.offset)
                               
        // Position state at the end of the block.
        // Blocks are ended by empty lines or lines with = starting them.
        while ( line != null ) {
          
          if ( line == null ) {
            break
          }
          
          var m = line.match(/^(\s*)([^=\s].*)$/)
          
          if ( m == null ) {
            break
          }
          
          nextIndentLevel = m[1].length
          
          if ( nextIndentLevel < indentLevel ) {
            state.prevLine()
            break;
          } else if ( nextIndentLevel > indentLevel ) {
            subState = state.upperSubState()
            subState.block = block
            this.stack.push(subState)
            this.parseIndent( nextIndentLevel, m[2] )
            this.stack.pop()
            state.seek(subState)
          }
          
          extractTags(block, line)
          
          line = state.nextLine()
          
        } // while
        
        // Update the offset.
        block.offset = state.offset        
        state.consume()
        
      }
      
      parser.parseLines = function() {
        var state = this.stack[this.stack.length-1]
        state.block.children = []

        var tmp
        var line = state.currLine()
        
        while (null != line){
        
          if ( ( tmp =  hlevel( line ) ) ) {
          
            state.consume()
            parser.parseHlevel(parseInt(tmp[0]), tmp[1])

          } else if ( ( tmp = line.match(/^(\s*)(\S.*)$/) ) ) {

            state.consume()
            parser.parseIndent(tmp[1].length, tmp[2])
            
          }

          line = state.nextLine()
        }
        
      }
      

    },
  
    // Block constructor
    // ntxtObj the root Ntxt object.
    // parentBlock the parent Block object.
    // startTxt the starting offset in ntxtObj.text where this starts
    // stopTxt the offset in ntxtObje.text after the startTxt position.
    // The block of text submitted must be a valid block, meaning, it may
    // ONLY contain subblocks.
    Block : function(ntxtObj, parentBlock, startTxt, stopTxt) {
    
      // Ensure that this function is only ever called as a constructor.
      if ( ! ( this instanceof ntxt.Block ) ) {
        return new ntxt.Block(ntxtObj)
      }

      // Process sub-blocks if any...
      var block = this
      
      block.children = []         // child blocks.
      block.tags = []             // all tags found in this block and children
      block.start = startTxt || 0
      block.offset = stopTxt || ntxtObj.text.length
      block.ntxt = ntxtObj
      block.parent = parentBlock

      // Set the indent to possibly non-zero if there is a parent block.
      if( block.parent ) {
        // Compute the indent of the first line of this Block.
        var re = /\s*\S/mg
        re.lastIndex = block.start      // set lastIndex
        if( re.test(ntxtObj.text) ) {  // move lastIndex over the whitespace.
          block.indent = re.lastIndex - block.start
        } else {
          block.indent = 0
        }
        block.parent.children.push(this)
      } else {
        block.indent = 0
      }
      
      // Add tags to this block and all parent blocks.
      block.addTag = function(tag) {
        this.tags.push(tag)
        
        if( this.parent ) {
          this.parent.addTag(tag)
        }
      } // addTag
      
      // Call substring on the ntxt array and return the text for this block.
      block.text = function() {
        return this.ntxt.text.substr(this.start, this.offset)
      } // text
      
      block.isRoot = function() { return this.parent }
      
      block.walk = function(f) {
        f(this)

        for ( c in this.children ) {
          this.children[c].walk(f)
        }
      }
      
      // Takes a function that takes:
      //   f(text, depth, node)
      block.walkText = function(printFunc, enterChild, exitChild) {
        this.walkTextHelper(printFunc, enterChild, exitChild, 0)
      }
      
      block.walkTextHelper = function(printFunc, enterChild, exitChild, depth) {

        enterChild(depth, this);
        
        if ( this.children.length == 0 ) {
          printFunc( this.text(), depth, this )
        } else {
      
          var prevEnd = this.start
          
          for ( var c in this.children ) {
            var child = this.children[c]
            var start = prevEnd
            var offset = child.start - start
            printFunc(this.ntxt.text.substr(start, offset), depth, this)
            this.children[c].walkTextHelper(printFunc,
                                            enterChild,
                                            exitChild,
                                            depth+1)
            prevEnd = child.start + child.offset
          }
          
          var lastChild = this.children[this.children.length-1]
          var start = lastChild.start + lastChild.offset
          var offset = this.start + this.offset - start
          
          printFunc(this.ntxt.text.substr(start, offset), depth, this)
        }
        
        exitChild(depth, this);

      }
      
    },
  
    // Ntxt Constructor.
    Ntxt : function(txt) {

      if ( ! ( this instanceof ntxt.Ntxt ) ) {
        return new ntxt.Ntxt(txt);
      }
    
      this.text = txt
      
      this.rootBlock = (new ntxt.BlockParser).parse(this)

    }, // Close Ntxt.
    
    // Factory.
    fetchNtxt : function(url) {
      url = url || 'n.txt'
      xmlr = new XMLHttpRequest
      xmlr.open('GET', url, false)
      xmlr.send();
      return new ntxt.Ntxt(xmlr.responseText)
    }
  }
