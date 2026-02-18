# frozen_string_literal: true

require "test_helper"

class Ractor::TestDispatch < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Ractor::Dispatch::VERSION
  end

  def test_run
    executor = Ractor::Dispatch::Executor.new

    r = Ractor.new(executor) do |ex|
      ex.run { 1 + 1 }
    end

    assert_equal 2, r.value
    executor.shutdown
  end

  def test_submit
    executor = Ractor::Dispatch::Executor.new

    r = Ractor.new(executor) do |ex|
      future = ex.submit { 1 + 1 }
      future.value
    end

    assert_equal 2, r.value
    executor.shutdown
  end

  def test_error_propagation
    executor = Ractor::Dispatch::Executor.new

    r = Ractor.new(executor) do |ex|
      ex.run { raise "oops" }
    rescue => e
      e
    end

    e = r.value
    assert_kind_of RuntimeError, e
    assert_equal "oops", e.message
    executor.shutdown
  end

  def test_future_value_twice
    executor = Ractor::Dispatch::Executor.new

    r = Ractor.new(executor) do |ex|
      future = ex.submit { 1 + 1 }
      [future.value, future.value]
    end

    assert_equal [2, 2], r.value
    executor.shutdown
  end
end
