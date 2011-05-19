# coding: utf-8

require 'support/unit_test_case'

module Tweetwine::Test::Unit

class ObfuscateTest < TestCase
  include Obfuscate

  it "obfuscates symmetrically" do
    str = 'hey, jack'
    assert_equal(str, obfuscate(obfuscate(str)))
  end
end

end
