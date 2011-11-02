require 'test/unit'

require 'ntxt/parser'
require 'ntxt/block'

require 'pp'

class TestParser < Test::Unit::TestCase

  @@fixture01 = File.open("test/test_parser_fixture.txt") { |io| io.read }
    
  def test_walk
    blk = Ntxt::Parser.new.parse(@@fixture01)
    
    assert_equal(blk.class, Ntxt::Block)
    
    return
    
    blk.walkText(
      lambda { |txt, depth, block| print txt },
      lambda { |depth, block| 
        puts "-----> #{depth} #{block.tags.keys.sort.join(',')}" },
      lambda { |depth, block| 
        puts "<----- #{depth} " } )
  end
  
  def test_indentation
    blk = Ntxt::Parser.new.parse(@@fixture01)
            
    assert_equal("pop out\n pop in\n", blk.children[0].children[2].text)
    assert_equal(" pop in\n", blk.children[0].children[2].children[0].text)
  end
  
  def test_header_parse
    blk = Ntxt::Parser.new.parse(@@fixture01)

    assert_equal(" a test\n of the bug\n this line will be wrong\n",
                 blk.children[0].children[1].text)
    assert_equal("[bug] parse last line in file.\n", 
                 blk.children[2].children[0].text)
  end
  
  def test_tagging
    blk = Ntxt::Parser.new.parse(@@fixture01)
    assert( blk.tags.member?('bug') )
    assert( blk.children[2].tags.member?('bug') )
  end

end
