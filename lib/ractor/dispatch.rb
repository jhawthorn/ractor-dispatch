# frozen_string_literal: true

require_relative "dispatch/version"
require_relative "dispatch/future"
require_relative "dispatch/executor"

class Ractor
  module Dispatch
    class Error < StandardError
      attr_reader :details

      def initialize(message = nil, details: nil)
        @details = details
        super(message)
      end
    end

    @main = Executor.new

    class << self
      def main
        @main
      end

      def reset_main! # :nodoc:
        @main.shutdown
        @main = Executor.new
      end
    end

    module ForkSafety # :nodoc:
      def _fork
        pid = super
        Ractor::Dispatch.reset_main! if pid == 0
        pid
      end
    end
    private_constant :ForkSafety

    Process.singleton_class.prepend(ForkSafety) if Process.respond_to?(:_fork)
  end
end
