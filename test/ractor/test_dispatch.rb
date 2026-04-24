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

    e = r.value
    assert_kind_of Ractor::Dispatch::Error, e
    assert_equal Ractor::Error, e.details[:class]
    assert_equal "can not copy Monitor object.", e.details[:message]
    assert_equal UnshareableError, e.details[:cause][:class]
    assert_equal "oops", e.details[:cause][:message]
    assert_equal expected_backtrace, e.details[:cause][:backtrace]
    executor.shutdown
  end

  def test_main
    r = Ractor.new do
      Ractor::Dispatch.main.run { Ractor.main? }
    end

    assert_equal true, r.value
  end
end
