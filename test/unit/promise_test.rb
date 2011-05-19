# coding: utf-8

require 'support/unit_test_case'

module Tweetwine::Test::Unit

class PromiseTest < TestCase
  before do
    @result = nil
    @action_called = 0
    @promise = Promise.new do
      @action_called += 1
      @result = rand 10
    end
  end

  it "evaluates action when calling a method" do
    result = @promise.to_i
    assert_same(@result, result)
    assert_equal(1, @action_called)
  end

  it "memoizes already evaluated action" do
    result = @promise.to_i
    assert_same(@result, result)
    result = @promise.to_i
    assert_same(@result, result)
    assert_equal(1, @action_called)
  end

  it "inspects the proxy object if action is not evaluated" do
    assert_match(/^#<Tweetwine::Promise/, @promise.inspect)
    assert_equal(0, @action_called)
  end

  it "inspects the evaluated object if action is evaluated" do
    eval_action
    assert_match(/^\d$/, @promise.inspect)
  end

  it "passes #object_id call to the evaluation result" do
    eval_action     # in order to have @result set
    assert_equal(@result.object_id, @promise.object_id)
  end

  it "passes #to_s call to the evaluation result" do
    eval_action     # in order to have @result set
    assert_equal(@result.to_s, @promise.to_s)
  end

  private

  def eval_action
    @promise * 42   # just do something with it
  end
end

end
