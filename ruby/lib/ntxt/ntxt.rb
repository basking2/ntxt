
module Ntxt

  # Root class that contains the text array that Blocks reference 
  # and the root block.
  class Ntxt
    attr_accessor :text, :rootBlock
  
    def initialize(text)
      @text  = text
      @rootBlock = (Parser.new).parse(self)
    end

    # walkText(print, enter, exit)
    # Walk the ntxt tree with 3 callbacks, print, enter, and exit.
    # Print is a lambda that takes the text, the depth, and a copy of
    # the Ntxt::Block it is in.
    # Enter is the same, but is called with no text argument and is called
    # when a block is entered (that is, the depth has increased by 1).
    # Exit is the same, but is called with no text argument and is called
    # when a block is exited (that is, the depth has decreated by 1).
    def walkText(print, enter, exit)
      @rootBlock.walkText(print, enter, exit)
    end
  end
end
