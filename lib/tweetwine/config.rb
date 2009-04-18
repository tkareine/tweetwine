require "yaml"

module Tweetwine
  class Config
    def self.load(file)
      new(file)
    end

    private_class_method :new

    def initialize(file)
      @config = YAML.load(File.read(file))
    end

    def method_missing(sym)
      key = sym.to_s
      if key[-1,1] == "?"
        result = @config.has_key? key[0...-1]
      else
        result = @config[key]
      end
      result
    end
  end
end