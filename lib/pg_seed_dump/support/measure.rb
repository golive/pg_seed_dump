# frozen_string_literal: true
require_relative "colored_string"

module PgSeedDump
  module Support
    class Measure
      def initialize
        @starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      def self.start
        new
      end

      def elapsed
        ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        units = "s"
        elapsed = ending - @starting
        slow = elapsed > 10
        text_color = slow ? :red : :green
        if elapsed < 1
          elapsed = (elapsed * 1000)
          units = "ms"
        end
        "#{elapsed.round(2)}#{units}".public_send(text_color)
      end
    end
  end
end