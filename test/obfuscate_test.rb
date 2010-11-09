# coding: utf-8

require "test_helper"

module Tweetwine::Test

class ObfuscateTest < UnitTestCase
  include Obfuscate

  should "obfuscate symmetrically" do
    str = 'hey, jack'
    assert_equal(str, obfuscate(obfuscate(str)))
  end
end

end
