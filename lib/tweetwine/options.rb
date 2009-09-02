module Tweetwine
  class Options
    def initialize(options)
      @hash = options.to_hash
    end

    def [](key)
      @hash[key]
    end

    def require(key)
      value = @hash[key]
      raise ArgumentError, "Option #{key} is required" if value.nil?
      value
    end
  end
end
