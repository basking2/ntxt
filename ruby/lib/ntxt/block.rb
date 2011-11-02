
module Ntxt

  # Block constructor
  # ntxtObj the root Ntxt object.
  # parentBlock the parent Block object.
  # startTxt the starting offset in ntxtObj.text where this starts
  # stopTxt the offset in ntxtObje.text after the startTxt position.
  # The block of text submitted must be a valid block, meaning, it may
  # ONLY contain subblocks.
  class Block
  
    attr_accessor :children, :tags, :start, :offset, :ntxt, :parent

    if RUBY_VERSION =~ /^1.8/
      def self.blockReMatch(re, txt, offset)
        re.match(txt[offset..-1])
      end
    else
      def self.blockReMatch(re, txt, offset)
        re.match(txt, offset)
      end
    end
        
    def initialize(ntxtObj, parentBlock=nil, startTxt=0, stopTxt=0)
      @children = []
      @tags = Hash.new(0)
      @start = startTxt
      @offset = stopTxt || ntxtObj.text.length
      @ntxt = ntxtObj
      @parent = parentBlock
      
      if @parent
        re = /\s*\S/m
        #m = re.match( ntxtObj.text, @start )
        m = Block::blockReMatch(re, ntxtObj.text, @start)
        if m
          @indent = m[0].length
        else
          @indent = 0
        end
        @parent.children.push(self)
      else
        @indent = 0
      end
    end
    
    def addTag(tag)
      @tags[tag] += 1
      @parent.addTag(tag) if @parent
    end
    
    def text
      @ntxt.text[@start, @offset]
    end
    
    def is_root?
      @parent
    end
    
    def walk(&y)
      yield self
      @children.each { |c| c.walk(&y) }
    end
    
    # printFunc is a lambda that takes the text, depth, and the node.
    # enterChild is a lambda that takes depth and the node.
    # exitChild is a lambda that takes depth and the node.
    def walkText(printFunc, enterChild, exitChild)
      walkTextHelper(printFunc, enterChild, exitChild, 0)
    end
    
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
  end
end
