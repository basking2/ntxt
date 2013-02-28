require 'ntxt/block'
require 'ntxt/ntxt'

module Ntxt

  # The parser for Ntxt. Most of this a typical user will not find useful
  # with the exception of Parser.parse.
  class Parser
  
    # Return an array in which the first element is the indent length and
    # the second element is the contained text. Nil otherwise.
    def hlevel()
      line = @lines[@currentLine]

      nextLine = if @lines.length > @currentLine + 1
        @lines[@currentLine+1]
      else
        nil
      end

      case line
      when /^\s*=([^=].*)=\s*$/
        [ 1, $~[1], 1 ]
      when /^\s*==([^=].*)==\s*$/
        [ 2, $~[1], 1 ]
      when /^\s*===([^=].*)===\s*$/
        [ 3, $~[1], 1 ]
      when /^\s*====([^=].*)====\s*$/
        [ 4, $~[1], 1 ]
      when /^\s*=====([^=].*)=====\s*$/
        [ 5, $~[1], 1 ]
      when /^\s*======([^=].*)======\s*$/
        [ 6, $~[1], 1 ]
      when /^\s*#\s*(.*)$/
        [ 1, $~[1], 1 ]
      when /^\s*##\s*(.*)$/
        [ 2, $~[1], 1 ]
      when /^\s*###\s*(.*)$/
        [ 3, $~[1], 1 ]
      when /^\s*####\s*(.*)$/
        [ 4, $~[1], 1 ]
      when /^\s*#####\s*(.*)$/
        [ 5, $~[1], 1 ]
      when /^\s*######\s*(.*)$/
        [ 6, $~[1], 1 ]
      else
        if nextLine && nextLine =~ /\s*==+\s*$/
          [ 1, line, 2 ]
        elsif nextLine && nextLine =~ /\s*--+\s*$/
          [ 2, line, 2 ]
        else
          nil
        end
      end
    end # hlevel

    def computeIndent
      /^(\s*).*$/.match(@lines[@currentLine])[1].length
    end

    def closeBlock
      @currentBlock.offset = @currentOffset - @currentBlock.start - 1
      @currentBlock = @currentBlock.parent
    end

    # Extract all the tags from the given line.
    #    Some tag examples:
    #      [a tag] [another tag]
    #      [a tag] [another tag] Not a tag. [a tag]
    #      No tag on this line.
    def extractTags()
      line = @lines[@currentLine]
      re = /\[([^\[]+)\]/m
      while line =~ re
        @currentBlock.addTag($~[1])
        line = line.sub(re, '')
      end
    end # self.extractTags
    
    # Parse the given Ntxt 's Ntxt#text.
    # [ntxtObj] If this is an Ntxt object, Ntxt#text is parsed.
    #           If +ntxtObj+ is not an Ntxt object, it is assumed to be
    #           a valid argument for Ntxt.new and a new Ntxt is constructed.
    def parse(ntxtObj)
    
      # If ntxtObj isn't an Ntxt, create it as one.
      ( ntxtObj = Ntxt.new(ntxtObj) ) unless ntxtObj.is_a?( Ntxt )

      rootBlock = Block.new(ntxtObj)

      @lines = ntxtObj.text.split("\n")
      @currentLine = 0
      @currentOffset = 0
      @currentIndent = 0
      @currentBlock = rootBlock
      
      parseLines()
      
      rootBlock
    end # parse(ntxtObj)

    def nextLine
      @currentOffset += @lines[@currentLine].length + 1
      @currentLine += 1
    end

    def parseLines
      while @currentLine < @lines.length do
        extractTags

        hlvl = hlevel

        if hlvl
          while @currentBlock.header >= hlvl[0] do
            closeBlock
          end

          @currentBlock = Block.new(
            @currentBlock.ntxt,
            @currentBlock,
            @currentOffset)
          @currentBlock.header = hlvl[0]

          hlvl[2].times { nextLine }
          @currentIndent = 0

          next
        end

        indent = computeIndent
        if indent < @currentIndent
          closeBlock
          @currentIndent = indent
        elsif indent > @currentIndent
          @currentBlock = Block.new(
            @currentBlock.ntxt,
            @currentBlock,
            @currentOffset)
          @currentBlock.indent = indent
          @currentIndent = indent
        end

        nextLine
      end

      while not @currentBlock.root?
        closeBlock
      end
    end # parseLines
  end
end
