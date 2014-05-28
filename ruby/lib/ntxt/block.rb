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

  # Block constructor
  # ntxtObj the root Ntxt object.
  # parentBlock the parent Block object.
  # startTxt the starting offset in ntxtObj.text where this starts
  # stopTxt the offset in ntxtObje.text after the startTxt position.
  # The block of text submitted must be a valid block, meaning, it may
  # ONLY contain subblocks.
  class Block

    # A list of child Blcoks.
    attr_accessor :children

    # A hash of all tags of this block and its children.
    attr_accessor :tags

    # The +start+ index in the text string held in the Ntxt parent object.
    # See the +ntxt+ field.
    attr_accessor :start

    # The offset from the +start+ field.
    attr_accessor :offset

    # The Ntxt object.
    attr_accessor :ntxt

    # The parent Block or nil if this is a root Block.
    attr_accessor :parent

    # The current header level. 0 for no header. 1-6 otherwise.
    attr_accessor :header

    # The current indent level. If this is a header block, ident=0.
    attr_accessor :indent

    # Create a new Block. Typically you will never need to do this.
    # Blocks are created by Parser.
    # [ntxtObj] The Ntxt object that this block belongs to.
    #           The Ntxt object holds the text this block will reference.
    # [parentBlock] The parent block. Nil by default.
    # [startTxt] The staring character in Ntxt.text.
    # [stopTxt] The initial offset. If nil this is set to ntxtObj.text.length.
    def initialize(ntxtObj, parentBlock=nil, startTxt=0, stopTxt=0)
      @children = []
      @tags = Hash.new(0)
      @start = startTxt
      @offset = stopTxt || ntxtObj.text.length
      @ntxt = ntxtObj
      @parent = parentBlock
      @indent = 0
      @header = 0

      if @parent
        @parent.children.push(self)
      end
    end

    # Add a tag to this block and all ancestor blocks.
    #
    # A tag added to a block does not increment that block's tag count
    # for the added tag. A tag added to the parent of a tagged block has
    # it's tag count incremented by 1.
    #
    # Thus, if a tag count = 0, then this block owns the tag.
    #
    # If a tag count = 1. there is 1 child block with the given tag.
    #
    # [tag] The tag to add.
    # [inc] The increment value. This should always be 0
    #       for client code.
    def addTag(tag, inc=0)
      @tags[tag] += inc
      @parent.addTag(tag, 1) if @parent
    end

    # Return the text slice that this block refers to.
    # Note that parent blocks include their child blocks' text.
    def text
      @ntxt.text[@start, @offset]
    end

    # Return true if the parent object is nil.
    def root?
      @parent.nil?
    end

    # Given a block this will first call that block with this Block as
    # the only argument. Then walk is recusively called on all child Blocks.
    def walk(&y)
      yield self
      @children.each { |c| c.walk(&y) }
    end

    # This method handles the complexity of handing the user
    # the text immediately handled by each block.
    #
    # If you call Block.text you will get a contiguous block of text
    # that covers this Block and all its children. Essentially the +start+
    # to the +offset+ substring of Ntxt.text.
    #
    # What this method does is pass each text that belongs only to
    # the particular Block in question and the children. The text
    # is passed to the user in order, so concatinating it would
    # result in equivalent output to Block.text.
    #
    # This method is useful for visualizing the text structure
    # or filtering out blocks that aren't interesting to the user.
    #
    # [printFunc] A lambda that takes the text, depth, and the Block.
    # [enterChild] A lambda that takes depth and the Block.
    # [exitChild] A lambda that takes depth and the Block.
    # For example:
    #
    #   printBlock = lambda { |text, depth, block| ... }
    #   enterBlock = lambda { |depth, block| ... }
    #   exitBlock  = lambda { |depth, block| ... }
    #
    #   block.walkText( printBlock, enterBlock, exitBlock )
    #
    def walkText(printFunc, enterChild, exitChild)
      walkTextHelper(printFunc, enterChild, exitChild, 0)
    end

    protected

    # Helper function for walkText. Takes the same arguments
    # with the depth set to 0.
    def walkTextHelper(printFunc, enterChild, exitChild, depth)
      enterChild.call(depth, self)

      if @children.length == 0
        printFunc.call(text(), depth, self)
      else
        prevEnd = @start

        @children.each do |child|
          start = prevEnd
          offset = child.start - start
          printFunc.call(@ntxt.text[start, offset], depth, self)
          child.walkTextHelper(printFunc, enterChild, exitChild, depth+1)
          prevEnd = child.start + child.offset
        end # @children.each

        lastChild = @children[-1]
        start = lastChild.start + lastChild.offset
        offset = @start + @offset - start

        printFunc.call(@ntxt.text[start, offset], depth, self)
      end # else of if @children.length == 0

      exitChild.call(depth, self)
    end

    private

    if RUBY_VERSION =~ /^1.8/

      # Regular expression matcher with an offset.
      # The implementation of this is descided at runtime depending on
      # if Ruby 1.9's new RE match method is found.
      def self.blockReMatch(re, txt, offset)
        re.match(txt[offset..-1])
      end
    else

      # Regular expression matcher with an offset.
      # The implementation of this is descided at runtime depending on
      # if Ruby 1.9's new RE match method is found.
      def self.blockReMatch(re, txt, offset)
        re.match(txt, offset)
      end
    end
  end
end
