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

gem 'test-unit'
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

    assert_not_nil(blk.children[0])
    assert_match(/pop out\n pop in$/m, blk.children[0].text)
    assert_not_nil(blk.children[0].children[1])
    assert_match(" pop in", blk.children[0].children[1].text)
  end

  def test_header_parse
    blk = Ntxt::Parser.new.parse(@@fixture01)

    assert_equal(" a test\n of the bug\n this line will be wrong",
                 blk.children[0].children[0].text)
    assert_equal("=hi=\n[bug] parse last line in file.",
                 blk.children[3].text)
  end

  def test_tagging
    blk = Ntxt::Parser.new.parse(@@fixture01)
    assert( blk.tags.member?('bug') )
    assert( blk.children[3].tags.member?('bug') )
  end
end
