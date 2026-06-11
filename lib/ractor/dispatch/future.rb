# frozen_string_literal: true

class Ractor
  module Dispatch
    class Future
      def initialize(port, resolved: false, value: nil, error: nil)
        @port = port
        @mutex = Mutex.new
        if resolved
          @resolved = true
          @value = value
          @error = error
        end
      end

      def value
        @mutex.synchronize do
          unless defined?(@resolved)
            @resolved = true
            status, val = @port.receive
            @port.close
            if status == :error
              @error = val
            else
              @value = val
            end
          end
        end

        raise @error if @error
        @value
      end

      def resolved?
        @mutex.synchronize { defined?(@resolved) }
      end
    end
  end
end
