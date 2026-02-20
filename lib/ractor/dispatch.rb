# frozen_string_literal: true

require_relative "dispatch/version"
require_relative "dispatch/future"
require_relative "dispatch/executor"

class Ractor
  module Dispatch
    class Error < StandardError; end

    @main = Executor.new

    def self.main
      @main
    end
  end
end
