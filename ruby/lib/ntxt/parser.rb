require 'ntxt/block'
require 'ntxt/ntxt'
require 'pp'

module Ntxt
  class Parser
  
    ###########################################################################
    class State
    
      attr_accessor :lines, :block, :lineStart, :lineEnd, :line, :start, :offset
    
      def initialize(lines, block, lineStart, start, lineEnd)
        @lines     = lines      # The array of lines to parse.
        @block     = block      # The block this state is operating on.
        @lineStart = lineStart  # The starting line in this state.
        @line      = lineStart  # The current line this state points at.
        @lineEnd   = lineEnd    # The last line. @lineEnd <= @lines.length.
        @start     = start      # Start index in text.
        @offset    = 0          # Offset from @start.
      end
      
      # Return the current line.
      def currLine
        if @line < @lineEnd && @line >= @lineStart
          @lines[@line]
        else
          nil
        end
      end
      
      # Shift the state to the next line and return that line.
      # If this goes out of bounds of the text nil is returned.
      def nextLine
        nLine = @line+1
        if nLine < @lineEnd
          @offset = @offset + @lines[@line].length + 1
          @line = nLine
          @lines[nLine]
        else
          @line = @lineEnd
          nil
        end
      end # nextLine
      
      # Shift the state to the previous line and return that line.
      # If this goes out of bounds of the text nil is returned.
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
      def consume
        @start = @start + @offset
        @offset = 0
        @lineStart = @line
      end
      
      def to_s
        "lineStart: %s, lineEnd: %s, line: %s, start: %s, offset: %s"%[
          @lineStart, @lineEnd, @line, @start, @offset
        ]
      end
      
      # Seek this state's position to the tiven state's position.
      def seek(state)
        @line = state.line
        @offset = (state.start + state.offset - @start).abs()
      end # seek
      
    end # Parser::State
    ###########################################################################
    
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
    
    def self.extractTags(block, line)
      while line =~ /^\s*\[([^\[]+)\]/m
        block.addTag($~[1])
        matchLength = $~[0].length
        line = line[matchLength,line.length - matchLength]
      end
    end # self.extractTags
    
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
    
    # Called from the first line of the text within the hlevel.
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
      
        break unless line =~ /^(\s*)([^=\s].*)$/
        
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
