# frozen_string_literal: true

class Ractor
  module Dispatch
    class Executor
      def initialize
        @port = Ractor::Port.new

        Thread.new do
          loop do
            callable, reply_port = @port.receive
            begin
              result = callable.call
              reply_port << [:ok, result]
            rescue => e
              reply_port << [:error, e]
            rescue Ractor::ClosedError
              # caller went away, discard
            end
          end
        rescue Ractor::ClosedError
          # port closed via shutdown
        end

        Ractor.make_shareable(self)
      end

      def submit(&block)
        callable = Ractor.shareable_proc(&block)
        reply_port = Ractor::Port.new
        @port << [callable, reply_port]
        Future.new(reply_port)
      end

      def run(&block)
        submit(&block).value
      end

      def shutdown
        @port.close
      end
    end
  end
end
