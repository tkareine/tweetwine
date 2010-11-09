# coding: utf-8

require "base64"

module Tweetwine
  module Obfuscate
    extend self

    def obfuscate(str)
      str.tr("\x21-\x7e", "\x50-\x7e\x21-\x4f")
    end

    def read(str)
      obfuscate(Base64.decode64(str))
    end

    def write(str)
      Base64.encode64(obfuscate(str))
    end
  end
end
