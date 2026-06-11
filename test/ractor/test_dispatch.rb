# frozen_string_literal: true

require "test_helper"
require "monitor"

class Ractor::TestDispatch < Minitest::Test
  class UnshareableError < StandardError
    include MonitorMixin
  end

  def test_that_it_has_a_version_number
    refute_nil ::Ractor::Dispatch::VERSION
  end

  def test_run
    executor = Ractor::Dispatch::Executor.new

    r = Ractor.new(executor) do |ex|
      ex.run { 1 + 1 }
    end

    assert_equal 2, ractor_value(r)
    executor.shutdown
  end

  def test_submit
    executor = Ractor::Dispatch::Executor.new

    r = Ractor.new(executor) do |ex|
      future = ex.submit { 1 + 1 }
      future.value
    end

    assert_equal 2, ractor_value(r)
    executor.shutdown
  end

  if RUBY_VERSION < "4"
    def test_ruby_3_submit_runs_inline
      executor = Ractor::Dispatch::Executor.new

      future = executor.submit { 42 }

      # No-op executor: the block runs inline, so the future is already resolved.
      assert future.resolved?
      assert_equal 42, future.value
      executor.shutdown
    end
  end

  def test_error_propagation
    executor = Ractor::Dispatch::Executor.new

    r = Ractor.new(executor) do |ex|
      ex.run { raise "oops" }
    rescue => e
      e
    end

    e = ractor_value(r)
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

    assert_equal [2, 2], ractor_value(r)
    executor.shutdown
  end

  if RUBY_VERSION >= "4"
    def test_unshareable_error_propagation
      executor = Ractor::Dispatch::Executor.new
      port = Ractor::Port.new

      r = Ractor.new(executor, port) do |ex, port|
        ex.run do
          raise UnshareableError, "oops"
        rescue => e
          port << e.backtrace.map(&:to_s)
          raise
        end
      rescue => e
        e
      end

      expected_backtrace = port.receive

      e = ractor_value(r)
      assert_kind_of Ractor::Dispatch::Error, e
      assert_equal Ractor::Error, e.details[:class]
      assert_equal "can not copy Monitor object.", e.details[:message]
      assert_equal UnshareableError, e.details[:cause][:class]
      assert_equal "oops", e.details[:cause][:message]
      assert_equal expected_backtrace, e.details[:cause][:backtrace]
      executor.shutdown
    end
  end

  if RUBY_VERSION >= "4"
    def test_main
      r = Ractor.new do
        Ractor::Dispatch.main.run { Ractor.main? }
      end

      assert_equal true, ractor_value(r)
    end
  end

  private

  def ractor_value(ractor)
    if RUBY_VERSION >= "4"
      ractor.value
    else
      ractor.take
    end
  end
end
