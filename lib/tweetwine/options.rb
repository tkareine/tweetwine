module Tweetwine
  class Options
    def initialize(options, source = nil)
      @hash = options.to_hash
      @source = source
    end

    def [](key)
      @hash[key]
    end

    def require(key)
      value = @hash[key]
      if value.nil?
        msg = "Option #{key} is required"
        msg << " for #{@source}" if @source
        raise ArgumentError, msg
      end
      value
    end
  end
end
