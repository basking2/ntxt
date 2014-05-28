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

require 'ntxt'
require 'pp'

class TestEdit < Test::Unit::TestCase

  def test_edit_01

    text =
      <<-EOT
      Text
        Sub 1
      More Text
        Sub 2
      Finale
        Sub 3
      EOT
    ntxt = Ntxt::Ntxt.new(text)

    assert_equal('        Sub 1', ntxt.rootBlock.children[0].children[0].text)
    assert_equal('        Sub 2', ntxt.rootBlock.children[0].children[1].text)
    assert_equal('        Sub 3', ntxt.rootBlock.children[0].children[2].text)

    ntxt.rootBlock.children[0].children[0].text = "        New Sub 1"
    assert_equal('        New Sub 1', ntxt.rootBlock.children[0].children[0].text)
    assert_equal('        Sub 2', ntxt.rootBlock.children[0].children[1].text)
    assert_equal('        Sub 3', ntxt.rootBlock.children[0].children[2].text)

    ntxt.rootBlock.children[0].children[1].text = "        New Sub 2"
    assert_equal('        New Sub 1', ntxt.rootBlock.children[0].children[0].text)
    assert_equal('        New Sub 2', ntxt.rootBlock.children[0].children[1].text)
    assert_equal('        Sub 3', ntxt.rootBlock.children[0].children[2].text)

    ntxt.rootBlock.children[0].children[2].text = "        New Sub 3"
    assert_equal('        New Sub 1', ntxt.rootBlock.children[0].children[0].text)
    assert_equal('        New Sub 2', ntxt.rootBlock.children[0].children[1].text)
    assert_equal('        New Sub 3', ntxt.rootBlock.children[0].children[2].text)

    assert_equal(text.gsub('Sub', 'New Sub'), ntxt.text)
  end
end