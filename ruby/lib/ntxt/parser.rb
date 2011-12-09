require 'ntxt/block'
require 'ntxt/ntxt'

module Ntxt

  # The parser for Ntxt. Most of this a typical user will not find useful
  # with the exception of Parser.parse.
  class Parser
  
    # An internal class that contains the current parse position
    # and current limits on that parse, such as an artificial end-of-file
    # marker to terminate a sub-parsing of a sub-block.    
    class State
    
      # Array of lines. The result of Ntxt.text being split on '\n'
      attr_accessor :lines
      
      # The current Block being built up.
      attr_accessor :block
      
      # The index into #lines to start parsing at
      # and before which #prevLine should return nil.
      attr_accessor :lineStart
      
      # The index into #lines at which #nextLine should return nil.
      # This defaults to #lines.length
      attr_accessor :lineEnd
      
      # The current line this State points at.
      attr_accessor :line
      
      # The index into Ntxt.text that corresponds to the first
      # character of the #currLine.
      attr_accessor :start
      
      # The offset from #start. The substring of Ntxt.text
      # starting at #start and of length #offset will produce the
      # text being considered by this State.
      attr_accessor :offset
    
      def initialize(lines, block, lineStart, start, lineEnd)
        @lines     = lines      # The array of lines to parse.
        @block     = block      # The block this state is operating on.
        @lineStart = lineStart  # The starting line in this state.
        @line      = lineStart  # The current line this state points at.
        @lineEnd   = lineEnd    # The last line. @lineEnd <= @lines.length.
        @start     = start      # Start index in text.
        @offset    = 0          # Offset from @start.
      end
      
      # Return the current line. If #prevLine or #nextLine has
      # walked outside of the #lineStart or #lineEnd limits this will
      # return nil.
      def currLine
        if @line < @lineEnd && @line >= @lineStart
          @lines[@line]
        else
          nil
        end
      end
      
      # Return the next line (#line + 1) unless we step beyond #lineEnd.
      # If we exceed #lineEnd, nil is returned.
      # Notice that this also updates #offset.
      def nextLine
      
        # If we are already past the end, return nil, do nothing.
        if @line >= @lineEnd
          nil
          
        # Otherwise we are updating some state.
        else
          @offset = @offset + @lines[@line].length + 1
          @line = @line + 1
          
          # Recheck if we are inside the array and return nil if we are not.
          (@line < @lineEnd) ? @lines[@line] : nil
        end        
      end # nextLine
      
      # Return the previous line (#line - 1) unless we step before #lineStart.
      # If we exceed #lineStart, nil is returned.
      # Notice that this also updates #offset.
      def prevLine
        if @line < @lineStart
          nil
        else
          nLine = @line - 1
          @offset = @offset - @lines[nLine].length - 1
          @line = nLine
          @lines[nLine]
        end
      end # prevLine
      
      # Shift the state starting points to the current position of 
      # what has been read in this state, effecitvely consuming that input.
      #
      # The #start field is moved to #start+offset. The #offset is set to 0.
      # Finally the #lineStart is set to #line.
      def consume
        @start = @start + @offset
        @offset = 0
        @lineStart = @line
      end
      
      # Print as a string.
      def to_s
        "lineStart: %s, lineEnd: %s, line: %s, start: %s, offset: %s"%[
          @lineStart, @lineEnd, @line, @start, @offset
        ]
      end
      
      # Seek this state's position forward to the given state's position.
      # If a state with a position behind the current state's position is
      # passed in as an argument the behavior is undefined.
      def seek(state)
        @line = state.line
        @offset = (state.start + state.offset - @start).abs()
      end # seek
      
    end # Parser::State


    
    # Return an array in which the first element is the indent length and
    # the second element is the contained text. Nil otherwise.
    def self.hlevel(line)
      case line
      when /^\s*=([^=].*)=\s*$/
        [ 1, $~[1] ]
      when /^\s*==([^=].*)==\s*$/
        [ 2, $~[1] ]
      when /^\s*===([^=].*)===\s*$/
        [ 3, $~[1] ]
      when /^\s*====([^=].*)====\s*$/
        [ 4, $~[1] ]
      when /^\s*=====([^=].*)=====\s*$/
        [ 5, $~[1] ]
      when /^\s*======([^=].*)======\s*$/
        [ 6, $~[1] ]
      else
        nil
      end
    end # self.hlevel
    
    # Extract all the tags from the given line.
    # [block] The block to which all tags will be added with Block#addTag.
    #         All parent blocks recieve copies of the child block's tag.
    # [line] The line to extract all tags from. Tags are
    #        square-bracket-enclosed strings found in sequence at the
    #        beginning of a line. If the sequence is broken, extraction stops.
    #    Some tag examples:
    #      [a tag] [another tag]
    #      [a tag] [another tag] Not a tag. [not a tag]
    #      No tag on this line.
    #      No tag on this line either. [not a tag]
    def self.extractTags(block, line)
      while line =~ /^\s*\[([^\[]+)\]/m
        block.addTag($~[1])
        matchLength = $~[0].length
        line = line[matchLength,line.length - matchLength]
      end
    end # self.extractTags
    
    # Parse the given Ntxt 's Ntxt#text.
    # [ntxtObj] If this is an Ntxt object, Ntxt#text is parsed.
    #           If +ntxtObj+ is not an Ntxt object, it is assumed to be
    #           a valid argument for Ntxt.new and a new Ntxt is constructed.
    def parse(ntxtObj)
    
      # If ntxtObj isn't an Ntxt, create it as one.
      ( ntxtObj = Ntxt.new(ntxtObj) ) unless ntxtObj.is_a?( Ntxt )

      lines = ntxtObj.text.split("\n")
      
      rootBlock = Block.new(ntxtObj)
      
      @stack = [ State.new( lines, rootBlock, 0, 0, lines.length ) ]
      
      parseLines()
      
      if @stack.length == 1
        # parse success!
        rootBlock
      else
        # parse failure.
        nil
      end
    end # parse(ntxtObj)

    # Take the state off the top of the #stack and attempt to parse
    # an Hlevel block. An HLevel block is a wiki-like header block of text.
    # For example:
    #   = Header 1 =
    #   == Header 2 ==
    # [level] an integer from 1 to 6.
    # [title] a string of the text found between the equal signs.
    def parseHlevel(level, title)
      state = @stack[-1]
      
      # If in parseHlevel, don't get the current line. That is contained
      # in the title argument. Instead, get the next line and proceed.
      line = state.nextLine

      while line
        # Check if we have discovered another block in the form of an hlevel.
        hl = Parser::hlevel(line)
        
        if hl && hl[0].to_i <= level
          break
        end
        
        line = state.nextLine
      end
      
      block = Block.new(
        state.block.ntxt,
        state.block,
        state.start,
        state.offset)

      subState = State.new(
        state.lines,
        block,
        state.lineStart+1,
        state.start + state.lines[state.lineStart].length + 1,
        state.line)
      
      @stack.push subState
      parseLines
      @stack.pop
      state.consume
    end # parseHlevel(leve, title)
    
    # Parse blocks of text that are indented at the given level or greater.
    # [indentLevel] an integer denoteing the number of characters this line is
    #               indented at.
    # [text] the content of the line that was indented.
    def parseIndent(indentLevel, text)
      state = @stack[-1]
      line = state.currLine

      # Build the block. Update the offset.
      block = Block.new(state.block.ntxt,
                        state.block,
                        state.start,
                        state.offset)

      # Position state at the ed of the block.
      # Blocks are ended by empty lines or lines with the = starting them.
      while line

        break if Parser::hlevel(line)
        break unless line =~ /^(\s*)(..*)$/

        nextIndentLevel = $~[1].length
        nextLine = $~[2]
        
        break if nextIndentLevel < indentLevel

        if nextIndentLevel > indentLevel
          # Advance to the next line after parsing a subblock.
          subState = State.new(
            state.lines,
            block,
            state.line, 
            state.start + state.offset,
            state.lineEnd)

          @stack.push subState
          parseIndent(nextIndentLevel, nextLine)
          @stack.pop
          state.seek subState
          line = state.currLine
        else
          Parser::extractTags(block, line)
          line = state.nextLine
        end # if nextIndentLevel > indentLevel
        
      end # while line
      block.offset = state.offset
      state.consume
    end # parseIndent(indentLevel, text)
    
    # This is the root of the parser's call tree after #parse sets up
    # the parse. This plucks the State off the Parser.stack, obtains the
    # State.currLine.
    # 
    # When an indented line is found, #parseIndent is called.
    # When a header line is found, #parseHlevel is caled.
    # Otherwise, we move to the next line.
    def parseLines
      state = @stack[-1]
      line = state.currLine
      
      while line
        tmp = Parser::hlevel(line)

        if tmp
          state.consume
          parseHlevel(tmp[0].to_i, tmp[1])
          line = state.currLine
        elsif line =~ /^(\s*)(\S.*)$/
          state.consume
          parseIndent($~[1].length, $~[2])
          line = state.currLine
        else
          line = state.nextLine
        end # if tmp
      end # while line
    end # parseLines
  end
end
