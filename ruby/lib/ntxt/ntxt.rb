
module Ntxt

  # Root class that contains the text array that Block objects reference.
  class Ntxt
  
    # The raw text file. This is a String.
    attr_accessor :text
    
    # The root Block. It will contain all tags in the document
    # and has a Block.start of 0 and a Block.offset of #text.length.
    attr_accessor :rootBlock
  
    # Create a new Ntxt object. This requires a String that is the text
    # of the object.
    #   ntxt = Ntxt::Ntxt.new( File.open('n.txt'){ |io| io.read } )
    def initialize(text)
      @text  = text
      @rootBlock = (Parser.new).parse(self)
    end

    # Calls Block#walkText.
    def walkText(print, enter, exit)
      @rootBlock.walkText(print, enter, exit)
    end
  end
end
