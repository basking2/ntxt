# Copyright (C) 2014 by Sam Baskinger
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
    def initialize(txt)
      self.text = txt
    end

    # Calls Block#walkText.
    def walkText(print, enter, exit)
      @rootBlock.walkText(print, enter, exit)
    end

    # Set the text of this Ntxt::Ntxt and parse it.
    #
    # Calling this invalides any Ntxt::Block objects previous associated with this Ntxt::Ntxt.
    # This returns +self+.
    def text=(txt)
      @text = txt
      @rootBlock = (Parser.new).parse(self)
      self
    end
  end
end
