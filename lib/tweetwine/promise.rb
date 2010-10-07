# coding: utf-8

module Tweetwine
  # Lazy evaluation via proxy object.
  #
  # A naive implementation, but it's enough.
  #
  # Adapted from the book Ruby Best Practices, by Gregory Brown.
  class Promise < BasicObject
    def initialize(&action)
      @action = action
    end

    def __result__
      if @action
        @result = @action.call
        @action = nil
      end
      @result
    end

    def inspect
      if @action
        "#<Tweetwine::Promise action=#{@action.inspect}>"
      else
        @result.inspect
      end
    end

    def respond_to?(method)
      method = method.to_sym
      [:__result__, :inspect].include?(method) || __result__.respond_to?(method)
    end

    def method_missing(*args, &blk)
      __result__.__send__(*args, &blk)
    end
  end
end
